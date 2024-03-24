const std = @import("std");
const auth = @import("auth");
const cs = @import("character_screen");
const core = @import("import.zig");
const lmdb = @import("lmdb");

db: lmdb.Environment = undefined,

pub fn react(allocator: std.mem.Allocator, opcode: u16, data: []const u8) ?[]const u8 {
    switch (opcode) {
        431 => { // auth
            const res = reactAuth(
                core.bytes.unpackBytes(auth.structs.auth, data).return_type,
            );

            const buf = core.bytes.packHeaderBytes(allocator, res.characters);

            return buf;
        },
        432 => { // exit
            return null;
        },
        435 => { // create character
            const res = reactCreateCharacter(
                core.bytes.unpackBytes(cs.structs.createCharacter, data).return_type,
            );

            const buf = core.bytes.packHeaderBytes(allocator, res.characters);

            return buf;
        },
        else => {
            std.debug.print("no way, opcode {any}\n", .{opcode});
        },
    }

    return "t";
}

const authResp = union {
    characters: cs.structs.CharactersChoice,
};

fn reactAuth(data: auth.structs.auth) authResp {
    _ = data; // autofix
    const character = cs.structs.Character{
        .job = "test",
        .level = 1,
        .active = true,
        .name = "test",
        .look = .{
            .ver = 0,
            .type_id = 512,
            .hair = 3592,
            .item_grids = undefined,
        },
    };

    const character1 = cs.structs.Character{
        .job = "test",
        .level = 1,
        .active = true,
        .name = "test222",
        .look = .{
            .ver = 0,
            .type_id = 512,
            .hair = 3592,
            .item_grids = undefined,
        },
    };

    const character2 = cs.structs.Character{
        .job = "test",
        .level = 1,
        .active = true,
        .name = "test23",
        .look = .{
            .ver = 0,
            .type_id = 512,
            .hair = 3592,
            .item_grids = undefined,
        },
    };

    const characters_choice = cs.structs.CharactersChoice{
        .characters = &[_]cs.structs.Character{ character, character1, character2 },
        .character_len = 3,
    };

    return authResp{ .characters = characters_choice };
}

fn reactCreateCharacter(data: cs.structs.createCharacter) authResp {
    _ = data; // autofix

    return authResp{ .characters = cs.structs.CharactersChoice{} };
}

test "reactAuth" {
    react(431, &[_]u8{});
}
