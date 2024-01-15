const std = @import("std");
const xev = @import("xev");

pub fn init() !void {
    var loop = try xev.Loop.init(.{});
    defer loop.deinit();

    var address = try std.net.Address.parseIp4("127.0.0.1", 1973);
    const server = try xev.TCP.init(address);

    // Bind and listen
    try server.bind(address);
    try server.listen(0);

    // Retrieve bound port and initialize client
    var sock_len = address.getOsSockLen();
    try std.os.getsockname(server.fd, &address.any, &sock_len);

    var c_accept: xev.Completion = undefined;
    var server_conn: ?xev.TCP = undefined;
    server.accept(&loop, &c_accept, ?xev.TCP, &server_conn, (struct {
        recv_buf: [128]u8 = undefined,
        recv_len: usize = 0,

        fn callback(
            ud: ?*?xev.TCP,
            internal_loop: *xev.Loop,
            internal_accept: *xev.Completion,
            r: xev.AcceptError!xev.TCP,
        ) xev.CallbackAction {
            _ = r catch {
                std.debug.print("test", .{});
            };

            var copy_internal_loop = internal_loop.*;
            var copy_internal_accept = internal_accept.*;

            ud.?.*.?.read(&copy_internal_loop, &copy_internal_accept, .{ .slice = &@This().recv_buf }, usize, &@This().recv_len, (struct {
                fn callback(
                    ud2: ?*usize,
                    _: *xev.Loop,
                    _: *xev.Completion,
                    _: xev.TCP,
                    _: xev.ReadBuffer,
                    r2: xev.TCP.ReadError!usize,
                ) xev.CallbackAction {
                    ud2.?.* = r2 catch unreachable;
                    return .disarm;
                }
            }).callback);

            std.debug.print("test", .{});
            return .disarm;
        }
    }).callback);

    // Run the loop until there are no more completions.
    try loop.run(.no_wait);

    while (true) {}
}
