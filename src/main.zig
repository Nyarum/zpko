const std = @import("std");
const Instant = std.time.Instant;
const xev = @import("xev");
const loop = @import("loop.zig");
const events = @import("events.zig");

pub fn main() !void {
    const the_loop = loop.Loop{ .react_cb = events.Events.react };

    try the_loop.init();
}
