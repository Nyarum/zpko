const std = @import("std");
const cs = @import("character_screen.zig");
const bytes = @import("bytes.zig");
const custom_types = @import("types.zig");

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
    const character = cs.Character{
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

    const characters_choice = cs.CharactersChoice{ .characters = &[_]cs.Character{character}, .character_len = 1 };

    return authResp{ .characters = characters_choice };
}

test "reactAuth" {
    react(431, &[_]u8{});
}
