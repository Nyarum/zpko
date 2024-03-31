const cs = @import("import.zig");
const core = @import("core");

pub fn reactCreateCharacter(data: cs.structs.createCharacter) cs.structs.createCharacterResp {
    _ = data; // autofix

    return cs.structs.createCharacterResp{};
}
