const std = @import("std");
const bytes = @import("bytes.zig");
const xev = @import("xev");
const packets = @import("packets.zig");
const types = @import("types.zig");

var external_server: xev.TCP = undefined;

pub fn init(the_loop: @This()) !void {
    _ = the_loop; // autofix
    var loop = try xev.Loop.init(.{});
    defer loop.deinit();

    var address = try std.net.Address.parseIp4("127.0.0.1", 1973);
    external_server = try xev.TCP.init(address);

    // Bind and listen
    try external_server.bind(address);
    try external_server.listen(0);

    // Retrieve bound port and initialize client
    var sock_len = address.getOsSockLen();
    try std.os.getsockname(external_server.fd, &address.any, &sock_len);

    var c_accept: xev.Completion = undefined;
    var server_conn: ?xev.TCP = undefined;
    external_server.accept(&loop, &c_accept, ?xev.TCP, &server_conn, @This().on_connection);

    // Run the loop until there are no more completions.
    try loop.run(.until_done);

    std.debug.print("test222\n", .{});

    while (true) {
        std.time.sleep(1000);
    }
}

react_cb: *const fn (data: []const u8) []const u8,

pub fn on_connection(
    ud: ?*?xev.TCP,
    internal_loop: *xev.Loop,
    internal_accept: *xev.Completion,
    r: xev.AcceptError!xev.TCP,
) xev.CallbackAction {
    _ = internal_accept; // autofix
    _ = r catch |err| {
        std.debug.print("can't accept {any}", .{err});
    };

    ud.?.* = r catch unreachable;

    std.debug.print("connected {any}\n", .{r});

    //var recv_buf: [4096]u8 = undefined;
    //var recv_len: usize = 0;

    //ud.?.*.?.read(&copy_internal_loop, &copy_internal_accept, .{ .slice = &recv_buf }, usize, &recv_len, @This().on_read);

    //var recv_buf: [4096]u8 = undefined;
    //var recv_len: usize = 0;

    //var c_read: xev.Completion = undefined;
    //external_server.read(internal_loop, &c_read, .{ .slice = &recv_buf }, usize, &recv_len, @This().on_read);

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const datePkt = packets.CharacterScreen.firstDate.init(allocator) catch |err| {
        std.debug.print("can't init firstDate {any}", .{err});
        return .rearm;
    };

    const writeBuf = bytes.packHeaderBytes(packets.CharacterScreen.firstDate, datePkt);

    std.debug.print("out write buf {any}\n", .{writeBuf});

    var c_write: xev.Completion = undefined;
    external_server.write(internal_loop, &c_write, .{ .slice = writeBuf }, void, null, (struct {
        fn callback(
            _: ?*void,
            _: *xev.Loop,
            c: *xev.Completion,
            _: xev.TCP,
            _: xev.WriteBuffer,
            r2: xev.TCP.WriteError!usize,
        ) xev.CallbackAction {
            _ = r2 catch |err| {
                std.debug.print("can't accept {any}", .{err});
            };

            std.debug.print("test2ss2", .{});

            _ = c;
            return .disarm;
        }
    }).callback);

    std.debug.print("test", .{});

    return .rearm;
}

pub fn on_read(
    ud: ?*usize,
    _: *xev.Loop,
    _: *xev.Completion,
    _: xev.TCP,
    rb: xev.ReadBuffer,
    r: xev.TCP.ReadError!usize,
) xev.CallbackAction {
    std.debug.print("recv: {any}\n", .{rb.slice});
    _ = ud; // autofix
    _ = r catch |err| {
        std.debug.print("can't read {any}", .{err});
    };

    std.debug.print("recv: {any}\n", .{rb.slice});

    return .rearm;
}
