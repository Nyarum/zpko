const cs = @import("character_screen");
const auth = @import("import.zig");
const core = @import("core");
const std = @import("std");
const Allocator = std.mem.Allocator;

storage: *core.storage,
allocator: Allocator,

const authResp = struct {
    login: []const u8,
    characters: cs.structs.CharactersChoice,
    charactersArray: std.ArrayList(*cs.structs.Character),
};

pub fn reactAuth(self: *@This(), data: auth.structs.auth) !authResp {
    std.log.info("react auth: {any}", .{data});

    var user = self.storage.getUser(core.storage.UserLogin{
        .value = data.login,
    });

    const login = self.allocator.alloc(u8, data.login.len) catch unreachable;
    for (data.login, 0..data.login.len) |char, index| {
        login[index] = char;
    }

    if (user == null) {
        _ = try self.storage.saveUser(core.storage.UserReq{
            .login = core.storage.UserLogin{
                .value = login,
            },
        });

        user = self.storage.getUser(core.storage.UserLogin{
            .value = login,
        });
    }

    const getUser = user.?;

    if (getUser.characters != null) {
        for (getUser.characters.?.items, 0..getUser.characters.?.items.len) |char, index| {
            std.log.info("char 2 {s} index {any}", .{ char.name, index });
        }
    }

    var characters = std.ArrayList(*cs.structs.Character).init(std.heap.page_allocator);

    std.log.info("react auth 2: {any}", .{data});

    if (getUser.characters != null) {
        for (getUser.characters.?.items) |char| {
            if (char.active) {
                const character = try self.allocator.create(cs.structs.Character);
                character.* = cs.structs.Character{
                    .name = char.name,
                    .look = char.look,
                    .active = char.active,
                    .job = char.job,
                    .level = char.level,
                };

                try characters.append(character);
            }
        }
    }

    const characters_choice = cs.structs.CharactersChoice{
        .characters = characters.items,
        .character_len = @intCast(characters.items.len),
    };

    return authResp{ .login = data.login, .characters = characters_choice, .charactersArray = characters };
}
