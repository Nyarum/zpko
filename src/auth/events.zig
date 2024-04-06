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
};

pub fn reactAuth(self: *@This(), data: auth.structs.auth) !authResp {
    var user = self.storage.getUser(core.storage.UserLogin{
        .value = data.login,
    });

    if (user == null) {
        _ = try self.storage.saveUser(core.storage.UserReq{
            .login = core.storage.UserLogin{
                .value = data.login,
            },
        });

        std.log.info("last check: {any}", .{self.storage.users.count()});

        user = self.storage.getUser(core.storage.UserLogin{
            .value = data.login,
        });
    }

    std.log.info("\n get user: {any} sdsad {d}", .{ user, 1 });

    const getUser = user.?;

    std.log.info("\n last check: {any}", .{self.storage.users.count()});

    var characters = std.ArrayList(cs.structs.Character).init(std.heap.page_allocator);
    defer characters.deinit();

    for (getUser.characters.items) |char| {
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

    const characters_choice = cs.structs.CharactersChoice{
        .characters = characters.items,
        .character_len = @intCast(characters.capacity),
    };

    return authResp{ .login = data.login, .characters = characters_choice };
}
