const std = @import("std");
const net = std.net;
const Allocator = std.mem.Allocator;
const timeUtil = @import("./time.zig");
const bytesUtil = @import("./bytes.zig");
const uuid = @import("./uuid.zig");
const storage = @import("./storage.zig");
const packets = @import("./packets.zig");
const world = @import("./world.zig");
const print = std.debug.print;
const io_uring = std.os.linux.IO_Uring;
const MAX_EVENTS = 1024; // Adjust based on expected load
const tcp = @import("./tcp.zig");

const Auth = struct {
    opcode: ?u16 = 431,
    key: []const u8,
    login: []const u8,
    password: []const u8,
    mac: []const u8,
    is_cheat: u16,
    client_version: u16,

    pub fn bro(_: Auth) void {
        print("test", .{});
    }
};

const Bro = struct {
    ss: u8 = 1,
    key: []const u8,
};

fn gras() void {
    //print("hey", .{});
}

pub fn main() !void {
    var addr = std.net.Address.initIp4(.{ 127, 0, 0, 1 }, 1973);
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var newWorld = try world.World.init(allocator);
    defer newWorld.deinit();

    var tcpServer = try tcp.TCP.init(
        allocator,
        &newWorld,
    );
    defer tcpServer.deinit();

    tcpServer.start(allocator, &addr) catch |err| {
        print("Can't setup tcp server: {any}\n", .{err});
        return;
    };

    print("testss\n", .{});
}
