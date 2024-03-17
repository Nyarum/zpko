const std = @import("std");
const cs = @import("character_screen.zig");
const bytes = @import("bytes.zig");
const custom_types = @import("types.zig");
const sub_packets = @import("sub_packets.zig");
const lmdb = @import("lmdb");

db: lmdb.Environment = undefined,

pub fn react(allocator: std.mem.Allocator, opcode: u16, data: []const u8) ?[]const u8 {
    switch (opcode) {
        431 => { // auth
            const res = reactAuth(
                bytes.unpackBytes(cs.auth, data),
            );

            const buf = bytes.packHeaderBytes(allocator, res.characters);

            return buf;
        },
        432 => { // exit
            return null;
        },
        435 => { // create character
            const res = reactCreateCharacter(
                bytes.unpackBytes(cs.createCharacter, data),
            );

            const buf = bytes.packHeaderBytes(allocator, res.characters);

            return buf;
        },
        else => {
            std.debug.print("no way, opcode {any}\n", .{opcode});
        },
    }

    return "t";
}

const authResp = union {
    characters: cs.CharactersChoice,
};

fn reactAuth(data: cs.auth) authResp {
    _ = data; // autofix
    const character = sub_packets.Character{
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

    const character1 = sub_packets.Character{
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

    const character2 = sub_packets.Character{
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

    const characters_choice = cs.CharactersChoice{
        .characters = &[_]sub_packets.Character{ character, character1, character2 },
        .character_len = 3,
    };

    return authResp{ .characters = characters_choice };
}

fn reactCreateCharacter(data: cs.createCharacter) authResp {
    _ = data; // autofix

    return authResp{};
}

test "reactAuth" {
    react(431, &[_]u8{});
}
