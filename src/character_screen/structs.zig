const std = @import("std");
const core = @import("core");

pub const InstAttr = struct {
    id: u16 = 0,
    value: u16 = 0,
};

pub const ItemAttr = struct {
    attr: u16 = 0,
    is_init: bool = false,
};

pub const ItemGrid = struct {
    id: u16 = 0,
    num: u16 = 0,
    endure: [2]u16 = [2]u16{ 0, 0 },
    energy: [2]u16 = [2]u16{ 0, 0 },
    forge_lv: u8 = 0,
    db_params: [2]u32 = [2]u32{ 0, 0 },
    inst_attrs: [5]InstAttr = undefined,
    item_attrs: [40]ItemAttr = undefined,
    is_change: bool = false,
};

pub const Look = struct {
    ver: u16,
    type_id: u16,
    item_grids: [10]ItemGrid = undefined,
    hair: u16,
};

pub const Character = struct {
    active: bool = false,
    name: []const u8,
    job: []const u8,
    level: u16,
    look: Look,
};

pub const CharactersChoice = struct {
    opcode: u16 = 931,
    error_code: u16 = 0,
    key: core.types.bytes = core.types.bytes{ .value = &[_]u8{ 0x7C, 0x35, 0x09, 0x19, 0xB2, 0x50, 0xD3, 0x49 } },
    character_len: u8 = 0,
    characters: []*Character = undefined,
    pincode: u8 = 1,
    encryption: u32 = 0,
    dw_flag: u32 = 12820,
};

pub const createCharacter = struct {
    name: []const u8,
    map: []const u8,
    look: Look,
};

pub const createCharacterResp = struct {
    opcode: u16 = 935,
    error_code: u16 = 0,
};
