const std = @import("std");
const print = std.debug.print;
const custom_types = @import("./types.zig");

fn isFieldOptional(comptime T: type, field_index: usize) !bool {
    const fields = @typeInfo(T).Struct.fields;
    return switch (field_index) {
        // This prong is analyzed `fields.len - 1` times with `idx` being a
        // unique comptime-known value each time.
        inline 0...fields.len - 1 => |idx| @typeInfo(fields[idx].type) == .Optional,
        else => return error.IndexOutOfBounds,
    };
}

pub fn unpackBytes(comptime T: type, bytes: []const u8) T {
    var result: T = undefined;
    var modBuf = bytes;
    const fields = std.meta.fields(T);

    inline for (fields, 0..fields.len) |field, index| {
        const isOptional: bool = isFieldOptional(T, index) catch {
            break;
        };

        if (!isOptional) {
            switch (field.type) {
                u8 => {
                    const takeBuf = modBuf[0..1];
                    modBuf = modBuf[1..];
                    @field(result, field.name) = takeBuf[0];
                },
                u16 => {
                    const takeBuf = modBuf[0..2];
                    modBuf = modBuf[2..];
                    const v = std.mem.readInt(u16, takeBuf, std.builtin.Endian.big);
                    @field(result, field.name) = v;
                },
                []const u8 => {
                    const takeBuf = modBuf[0..2];
                    modBuf = modBuf[2..];
                    const lnStr = std.mem.readInt(u16, takeBuf, std.builtin.Endian.big);

                    const str = modBuf[0..lnStr];
                    modBuf = modBuf[lnStr..];
                    @field(result, field.name) = str;
                },
                else => {
                    std.log.info("I don't know", .{});
                },
            }
        }
    }

    return result;
}

pub fn packBytes(comptime T: type, v: T) []const u8 {
    var buf: [4096]u8 = undefined;
    comptime var offset: u16 = 0;
    var finalOffset: u16 = 0;

    inline for (std.meta.fields(T)) |field| {
        switch (field.type) {
            u8 => {
                const v2 = @field(v, field.name);
                std.mem.writeInt(u8, buf[offset .. offset + 1], v2, std.builtin.Endian.big);
                offset = offset + 1;
                finalOffset = finalOffset + 1;
            },
            u16 => {
                const v2 = @field(v, field.name);
                std.mem.writeInt(u16, buf[offset .. offset + 2], v2, std.builtin.Endian.big);
                offset = offset + 1;
                finalOffset = finalOffset + 1;
            },
            []const u8 => {
                const v2 = @field(v, field.name);
                @memcpy(buf[offset .. offset + v2.len], v2[0..v2.len]);
                finalOffset = offset + @as(u8, @intCast(v2.len));
            },
            custom_types.plain_string => {
                const v2 = @field(v, field.name);
                const value = v2.value;
                @memcpy(buf[offset .. offset + value.len], value[0..value.len]);
                finalOffset = offset + @as(u8, @intCast(value.len));
            },
            ?u16 => {
                const v2 = @field(v, field.name);
                std.mem.writeInt(u16, buf[offset .. offset + 2], v2.?, std.builtin.Endian.big);
                offset = offset + 2;
                finalOffset = finalOffset + 2;
            },
            else => {
                std.log.info("I don't know type {any}", .{field});
            },
        }
    }

    return buf[0..finalOffset];
}

pub fn packHeaderBytes(comptime T: type, v: T) []u8 {
    const buf = packBytes(T, v);
    const len = buf.len + 6;

    var aa = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    var lenBuf = aa.allocator().alloc(u8, 4096) catch unreachable;

    std.mem.writeInt(u16, lenBuf[0..2], @as(u16, @intCast(len)), std.builtin.Endian.big);
    std.mem.writeInt(u32, lenBuf[2..6], 0x80, std.builtin.Endian.little);

    std.debug.print("ssss {any}\n", .{buf});
    @memcpy(lenBuf[6..len], buf[0..]);

    std.log.info("{x:0>2}", .{std.fmt.fmtSliceHexUpper(lenBuf[0..len])});

    return lenBuf[0..len];
}

const header = struct {
    ln: u16,
    id: u32,
    opcode: u16,
    body: []const u8,
};

pub fn unpackHeaderBytes(buf: []const u8) header {
    const h = header{};

    h.ln = std.mem.readInt(u16, buf, std.builtin.Endian.big);
    h.id = std.mem.readInt(u32, buf, std.builtin.Endian.little);
    h.opcode = std.mem.readInt(u16, buf, std.builtin.Endian.big);
    h.body = buf[8..h.ln];

    return h;
}
