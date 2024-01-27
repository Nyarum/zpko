const std = @import("std");
const bytes = @import("bytes.zig");
const xev = @import("xev");
const cs = @import("character_screen.zig");
const types = @import("types.zig");
const Allocator = std.mem.Allocator;
const events = @import("events.zig");

const BufferPool = std.heap.MemoryPoolExtra([4096]u8, .{ .alignment = 0 });
const CompletionPool = std.heap.MemoryPool(xev.Completion);
const TCPPool = std.heap.MemoryPool(xev.TCP);

pub const Server = struct {
    loop: *xev.Loop,
    buffer_pool: BufferPool,
    completion_pool: CompletionPool,
    socket_pool: TCPPool,
    stop: bool,
    alloc: Allocator,

    pub fn init(alloc: Allocator, loop: *xev.Loop) !Server {
        return .{
            .loop = loop,
            .buffer_pool = BufferPool.init(alloc),
            .completion_pool = CompletionPool.init(alloc),
            .socket_pool = TCPPool.init(alloc),
            .stop = false,
            .alloc = alloc,
        };
    }

    pub fn deinit(self: *Server) void {
        self.buffer_pool.deinit();
        self.completion_pool.deinit();
        self.socket_pool.deinit();
    }

    /// Must be called with stable self pointer.
    pub fn start(self: *Server) !void {
        const addr = try std.net.Address.parseIp4("127.0.0.1", 1973);
        var socket = try xev.TCP.init(addr);

        const c = try self.completion_pool.create();
        try socket.bind(addr);
        try socket.listen(std.os.linux.SOMAXCONN);
        socket.accept(self.loop, c, Server, self, acceptCallback);
    }

    pub fn threadMain(self: *Server) !void {
        try self.loop.run(.until_done);
    }

    fn destroyBuf(self: *Server, buf: []const u8) void {
        self.buffer_pool.destroy(
            @alignCast(
                @as(*[4096]u8, @ptrFromInt(@intFromPtr(buf.ptr))),
            ),
        );
    }

    fn acceptCallback(
        self_: ?*Server,
        l: *xev.Loop,
        c: *xev.Completion,
        r: xev.TCP.AcceptError!xev.TCP,
    ) xev.CallbackAction {
        const self = self_.?;

        // Create our socket
        const socket = self.socket_pool.create() catch unreachable;
        socket.* = r catch unreachable;

        // Start reading -- we can reuse c here because its done.
        const buf = self.buffer_pool.create() catch unreachable;
        socket.read(l, c, .{ .slice = buf }, Server, self, readCallback);

        const w_c = self.completion_pool.create() catch unreachable;

        const datePkt = cs.firstDate.init(self.alloc) catch |err| {
            std.debug.print("can't init firstDate {any}", .{err});
            return .rearm;
        };
        const first_date = bytes.packHeaderBytes(datePkt);

        std.debug.print("Send buf: {any}\n", .{std.fmt.fmtSliceHexUpper(first_date)});

        socket.write(l, w_c, .{ .slice = first_date }, Server, self, writeCallback);

        return .disarm;
    }

    fn readCallback(
        self_: ?*Server,
        loop: *xev.Loop,
        c: *xev.Completion,
        socket: xev.TCP,
        buf: xev.ReadBuffer,
        r: xev.TCP.ReadError!usize,
    ) xev.CallbackAction {
        const self = self_.?;
        const n = r catch |err| switch (err) {
            error.EOF => {
                self.destroyBuf(buf.slice);
                socket.shutdown(loop, c, Server, self, shutdownCallback);
                return .disarm;
            },

            else => {
                self.destroyBuf(buf.slice);
                self.completion_pool.destroy(c);
                std.log.warn("server read unexpected err={}", .{err});
                return .disarm;
            },
        };

        if (n == 2) {
            const w_c = self.completion_pool.create() catch unreachable;
            socket.write(loop, w_c, .{ .slice = buf.slice[0..n] }, Server, self, writeCallback);

            return .rearm;
        }

        std.debug.print("Read buf: {any}\n", .{std.fmt.fmtSliceHexUpper(buf.slice[0..n])});

        const header = bytes.unpackHeaderBytes(buf.slice[0..n]);
        const res = events.react(header.opcode, header.body);

        const w_c = self.completion_pool.create() catch unreachable;

        std.debug.print("Send buf: {any}\n", .{std.fmt.fmtSliceHexUpper(res)});

        socket.write(loop, w_c, .{ .slice = res }, Server, self, writeCallback);

        // Read again
        return .rearm;
    }

    fn writeCallback(
        self_: ?*Server,
        l: *xev.Loop,
        c: *xev.Completion,
        s: xev.TCP,
        buf: xev.WriteBuffer,
        r: xev.TCP.WriteError!usize,
    ) xev.CallbackAction {
        _ = buf; // autofix
        _ = l;
        _ = s;
        _ = r catch unreachable;

        // We do nothing for write, just put back objects into the pool.
        const self = self_.?;
        self.completion_pool.destroy(c);

        return .disarm;
    }

    fn shutdownCallback(
        self_: ?*Server,
        l: *xev.Loop,
        c: *xev.Completion,
        s: xev.TCP,
        r: xev.TCP.ShutdownError!void,
    ) xev.CallbackAction {
        _ = r catch {};

        const self = self_.?;
        s.close(l, c, Server, self, closeCallback);
        return .disarm;
    }

    fn closeCallback(
        self_: ?*Server,
        l: *xev.Loop,
        c: *xev.Completion,
        socket: xev.TCP,
        r: xev.TCP.CloseError!void,
    ) xev.CallbackAction {
        _ = l;
        _ = r catch unreachable;
        _ = socket;

        const self = self_.?;
        self.stop = true;
        self.completion_pool.destroy(c);
        return .disarm;
    }
};
