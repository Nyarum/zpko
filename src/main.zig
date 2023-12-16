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
const tcp = @import("./tcp.zig");

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

const Bro = struct {
    ss: u8 = 1,
    key: []const u8,
};

fn gras() void {
    //print("hey", .{});
}

pub fn main() !void {
    var addr = std.net.Address.initIp4(.{ 127, 0, 0, 1 }, 1973);
    const allocator = std.heap.page_allocator;

    var threadPool: std.Thread.Pool = undefined;
    try threadPool.init(.{
        .allocator = allocator,
    });

    var tcpServer = try tcp.TCP.init();
    defer tcpServer.server.deinit();

    try threadPool.spawn(gras, .{});
    // Main event loop

    tcpServer.start(allocator, &addr) catch |err| {
        print("Can't setup tcp server: {any}\n", .{err});
        return;
    };
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
