const std = @import("std");
const net = std.net;
const Allocator = std.mem.Allocator;
const timeUtil = @import("./time.zig");
const bytesUtil = @import("./bytes.zig");
const uuid = @import("./uuid.zig");
const print = std.debug.print;

const Auth = struct {
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

pub fn main() !void {
    print("{s}\n", .{uuid.UUID4.generate()});

    const bytes = [_]u8{
        0x00,
        0x01,
        0x02,
        0x00,
        0x01,
        0x02,
        0x00,
        0x01,
        0x02,
        0x00,
        0x01,
        0x02,
        0x00,
        0x02,
        0x00,
        0x03,
    };

    const bro = Bro{
        .key = "bro",
    };

    const buf = bytesUtil.packBytes(Bro, bro);
    std.debug.print("{any}", .{buf});

    const myStruct = bytesUtil.unpackBytes(Auth, &bytes);

    std.debug.print("field1: {any}\n", .{myStruct.is_cheat});

    const allocator = std.heap.page_allocator;

    var server = net.StreamServer.init(.{});
    defer server.deinit();

    try server.listen(try net.Address.parseIp4("127.0.0.1", 1973));

    const time = try timeUtil.getCurrentTime(allocator);

    std.debug.print("{s}\n", .{time});

    while (true) {
        const connection = try server.accept();

        std.debug.print("New connection: {}\n", .{connection.address});

        const thread = std.Thread.spawn(.{}, handleConnection, .{connection}) catch |err| {
            std.log.err("can't spawn {any}", .{err});
            continue;
        };
        thread.detach();

        const firstDate = bytesUtil.packHeaderBytes(940, time);
        const size = try connection.stream.write(firstDate);
        _ = size;
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
                931,
                &[_]u8{ 0x00, 0x00, 0x00, 0x08, 0x7C, 0x35, 0x09, 0x19, 0xB2, 0x50, 0xD3, 0x49, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x32, 0x14 },
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
