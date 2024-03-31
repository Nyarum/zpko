const std = @import("std");
const core = @import("core");
const character_screen = @import("character_screen");

test "pack with header for characters choice" {
    const allocator = std.heap.page_allocator;
    const characters_choice = character_screen.structs.CharactersChoice{};
    const auth_enter_pkt = core.bytes.packHeaderBytes(allocator, characters_choice);

    std.debug.print("characters choice: {X:1}\n", .{std.fmt.fmtSliceHexUpper(auth_enter_pkt)});
}

test "pack with header for characters choice with one character" {
    const allocator = std.heap.page_allocator;

    const character = character_screen.structs.Character{
        .job = "test",
        .level = 0,
        .active = true,
        .name = "test",
        .look = .{
            .ver = 0,
            .type_id = 0,
            .hair = 0,
            .item_grids = undefined,
        },
    };

    const characters_choice = character_screen.structs.CharactersChoice{ .characters = &[_]character_screen.structs.Character{character}, .character_len = 1 };

    const auth_enter_pkt = core.bytes.packHeaderBytes(allocator, characters_choice);

    std.debug.print("characters choice with one character: {X:1}\n", .{std.fmt.fmtSliceHexUpper(auth_enter_pkt)});
}
