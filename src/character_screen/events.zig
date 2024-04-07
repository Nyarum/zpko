const cs = @import("import.zig");
const core = @import("core");
const std = @import("std");
const Allocator = std.mem.Allocator;

storage: *core.storage,
allocator: Allocator,

pub fn reactCreateCharacter(self: *@This(), login: []const u8, data: cs.structs.createCharacter) !cs.structs.createCharacterResp {
    const character = try self.allocator.create(core.storage.Character);
    character.* = core.storage.Character{
        .name = data.name,
        .map = data.map,
        .look = data.look,
        .active = true,
        .job = "Newbie",
        .level = 1,
    };

    try self.storage.saveCharacter(core.storage.UserLogin{ .value = login }, character);

    return cs.structs.createCharacterResp{};
}
