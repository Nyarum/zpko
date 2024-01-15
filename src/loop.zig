const std = @import("std");
const xev = @import("xev");

pub const Loop = struct {
    fn on_connection(
        ud: ?*?xev.TCP,
        internal_loop: *xev.Loop,
        internal_accept: *xev.Completion,
        r: xev.AcceptError!xev.TCP,
    ) xev.CallbackAction {
        _ = r catch |err| {
            std.debug.print("can't accept {any}", .{err});
        };

        var recv_buf: [128]u8 = undefined;
        var recv_len: usize = 0;

        var copy_internal_loop = internal_loop.*;
        var copy_internal_accept = internal_accept.*;

        ud.?.*.?.read(&copy_internal_loop, &copy_internal_accept, .{ .slice = &recv_buf }, usize, &recv_len, @This().on_read);

        return .disarm;
    }

    fn on_read(
        ud: ?*usize,
        _: *xev.Loop,
        _: *xev.Completion,
        _: xev.TCP,
        _: xev.ReadBuffer,
        r: xev.TCP.ReadError!usize,
    ) xev.CallbackAction {
        _ = ud; // autofix
        _ = r catch |err| {
            std.debug.print("can't read {any}", .{err});
        };

        return .disarm;
    }

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
        server.accept(&loop, &c_accept, ?xev.TCP, &server_conn, @This().on_connection);

        // Run the loop until there are no more completions.
        try loop.run(.no_wait);

        while (true) {}
    }
};
