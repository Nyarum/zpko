const std = @import("std");
const print = std.debug.print;
const custom_types = @import("types.zig");
const cs = @import("character_screen.zig");
const sub_packets = @import("sub_packets.zig");
const Allocator = std.mem.Allocator;

const default_buf_size = 8192;

fn isFieldOptional(comptime T: type, field_index: usize) !bool {
    const fields = @typeInfo(T).Struct.fields;
    return switch (field_index) {
        // This prong is analyzed `fields.len - 1` times with `idx` being a
        // unique comptime-known value each time.
        inline 0...fields.len - 1 => |idx| @typeInfo(fields[idx].type) == .Optional,
        else => return error.IndexOutOfBounds,
    };
}

fn unpack_return_func(comptime T: type) type {
    return struct {
        return_type: T,
        buf: []const u8,

        pub fn init(internal_return_type: T, internal_buf: []const u8) unpack_return_func(T) {
            return unpack_return_func(T){
                .return_type = internal_return_type,
                .buf = internal_buf,
            };
        }
    };
}

pub fn unpackBytes(comptime T: type, bytes: []const u8) unpack_return_func(T) {
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
                sub_packets.Look => {
                    const unpack_struct = unpackBytes(field.type, modBuf);

                    @field(result, field.name) = unpack_struct.return_type;
                    modBuf = unpack_struct.buf;
                },
                else => {
                    std.log.info("I don't know", .{});
                },
            }
        }
    }

    return unpack_return_func(T).init(result, modBuf);
}

