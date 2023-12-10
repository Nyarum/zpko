const std = @import("std");
const Allocator = std.mem.Allocator;
const models = @import("./models.zig");

const Storage = struct {
    users: std.HashMap,

    fn init(allocator: Allocator) Storage {
        return Storage{
            .users = std.AutoHashMap(u32, models.User).init(
                allocator,
            ),
        };
    }
};
