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

const Auth = struct {
    opcode: ?u16 = 431,
    key: []const u8,
    login: []const u8,
    password: []const u8,
    mac: []const u8,
    is_cheat: u16,
    client_version: u16,

    pub fn bro(_: Auth) void {
        print("test", .{});
    }
};

const State = enum { accept, recv, send };

const Socket = struct {
    handle: std.os.socket_t,
    buffer: [1024]u8,
    state: State,
};

const Bro = struct {
    ss: u8 = 1,
    key: []const u8,
};

pub fn main() !void {
    var ring = try io_uring.init(MAX_EVENTS, 0);

    // Initialize and set up the TCP server socket
    var server = net.StreamServer.init(.{});
    defer server.deinit();

    var addr = std.net.Address.initIp4(.{ 127, 0, 0, 1 }, 1973);
    var addr_len: std.os.socklen_t = addr.getOsSockLen();

    try server.listen(addr);

    std.debug.print("run other, {any}\n", .{server.sockfd});

    // Submit new events, like accepting new connections
    _ = try ring.accept(@as(u64, @intFromPtr(&server)), server.sockfd.?, &addr.any, &addr_len, 0);

    var allocator = std.heap.page_allocator;

    // Main event loop
    while (true) {
        _ = try ring.submit_and_wait(1);

        while (ring.cq_ready() > 0) {
            const event = try ring.copy_cqe();
            var client = @as(*Socket, @ptrFromInt(@as(usize, @intCast(event.user_data))));

            switch (client.state) {
                .accept => {
                    client = try allocator.create(Socket);
                    client.handle = @as(std.os.socket_t, @intCast(event.res));
                    client.state = .recv;
                    _ = try ring.recv(@intFromPtr(client), client.handle, .{ .buffer = &client.buffer }, 0);
                    _ = try ring.accept(@intFromPtr(&server), server.sockfd.?, &addr.any, &addr_len, 0);

                    std.debug.print("Connected {any}\n", .{client});
                },
                .recv => {
                    const read = @as(usize, @intCast(event.res));
                    client.state = .send;
                    _ = try ring.send(@intFromPtr(client), client.handle, client.buffer[0..read], 0);
                },
                .send => {
                    std.os.closeSocket(client.handle);
                    allocator.destroy(client);
                },
            }

            std.debug.print("{any}", .{event});
        }

        std.debug.print("test", .{});
    }
}

fn handleConnection(conn: net.StreamServer.Connection) void {
    defer conn.stream.close();

    // Allocate a buffer for incoming data
    var buf: [4096]u8 = undefined;

    // Read data from the client
    while (true) {
        const readSize = conn.stream.read(&buf) catch {
            break;
        };

        if (readSize == 0) {
            std.log.debug("connection is closed", .{});
            break;
        }

        if (std.mem.eql(u8, buf[6..8], &[_]u8{ 0x01, 0xB0 })) {
            std.log.debug("connection is closed", .{});
            break;
        }

        if (readSize == 2) {
            _ = conn.stream.write(&[_]u8{ 0x00, 0x02 }) catch {
                break;
            };
            continue;
        }

        if (std.mem.eql(u8, buf[6..8], &[_]u8{ 0x01, 0xAF })) {
            const authEnter = bytesUtil.packHeaderBytes(
                packets.Undefined2,
                packets.Undefined2{
                    .data = &[_]u8{ 0x00, 0x00, 0x00, 0x08, 0x7C, 0x35, 0x09, 0x19, 0xB2, 0x50, 0xD3, 0x49, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x32, 0x14 },
                },
            );

            _ = conn.stream.write(authEnter) catch {
                break;
            };
            continue;
        }

        std.log.info("Read size{d}", .{readSize});
        std.log.info("{x:0>2}", .{std.fmt.fmtSliceHexUpper(buf[0..readSize])});
    }
}
