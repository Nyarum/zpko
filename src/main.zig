const std = @import("std");
const net = std.net;
const Allocator = std.mem.Allocator;
const timeUtil = @import("./time.zig");

fn packBytes(opcode: u16, buf: []const u8) []const u8 {
    const len = buf.len + 8;

    var lenBuf: [4096]u8 = undefined;
    std.mem.writeInt(u16, lenBuf[0..2], @as(u16, @intCast(len)), std.builtin.Endian.big);
    std.mem.writeInt(u32, lenBuf[2..6], 0x80, std.builtin.Endian.little);
    std.mem.writeInt(u16, lenBuf[6..8], opcode, std.builtin.Endian.big);
    std.mem.copyForwards(u8, lenBuf[8..len], buf[0..]);

    std.log.info("{x:0>2}", .{std.fmt.fmtSliceHexUpper(lenBuf[0..len])});

    return lenBuf[0..len];
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var server = net.StreamServer.init(.{});
    defer server.deinit();

    try server.listen(try net.Address.parseIp4("127.0.0.1", 1973));

    const time = try timeUtil.getCurrentTime(allocator);

    std.debug.print("{s}\n", .{time});

    while (true) {
        const connection = try server.accept();

        std.debug.print("New connection: {}\n", .{connection.address});

        const firstDate = packBytes(940, time);
        const size = try connection.stream.write(firstDate);

        std.log.info("Write size {d}", .{size});

        var lenBuf: [4096]u8 = undefined;
        while (true) {
            const readSize = connection.stream.read(&lenBuf) catch |err| {
                std.log.err("can't read from connection {any}", .{err});
                break;
            };

            if (readSize == 0) {
                std.log.debug("connection is closed", .{});
                break;
            }

            if (std.mem.eql(u8, lenBuf[6..8], &[_]u8{ 0x01, 0xB0 })) {
                std.log.debug("connection is closed", .{});
                break;
            }

            if (readSize == 2) {
                _ = try connection.stream.write(&[_]u8{ 0x00, 0x02 });
                continue;
            }

            if (std.mem.eql(u8, lenBuf[6..8], &[_]u8{ 0x01, 0xAF })) {
                const authEnter = packBytes(
                    931,
                    &[_]u8{ 0x00, 0x00, 0x00, 0x08, 0x7C, 0x35, 0x09, 0x19, 0xB2, 0x50, 0xD3, 0x49, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x32, 0x14 },
                );

                _ = try connection.stream.write(authEnter);
                continue;
            }

            std.log.info("Read size{d}", .{readSize});
            std.log.info("{x:0>2}", .{std.fmt.fmtSliceHexUpper(lenBuf[0..readSize])});
        }

        connection.stream.close();
    }
}
