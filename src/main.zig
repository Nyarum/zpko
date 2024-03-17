const std = @import("std");
const Instant = std.time.Instant;
const xev = @import("xev");
const the_loop = @import("loop.zig");
const events = @import("events.zig");
const lmdb = @import("lmdb");
const database = @import("database.zig");

pub fn main() !void {
    const env = try lmdb.Environment.init("database", .{});
    defer env.deinit();

    //try database.saveCharacter(env);

    var thread_pool = xev.ThreadPool.init(.{});
    defer thread_pool.deinit();
    defer thread_pool.shutdown();

    const GPA = std.heap.GeneralPurposeAllocator(.{});
    var gpa: GPA = .{};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var server_loop = try xev.Loop.init(.{
        .entries = std.math.pow(u13, 2, 12),
        .thread_pool = &thread_pool,
    });
    defer server_loop.deinit();

    var server = try the_loop.Server.init(alloc, &server_loop, env);
    defer server.deinit();
    try server.start();

    try the_loop.Server.threadMain(&server);
}
