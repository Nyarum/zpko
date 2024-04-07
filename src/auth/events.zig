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
    charactersArray: std.ArrayList(cs.structs.Character),
};

pub fn reactAuth(self: *@This(), data: auth.structs.auth) !authResp {
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

    var characters = std.ArrayList(cs.structs.Character).init(self.allocator);

    if (getUser.characters != null) {
        for (getUser.characters.?.items) |char| {
            if (char.active) {
                try characters.append(cs.structs.Character{
                    .name = char.name,
                    .look = char.look,
                    .active = char.active,
                    .job = char.job,
                    .level = char.level,
                });
            }
        }
    }

    const characters_choice = cs.structs.CharactersChoice{
        .characters = characters.items,
        .character_len = @intCast(characters.items.len),
    };

    return authResp{ .login = data.login, .characters = characters_choice, .charactersArray = characters };
}
