const std = @import("std");
const Allocator = std.mem.Allocator;
const cs = @import("character_screen");

const allocator = std.heap.page_allocator;
var users = std.AutoHashMap(u32, std.ArrayList(u8)).init(allocator);

pub fn saveUser(v: cs.Character) !void {
    var out = std.ArrayList(u8).init(allocator);
    defer out.deinit();

    try std.json.stringify(v, .{}, out.writer());

    std.debug.print("save character: {s}\n", .{out.items});

    try users.put(1, try out.clone());
}

pub fn getUser(id: u32) ?cs.Character {
    if (users.get(id)) |v| {
        const chs = std.json.parseFromSlice(cs.Character, allocator, v.items, .{}) catch |err| {
            std.debug.print("error parsing character: {any}\n", .{err});
            return null;
        };

        return chs.value;
    }

    return null;
}

test "try save user" {
    try saveUser(cs.structs.Character{
        .active = true,
        .job = "Warrior",
        .level = 1,
        .name = "test",
        .look = cs.structs.Look{ .hair = 0, .item_grids = undefined, .type_id = 0, .ver = 0 },
    });

    if (getUser(1)) |v| {
        std.debug.print("bro {any}\n", .{v});
    } else {
        std.debug.print("value is null\n", .{});
    }
}