pub fn packBytes(allocator: Allocator, v: anytype, i: u16) []u8 {
    var buf: [default_buf_size]u8 = undefined;
    var finalOffset: u16 = 0;

    inline for (std.meta.fields(@TypeOf(v))) |field| {
        //std.debug.print("field: {s} and it type {any}\n", .{ field.name, field.type });

        switch (field.type) {
            u8 => {
                var buf2: [1]u8 = undefined;
                const v2 = @field(v, field.name);
                std.mem.writeInt(u8, &buf2, v2, std.builtin.Endian.big);
                std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + 1], buf2[0..]);
                finalOffset = finalOffset + 1;
            },
            bool => {
                var buf2: [1]u8 = undefined;
                const v2 = @field(v, field.name);

                if (v2) {
                    std.mem.writeInt(u8, &buf2, 1, std.builtin.Endian.big);
                } else {
                    std.mem.writeInt(u8, &buf2, 0, std.builtin.Endian.big);
                }

                std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + 1], buf2[0..]);
                finalOffset = finalOffset + 1;
            },
            [2]u16 => {
                const vs = @field(v, field.name);

                for (vs) |internal_v| {
                    var buf2: [2]u8 = undefined;
                    std.mem.writeInt(u16, &buf2, internal_v, std.builtin.Endian.big);
                    std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + 2], buf2[0..]);
                    finalOffset = finalOffset + 2;
                }
            },
            [2]u32 => {
                const vs = @field(v, field.name);

                for (vs) |internal_v| {
                    var buf2: [4]u8 = undefined;
                    std.mem.writeInt(u32, &buf2, internal_v, std.builtin.Endian.big);
                    std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + 4], buf2[0..]);
                    finalOffset = finalOffset + 4;
                }
            },
            u16 => {
                const v2 = @field(v, field.name);
                var buf2: [2]u8 = undefined;
                std.mem.writeInt(u16, &buf2, v2, std.builtin.Endian.big);
                std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + 2], buf2[0..]);
                finalOffset = finalOffset + 2;
            },
            u32 => {
                const v2 = @field(v, field.name);
                var buf2: [4]u8 = undefined;
                std.mem.writeInt(u32, &buf2, v2, std.builtin.Endian.big);
                std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + 4], buf2[0..]);
                finalOffset = finalOffset + 4;
            },
            []const u8 => {
                const v2 = @field(v, field.name);

                var buf2: [2]u8 = undefined;
                std.mem.writeInt(u16, &buf2, @as(u16, @intCast(v2.len + 1)), std.builtin.Endian.big);
                std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + 2], buf2[0..]);
                finalOffset = finalOffset + 2;

                std.mem.copyForwards(u8, buf[finalOffset..], v2[0..]);
                finalOffset = finalOffset + @as(u16, @intCast(v2.len));

                std.mem.copyForwards(u8, buf[finalOffset..], "\x00");
                finalOffset = finalOffset + 1;
            },
            custom_types.plain_string => {
                const v2 = @field(v, field.name);
                const value = v2.value;
                @memcpy(buf[finalOffset .. finalOffset + value.len], value[0..value.len]);
                finalOffset = finalOffset + @as(u8, @intCast(value.len));
            },
            custom_types.bytes => {
                const v2 = @field(v, field.name).value;

                var buf2: [2]u8 = undefined;
                std.mem.writeInt(u16, &buf2, @as(u16, @intCast(v2.len)), std.builtin.Endian.big);
                std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + 2], buf2[0..]);
                finalOffset = finalOffset + 2;

                std.mem.copyForwards(u8, buf[finalOffset..], v2[0..]);
                finalOffset = finalOffset + @as(u16, @intCast(v2.len));
            },
            ?u16 => {
                const v2 = @field(v, field.name).?;
                var buf2: [2]u8 = undefined;
                std.mem.writeInt(u16, &buf2, v2, std.builtin.Endian.big);
                std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + 2], buf2[0..]);
                finalOffset = finalOffset + 2;
            },
            []const sub_packets.Character => {
                const c_field = @field(v, field.name);

                for (c_field) |*char| {
                    const pack_bytes = packBytes(allocator, char.*, i + 1);
                    std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + pack_bytes.len], pack_bytes);
                    finalOffset = finalOffset + @as(u16, @intCast(pack_bytes.len));
                }
            },
            sub_packets.Look => {
                const pack_bytes = packBytes(allocator, @field(v, field.name), i + 1);

                var buf2: [2]u8 = undefined;
                std.mem.writeInt(u16, &buf2, @as(u16, @intCast(pack_bytes.len)), std.builtin.Endian.big);
                std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + 2], buf2[0..]);
                finalOffset = finalOffset + 2;

                std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + pack_bytes.len], pack_bytes);
                finalOffset = finalOffset + @as(u16, @intCast(pack_bytes.len));
            },
            [5]sub_packets.InstAttr => {
                const inst_attrs = @field(v, field.name);

                for (inst_attrs) |ia| {
                    const pack_bytes = packBytes(allocator, ia, i + 1);
                    std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + pack_bytes.len], pack_bytes);
                    finalOffset = finalOffset + @as(u16, @intCast(pack_bytes.len));
                }
            },
            [40]sub_packets.ItemAttr => {
                const item_attrs = @field(v, field.name);

                for (item_attrs) |ia| {
                    const pack_bytes = packBytes(allocator, ia, i + 1);
                    std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + pack_bytes.len], pack_bytes);
                    finalOffset = finalOffset + @as(u16, @intCast(pack_bytes.len));

                    //std.debug.print("item attr size {any}\n", .{pack_bytes.len});
                }
            },
            [10]sub_packets.ItemGrid => {
                const item_grids = @field(v, field.name);

                for (item_grids) |id| {
                    const pack_bytes = packBytes(allocator, id, i + 1);
                    std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + pack_bytes.len], pack_bytes);
                    finalOffset = finalOffset + @as(u16, @intCast(pack_bytes.len));
                }
            },
            else => {
                std.debug.print("not found handle for the type {any}\n", .{@typeInfo(field.type)});
            },
        }
    }

    if (i == 0) {
        const new_array = allocator.alloc(u8, finalOffset + 6) catch unreachable;
        std.mem.copyForwards(u8, new_array[6..], buf[0..finalOffset]);
        return new_array;
    }

    return buf[0..finalOffset];
}

pub fn packHeaderBytes(allocator: Allocator, v: anytype) []u8 {
    var buf = packBytes(allocator, v, 0);
    var lenBuf: [6]u8 = std.mem.zeroes([6]u8);
    const len = buf.len;

    std.debug.print("before: {x:0>2}", .{std.fmt.fmtSliceHexUpper(buf)});

    std.mem.writeInt(u16, lenBuf[0..2], @as(u16, @intCast(len)), std.builtin.Endian.big);
    std.mem.writeInt(u32, lenBuf[2..6], 0x80, std.builtin.Endian.little);
    std.mem.copyBackwards(u8, buf[0..6], lenBuf[0..6]);

    std.debug.print("after: {x:0>2}", .{std.fmt.fmtSliceHexUpper(buf)});

    return buf;
}

const header = struct {
    ln: u16,
    id: u32,
    opcode: u16,
    body: []const u8,
};

pub fn unpackHeaderBytes(buf: []const u8) header {
    var h: header = undefined;

    h.ln = std.mem.readInt(u16, buf[0..2], std.builtin.Endian.big);
    h.id = std.mem.readInt(u32, buf[2..6], std.builtin.Endian.little);
    h.opcode = std.mem.readInt(u16, buf[6..8], std.builtin.Endian.big);

    h.body = buf[8..h.ln];

    return h;
}
