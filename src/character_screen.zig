const std = @import("std");
const print = std.debug.print;
const timeUtil = @import("../time.zig");
const Allocator = std.mem.Allocator;
const bytes = @import("bytes.zig");
const custom_types = @import("types");

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

pub const InstAttr = struct {
    id: u16,
    value: u16,
};

pub const ItemAttr = struct {
    attr: u16,
    is_init: bool,
};

pub const ItemGrid = struct {
    id: u16,
    num: u16,
    endure: [2]u16,
    energy: [2]u16,
    forge_lv: u8,
    db_params: [2]u32,
    inst_attrs: [5]InstAttr,
    item_attrs: [40]ItemAttr,
    is_change: bool,
};

pub const Look = struct {
    ver: u16,
    type_id: u16,
    item_grids: [10]ItemGrid,
    hair: u16,
};

pub const Character = struct {
    active: bool,
    name: [32]u8,
    job: [32]u8,
    map: [32]u8,
    level: u16,
    look_size: u16,
    look: Look,
};

pub const CharactersChoice = struct {
    opcode: u16 = 931,
    error_code: u16,
    key_len: u16,
    key: []const u8,
    character_len: u8,
    characters: []const Character,
    pincode: u8,
    encryption: u32,
    dw_flag: u32,
};

fn prints(comptime text: []const u8, param: anytype) void {
    std.debug.print(text ++ ": {any}", .{param});
}

test "pack with header for characters choice" {
    const characters_choice = CharactersChoice{
        .error_code = 0,
        .key_len = 32,
        .key = &[_]u8{0} ** 32,
        .character_len = 1,
        .characters = &[_]Character{.{
            .active = true,
            .name = [_]u8{0} ** 32,
            .job = [_]u8{0} ** 32,
            .map = [_]u8{0} ** 32,
            .level = 0,
            .look_size = 0,
            .look = .{ .ver = 0, .type_id = 0, .item_grids = undefined, .hair = 0 },
        }},
        .pincode = 0,
        .encryption = 0,
        .dw_flag = 0,
    };
    const auth_enter_pkt = bytes.packHeaderBytes(CharactersChoice, characters_choice);

    std.debug.print("bytes output: {X:1}\n", .{auth_enter_pkt});
}
