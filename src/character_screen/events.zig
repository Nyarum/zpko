const cs = @import("import.zig");
const core = @import("core");
const std = @import("std");
const Allocator = std.mem.Allocator;

storage: *core.storage,
allocator: Allocator,

pub fn reactCreateCharacter(self: *@This(), login: []const u8, data: cs.structs.createCharacter) !cs.structs.createCharacterResp {
    const name = try self.allocator.dupe(u8, data.name);
    const map = try self.allocator.dupe(u8, data.map);

    try self.storage.saveCharacter(core.storage.UserLogin{ .value = login }, core.storage.Character{
        .name = name,
        .map = map,
        .look = data.look,
        .active = true,
        .job = "Newbie",
        .level = 1,
    });

    return cs.structs.createCharacterResp{};
}
