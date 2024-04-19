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

pub fn react(self: *@This(), opcode: core.opcodes.Opcode, data: []const u8) !?[]const u8 {
    switch (opcode) {
        core.opcodes.Opcode.Auth => {
            const res = try self.authEvents.reactAuth(
                core.bytes.unpackBytes(auth.structs.auth, data, std.builtin.Endian.big).return_type,
            );

            defer res.charactersArray.deinit();

            self.state.login = self.allocator.alloc(u8, res.login.len) catch unreachable;
            for (res.login, 0..res.login.len) |char, index| {
                self.state.login[index] = char;
            }

            const buf = core.bytes.packHeaderBytes(self.allocator, res.characters);

            return buf;
        },
        core.opcodes.Opcode.Exit => {
            return null;
        },
        core.opcodes.Opcode.CreateCharacter => {
            const createCharUnpack = core.bytes.unpackBytes(cs.structs.createCharacter, data, std.builtin.Endian.big);

            std.log.info("login {any}", .{self.state.login});

            const res = try self.csEvents.reactCreateCharacter(
                self.state.login,
                createCharUnpack.return_type,
            );

            const buf = core.bytes.packHeaderBytes(self.allocator, res);

            return buf;
        },
        core.opcodes.Opcode.EnterWorld => {
            const enterWorldUnpack = core.bytes.unpackBytes(cs.structs.enterGameRequest, data, std.builtin.Endian.big);

            const res = try self.csEvents.reactEnterWorld(
                self.state.login,
                enterWorldUnpack.return_type,
            );

            const buf = core.bytes.packHeaderBytes(self.allocator, res);

            return buf;
        },
    }

    std.debug.print("no way, opcode {any}\n", .{opcode});

    return null;
}

test "reactAuth" {
    react(431, &[_]u8{});
}
