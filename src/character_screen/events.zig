const cs = @import("import.zig");
const core = @import("core");

storage: *core.storage,

pub fn reactCreateCharacter(self: *@This(), login: []const u8, data: cs.structs.createCharacter) !cs.structs.createCharacterResp {
    try self.storage.saveCharacter(core.storage.UserLogin{ .value = login }, core.storage.Character{
        .name = data.name,
        .map = data.map,
        .look = data.look,
        .active = true,
        .job = "Newbie",
        .level = 1,
    });

    return cs.structs.createCharacterResp{};
}
