const std = @import("std");
const print = std.debug.print;
const timeUtil = @import("time.zig");
const Allocator = std.mem.Allocator;
const bytes = @import("bytes.zig");
const custom_types = @import("types.zig");
const sub_packets = @import("sub_packets.zig");

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

pub const CharactersChoice = struct {
    opcode: u16 = 931,
    error_code: u16 = 0,
    key: custom_types.bytes = custom_types.bytes{ .value = &[_]u8{ 0x7C, 0x35, 0x09, 0x19, 0xB2, 0x50, 0xD3, 0x49 } },
    character_len: u8 = 0,
    characters: []const sub_packets.Character = &[_]sub_packets.Character{},
    pincode: u8 = 1,
    encryption: u32 = 0,
    dw_flag: u32 = 12820,
};

pub const createCharacter = struct { opcode: u16 };

fn prints(comptime text: []const u8, param: anytype) void {
    std.debug.print(text ++ ": {any}", .{param});
}

test "pack with header for characters choice" {
    const allocator = std.heap.page_allocator;
    const characters_choice = CharactersChoice{};
    const auth_enter_pkt = bytes.packHeaderBytes(allocator, characters_choice);

    std.debug.print("bytes output: {X:1}\n", .{std.fmt.fmtSliceHexUpper(auth_enter_pkt)});
}

test "pack with header for characters choice with one character" {
    const allocator = std.heap.page_allocator;

    const character = sub_packets.Character{
        .job = "test",
        .level = 0,
        .active = true,
        .name = "test",
        .look = .{
            .ver = 0,
            .type_id = 0,
            .hair = 0,
            .item_grids = undefined,
        },
    };

    const characters_choice = CharactersChoice{ .characters = &[_]sub_packets.Character{character}, .character_len = 1 };

    const auth_enter_pkt = bytes.packHeaderBytes(allocator, characters_choice);

    std.debug.print("bytes output: {X:1}\n", .{std.fmt.fmtSliceHexUpper(auth_enter_pkt)});
}
