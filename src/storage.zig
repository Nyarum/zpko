const std = @import("std");
const Allocator = std.mem.Allocator;
const models = @import("./models.zig");

pub const Storage = struct {
    users: std.AutoHashMap(u32, models.User),

    pub fn init(allocator: Allocator) Storage {
        return Storage{
            .users = std.AutoHashMap(u32, models.User).init(
                allocator,
            ),
        };
    }
};
