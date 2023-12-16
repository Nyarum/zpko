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

const State = enum { accept, recv, send, closed };

const Socket = struct {
    handle: std.os.socket_t,
    buffer: [1024]u8,
    state: State,
};

pub const TCP = struct {
    ring: io_uring,
    server: net.StreamServer,

    pub fn init() !TCP {
        const ring = try io_uring.init(MAX_EVENTS, 0);

        return TCP{
            .ring = ring,
            .server = net.StreamServer.init(.{}),
        };
    }

    pub fn start(tcp: *TCP, allocator: Allocator, addr: *std.net.Address) !void {
        try tcp.server.listen(addr.*);

        std.debug.print("test", .{});

        const ptrServer = @as(u64, @intFromPtr(&tcp.server));
        var addr_len: std.os.socklen_t = addr.getOsSockLen();

        print("ptr: {any}\n", .{tcp.server.sockfd.?});

        // Submit new events, like accepting new connections
        _ = try tcp.ring.accept(ptrServer, tcp.server.sockfd.?, &addr.any, &addr_len, 0);

        var hashEnable = std.AutoHashMap(std.os.socket_t, u32).init(allocator);

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

                        try hashEnable.put(client.handle, 0);

                        const timePkt = try packets.CharacterScreen.firstDate.init(allocator);

                        std.debug.print("Connected {any}\n", .{client});

                        const buf = bytesUtil.packHeaderBytes(packets.CharacterScreen.firstDate, timePkt);

                        std.debug.print("Buf {any}\n", .{buf});

                        _ = try tcp.ring.recv(@intFromPtr(client), client.handle, .{ .buffer = &client.buffer }, 0);
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
                            return;
                        }

                        if (event.res > 7) {
                            if (std.mem.eql(u8, client.buffer[6..8], &[2]u8{ 0x01, 0xb0 })) {
                                client.state = State.closed;
                                _ = try tcp.ring.close(@intFromPtr(client), client.handle);
                                continue;
                            }
                        }

                        _ = try tcp.ring.recv(@intFromPtr(client), client.handle, .{ .buffer = &client.buffer }, 0);

                        if (event.res <= 2) {
                            continue;
                        }

                        std.debug.print("Recv {any}\n", .{client.buffer});

                        std.debug.print("test! {any}\n", .{event.res});

                        if (hashEnable.get(client.handle) == 0) {
                            const authEnter = bytesUtil.packHeaderBytes(
                                packets.Undefined2,
                                packets.Undefined2{
                                    .data = &[_]u8{ 0x00, 0x00, 0x00, 0x08, 0x7C, 0x35, 0x09, 0x19, 0xB2, 0x50, 0xD3, 0x49, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x32, 0x14 },
                                },
                            );
                            try hashEnable.put(client.handle, hashEnable.get(client.handle).? + 1);

                            _ = try tcp.ring.send(@intFromPtr(client), client.handle, authEnter, 0);
                        }
                    },
                    .send => {
                        std.debug.print("Send {any}\n", .{client.buffer});

                        std.os.closeSocket(client.handle);
                        allocator.destroy(client);
                    },
                }
            }
        }
    }
};
