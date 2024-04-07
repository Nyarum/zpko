const std = @import("std");
const auth = @import("auth");
const cs = @import("character_screen");
const core = @import("import.zig");
const lmdb = @import("lmdb");
const Allocator = std.mem.Allocator;

storage: *core.storage = undefined,
state: State = undefined,
authEvents: auth.events = undefined,
csEvents: cs.events = undefined,
allocator: Allocator = undefined,

pub const State = struct {
    login: []u8 = undefined,
};

pub fn react(self: *@This(), opcode: u16, data: []const u8) !?[]const u8 {
    switch (opcode) {
        431 => { // auth
            const res = try self.authEvents.reactAuth(
                core.bytes.unpackBytes(auth.structs.auth, data).return_type,
            );

            defer res.charactersArray.deinit();

            self.state.login = self.allocator.alloc(u8, res.login.len) catch unreachable;
            for (res.login, 0..res.login.len) |char, index| {
                self.state.login[index] = char;
            }

            const buf = core.bytes.packHeaderBytes(self.allocator, res.characters);

            return buf;
        },
        432 => { // exit
            return null;
        },
        435 => { // create character
            const createCharUnpack = core.bytes.unpackBytes(cs.structs.createCharacter, data);

            std.log.info("login {any}", .{self.state.login});

            const res = try self.csEvents.reactCreateCharacter(
                self.state.login,
                createCharUnpack.return_type,
            );

            //std.debug.print("create character: len({any}) {any}\n", .{ createCharUnpack.buf, createCharUnpack.return_type });

            const buf = core.bytes.packHeaderBytes(self.allocator, res);

            return buf;
        },
        else => {
            std.debug.print("no way, opcode {any}\n", .{opcode});
        },
    }

    return "t";
}

test "reactAuth" {
    react(431, &[_]u8{});
}
