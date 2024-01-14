const std = @import("std");
const Instant = std.time.Instant;
const xev = @import("xev");

pub fn main() !void {
    // Initialize the loop state. Notice we can use a stack-allocated
    // value here. We can even pass around the loop by value! The loop
    // will contain all of our "completions" (watches).
    var loop = try xev.Loop.init(.{});
    defer loop.deinit();

    var address = try std.net.Address.parseIp4("127.0.0.1", 0);
    const server = try xev.TCP.init(address);

    // Bind and listen
    try server.bind(address);
    try server.listen(1);

    // Retrieve bound port and initialize client
    var sock_len = address.getOsSockLen();
    try std.os.getsockname(server.fd, &address.any, &sock_len);

    var c_accept: xev.Completion = undefined;
    var server_conn: ?xev.TCP = undefined;
    server.accept(&loop, &c_accept, ?xev.TCP, &server_conn, (struct {
        fn callback(
            ud: ?*?xev.TCP,
            _: *xev.Loop,
            _: *xev.Completion,
            r: xev.AcceptError!xev.TCP,
        ) xev.CallbackAction {
            _ = ud; // autofix
            _ = r catch {
                std.debug.print("test", .{});
            }; // autofix
            std.debug.print("test", .{});
            return .disarm;
        }
    }).callback);

    // Run the loop until there are no more completions.
    try loop.run(.until_done);
}
