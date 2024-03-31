const std = @import("std");
const cs = @import("character_screen");
const core = @import("core");

test "storage try save user and character" {
    _ = core.storage.saveUser(core.storage.UserReq{
        .login = core.storage.UserLogin{ .value = "test" },
        .character = cs.structs.Character{
            .active = true,
            .job = "Warrior",
            .level = 1,
            .name = "test",
            .look = cs.structs.Look{ .hair = 0, .item_grids = undefined, .type_id = 0, .ver = 0 },
        },
    }) catch |err| {
        // Handle the error here
        std.debug.print("Error saving character: {}\n", .{err});
        return;
    };

    core.storage.saveCharacter(
        core.storage.UserLogin{ .value = "test" },
        cs.structs.Character{
            .active = false,
            .job = "Warrior",
            .level = 1,
            .name = "test",
            .look = cs.structs.Look{ .hair = 0, .item_grids = undefined, .type_id = 0, .ver = 0 },
        },
    ) catch |err| {
        // Handle the error here
        std.debug.print("Error saving character: {}\n", .{err});
        return;
    };

    if (core.storage.getUser(core.storage.UserLogin{ .value = "test" })) |v| {
        std.debug.print("bro {any}\n", .{v});
    } else {
        std.debug.print("value is null\n", .{});
    }
}
