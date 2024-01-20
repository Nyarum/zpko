pub const CharacterScreen = @import("character_screen.zig");

pub const Undefined2 = struct {
    opcode: ?u16 = 931,
    data: []const u8,
};
