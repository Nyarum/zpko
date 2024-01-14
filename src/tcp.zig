const std = @import("std");
const Allocator = std.mem.Allocator;
const timeUtil = @import("./time.zig");
const bytesUtil = @import("./bytes.zig");
const uuid = @import("./uuid.zig");
const storage = @import("./storage.zig");
const packets = @import("./packets.zig");
const print = std.debug.print;
const world = @import("./world.zig");
const network = @import("network");

pub const TCP = struct {
    mutex: std.Thread.Mutex = .{},
    threadPool: std.Thread.Pool = undefined,
    newWorld: *world.World,

    pub fn init(allocator: Allocator, newWorld: *world.World) !*TCP {
        var tcp = TCP{
            .newWorld = newWorld,
        };

        try tcp.threadPool.init(.{
            .allocator = allocator,
        });

        return &tcp;
    }

    pub fn start(tcp: *TCP, port: u16) !void {
        _ = tcp; // autofix
        var sock = try network.Socket.create(.ipv4, .tcp);
        defer sock.close();

        try sock.bindToPort(port);

        try sock.listen();

        while (true) {
            var client = try sock.accept();
            defer client.close();

            std.debug.print("Client connected from {}.\n", .{
                try client.getLocalEndPoint(),
            });

            runEchoClient(client) catch |err| {
                std.debug.print("Client disconnected with msg {s}.\n", .{
                    @errorName(err),
                });
                continue;
            };

            std.debug.print("Client disconnected.\n", .{});
        }
    }
};

fn runEchoClient(client: network.Socket) !void {
    while (true) {
        var buffer: [8192]u8 = undefined;

        const len = try client.receive(&buffer);
        if (len == 0)
            break;

        // we ignore the amount of data sent.
        _ = try client.send(buffer[0..len]);
    }
}
