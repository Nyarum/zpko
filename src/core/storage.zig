const std = @import("std");
const Allocator = std.mem.Allocator;
const cs = @import("character_screen");
const core = @import("core");
const Endian = std.builtin.Endian;

pub const UUID = struct {
    uuid: []const u8,
};

pub const UUIDContext = struct {
    pub fn hash(_: UUIDContext, k: UUID) u64 {
        var h = std.hash.Fnv1a_64.init();
        h.update(k.uuid);

        return h.final();
    }

    pub fn eql(_: UUIDContext, a: UUID, b: UUID) bool {
        return std.mem.eql(u8, a.uuid, b.uuid);
    }
};

pub fn generateUUID() !UUID {
    var uuid_bytes: [16]u8 = undefined;
    std.crypto.random.bytes(&uuid_bytes);

    // Set the UUID to version 4 (random)
    uuid_bytes[6] = (uuid_bytes[6] & 0x0f) | 0x40;
    // Set the UUID to variant 1 (RFC 4122)
    uuid_bytes[8] = (uuid_bytes[8] & 0x3f) | 0x80;

    const uuid_str = try std.fmt.allocPrint(
        std.heap.page_allocator,
        "{X:0>4}-{X:0>4}-{X:0>4}-{X:0>4}",
        .{
            std.mem.readInt(u32, uuid_bytes[0..4], Endian.big),
            std.mem.readInt(u32, uuid_bytes[4..8], Endian.big),
            std.mem.readInt(u32, uuid_bytes[8..12], Endian.big),
            std.mem.readInt(u32, uuid_bytes[12..16], Endian.big),
        },
    );

    return .{ .uuid = uuid_str };
}

pub const UserLogin = struct {
    value: []const u8,
};

pub const UserLoginContext = struct {
    pub fn hash(_: UserLoginContext, k: UserLogin) u64 {
        var h = std.hash.Fnv1a_64.init();
        h.update(k.value);

        return h.final();
    }

    pub fn eql(_: UserLoginContext, a: UserLogin, b: UserLogin) bool {
        return std.mem.eql(u8, a.value, b.value);
    }
};

pub const UserReq = struct {
    login: UserLogin,
    character: cs.structs.Character,
};

pub const User = struct {
    uuid: UUID,
    login: UserLogin,
    character: cs.structs.Character,
};

const allocator = std.heap.page_allocator;
var users = std.HashMap(UserLogin, User, UserLoginContext, 10).init(allocator);

const SaveUserResp = struct {
    uuid: []u8,
    character: cs.structs.Character,
};

pub fn saveUser(v: UserReq) !UUID {
    const uuid = generateUUID() catch |err| {
        // Handle the error here
        std.debug.print("Error generating UUID: {}\n", .{err});
        return err;
    };

    const user = User{
        .uuid = uuid,
        .login = v.login,
        .character = v.character,
    };

    users.put(v.login, user) catch |err| {
        // Handle the error here
        std.debug.print("Error saving character: {}\n", .{err});
        return err;
    };

    return uuid;
}

pub fn saveCharacter(login: UserLogin, v: cs.structs.Character) !void {
    var user = getUser(login);
    if (user == null) {
        return error.UserNotFound;
    }

    user.?.character = v;

    users.put(login, user.?) catch |err| {
        // Handle the error here
        std.debug.print("Error saving character: {}\n", .{err});
        return err;
    };

    return;
}

pub fn getUser(login: UserLogin) ?User {
    return users.get(login);
}
