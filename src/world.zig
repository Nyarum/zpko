const std = @import("std");
const net = std.net;
const Allocator = std.mem.Allocator;
const print = std.debug.print;
const tcp = @import("./tcp.zig");
const bytesUtil = @import("./bytes.zig");
const packets = @import("./packets.zig");

const Player = struct {
    isAuth: bool = false,
};

pub const World = struct {
    players: std.AutoHashMap(std.os.socket_t, Player),
    mutex: std.Thread.Mutex = .{},

    pub fn init(allocator: Allocator) !World {
        const world = World{
            .players = std.AutoHashMap(std.os.socket_t, Player).init(allocator),
        };

        return world;
    }

    pub fn handlePlayerData(world: *World, tcpClient: *tcp.TCP, client: std.os.socket_t, data: []u8) void {
        _ = data;

        print("test bro1\n", .{});

        const player = world.getPlayer(client);

        print("test bro1 {any}\n", .{player});

        if (player == null) {
            const authEnter = bytesUtil.packHeaderBytes(
                packets.Undefined2,
                packets.Undefined2{
                    .data = &[_]u8{ 0x00, 0x00, 0x00, 0x08, 0x7C, 0x35, 0x09, 0x19, 0xB2, 0x50, 0xD3, 0x49, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x32, 0x14 },
                },
            );

            _ = world.addPlayer(client) catch |err| {
                print("err: {any}", .{err});
            };

            _ = tcpClient.send(client, authEnter) catch |err| {
                print("err: {any}", .{err});
            };
        }
    }

    pub fn addPlayer(world: *World, client: std.os.socket_t) !void {
        world.mutex.lock();
        try world.players.put(client, Player{});
        world.mutex.unlock();
    }

    pub fn getPlayer(world: *World, client: std.os.socket_t) ?Player {
        world.mutex.lock();
        defer world.mutex.unlock();

        return world.players.get(client);
    }

    pub fn removePlayer(world: *World, client: std.os.socket_t) void {
        world.mutex.lock();
        defer world.mutex.unlock();

        _ = world.players.remove(client);
    }

    pub fn deinit(world: *World) void {
        _ = world;
        //world.players.deinit(allocator);
    }
};

test "init world and add player" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var world = try World.init(allocator);

    const bro: usize = 2;

    try world.addPlayer(bro);
}
