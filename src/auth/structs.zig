const std = @import("std");
const print = std.debug.print;
const timeUtil = @import("time.zig");
const Allocator = std.mem.Allocator;
const custom_types = @import("types.zig");

pub const firstDate = struct {
    opcode: ?u16 = 940,
    date: custom_types.plain_string,

    pub fn init(allocator: Allocator) !firstDate {
        const date = custom_types.plain_string{ .value = try timeUtil.getCurrentTime(allocator) };

        return firstDate{
            .date = date,
        };
    }
};

pub const auth = struct {
    opcode: ?u16 = 431,
    key: []const u8,
    login: []const u8,
    password: []const u8,
    mac: []const u8,
    is_cheat: u16,
    client_version: u16,

    pub fn bro(_: auth) void {
        print("test", .{});
    }
};
