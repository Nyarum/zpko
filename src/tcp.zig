const std = @import("std");
const net = std.net;
const Allocator = std.mem.Allocator;
const timeUtil = @import("./time.zig");
const bytesUtil = @import("./bytes.zig");
const uuid = @import("./uuid.zig");
const storage = @import("./storage.zig");
const packets = @import("./packets.zig");
const print = std.debug.print;
const io_uring = std.os.linux.IO_Uring;
const MAX_EVENTS = 1024; // Adjust based on expected load
const world = @import("./world.zig");

const State = enum { accept, recv, send, closed };

const Socket = struct {
    handle: std.os.socket_t,
    buffer: ?[8096]u8,
    state: State,
};

const Player = struct {
    isAuth: bool = false,
};

pub const TCP = struct {
    ring: io_uring,
    server: net.StreamServer,
    players: std.AutoHashMap(std.os.socket_t, Player),
    mutex: std.Thread.Mutex = .{},
    threadPool: std.Thread.Pool = undefined,
    newWorld: *world.World,

    pub fn init(allocator: Allocator, newWorld: *world.World) !*TCP {
        const ring = try io_uring.init(MAX_EVENTS, 0);

        var tcp = TCP{
            .ring = ring,
            .server = net.StreamServer.init(.{}),
            .players = std.AutoHashMap(std.os.socket_t, Player).init(allocator),
            .newWorld = newWorld,
        };

        try tcp.threadPool.init(.{
            .allocator = allocator,
        });

        return &tcp;
    }

    pub fn send(tcp: *TCP, client: std.os.socket_t, data: []const u8) !void {
        const oldClient = &Socket{
            .handle = client,
            .buffer = null,
            .state = .recv,
        };

        print("send tcp", .{});

        _ = tcp.ring.send(@intFromPtr(oldClient), oldClient.handle, data, 0) catch |err| {
            print("err: {any}", .{err});
        };
    }

    pub fn deinit(tcp: *TCP) void {
        tcp.players.deinit();

        if (tcp.threadPool.threads.len > 0) {
            tcp.threadPool.deinit();
        }

        tcp.ring.deinit();
        std.os.closeSocket(tcp.server.sockfd.?);
    }

    pub fn start(tcp: *TCP, allocator: Allocator, addr: *std.net.Address) !void {
        try tcp.server.listen(addr.*);

        std.debug.print("test", .{});

        const ptrServer = @as(u64, @intFromPtr(&tcp.server));
        var addr_len: std.os.socklen_t = addr.getOsSockLen();

        print("ptr: {any}\n", .{tcp.server.sockfd.?});

        // Submit new events, like accepting new connections
        _ = try tcp.ring.accept(ptrServer, tcp.server.sockfd.?, &addr.any, &addr_len, 0);

        while (true) {
            _ = try tcp.ring.submit();

            var cqes: [1024]std.os.linux.io_uring_cqe = undefined;
            const count = try tcp.ring.copy_cqes(&cqes, 1);

            std.debug.print("{any} and {any}\n", .{ cqes.len, count });

            for (cqes[0..count]) |event| {
                print("event {any}\n", .{event});

                var client = @as(*Socket, @ptrFromInt(@as(usize, @intCast(event.user_data))));

                print("bbb {any}\n", .{client.state});

                switch (client.state) {
                    .accept => {
                        client = try allocator.create(Socket);
                        client.handle = @as(std.os.socket_t, @intCast(event.res));
                        client.state = .recv;

                        try tcp.players.put(client.handle, Player{});

                        const timePkt = try packets.CharacterScreen.firstDate.init(allocator);

                        std.debug.print("Connected {any}\n", .{client});

                        const buf = bytesUtil.packHeaderBytes(packets.CharacterScreen.firstDate, timePkt);

                        std.debug.print("Buf {any}\n", .{buf});

                        _ = try tcp.ring.recv(@intFromPtr(client), client.handle, .{ .buffer = &client.buffer.? }, 0);
                        _ = try tcp.ring.send(@intFromPtr(client), client.handle, buf, 0);
                        _ = try tcp.ring.accept(ptrServer, tcp.server.sockfd.?, &addr.any, &addr_len, 0);

                        print("test222\n", .{});
                    },
                    .closed => {
                        print("closed", .{});
                    },
                    .recv => {
                        if (event.res == 0 or event.res == -9) {
                            std.log.debug("connection is closed", .{});
                            _ = try tcp.ring.close(@intFromPtr(client), client.handle);
                            continue;
                        }

                        if (event.res > 7) {
                            if (std.mem.eql(u8, client.buffer.?[6..8], &[2]u8{ 0x01, 0xb0 })) {
                                client.state = State.closed;
                                _ = try tcp.ring.close(@intFromPtr(client), client.handle);
                                continue;
                            }
                        }

                        _ = try tcp.ring.recv(@intFromPtr(client), client.handle, .{ .buffer = &client.buffer.? }, 0);

                        if (event.res <= 2) {
                            continue;
                        }

                        std.debug.print("Recv {any}\n", .{client.buffer});

                        try tcp.threadPool.spawn(world.World.handlePlayerData, .{
                            tcp.newWorld,
                            tcp,
                            client.handle,
                            client.buffer.?[0..@as(usize, @intCast(event.res))],
                        });
                    },
                    .send => {
                        std.debug.print("Send {any}\n", .{client.buffer});

                        _ = try tcp.ring.recv(@intFromPtr(client), client.handle, .{ .buffer = &client.buffer.? }, 0);
                    },
                }
            }
        }
    }
};
