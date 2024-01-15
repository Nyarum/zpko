const std = @import("std");
const Instant = std.time.Instant;
const xev = @import("xev");
const loop = @import("loop.zig");

pub fn main() !void {
    try loop.init();
}
