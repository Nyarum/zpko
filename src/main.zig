const std = @import("std");
const net = std.net;
const Allocator = std.mem.Allocator;
const timeUtil = @import("./time.zig");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var server = net.StreamServer.init(.{});
    defer server.deinit();

    try server.listen(try net.Address.parseIp4("127.0.0.1", 12345));

    const time = try timeUtil.getCurrentTime(allocator);

    std.debug.print("{s}\n", .{time});

    while (true) {
        const connection = try server.accept();
        std.debug.print("Новое соединение: {}\n", .{connection.address});

        // Здесь можно обрабатывать данные соединения
        // Например, читать и отправлять сообщения
    }
}
