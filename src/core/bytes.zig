const std = @import("std");
const print = std.debug.print;
const core = @import("import.zig");
const character_screen = @import("character_screen");
const Allocator = std.mem.Allocator;

const default_buf_size = 64959;

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

pub fn unpackBytes(comptime T: type, bytes: []const u8, comptime endian: std.builtin.Endian) unpack_return_func(T) {
    var result: T = undefined;
    var modBuf = bytes;
    const fields = std.meta.fields(T);

    inline for (fields, 0..fields.len) |field, index| {
        const isOptional: bool = isFieldOptional(T, index) catch {
            break;
        };

        if (!isOptional) {
            //std.debug.print("type parse: {any}\n", .{field.type});

            switch (field.type) {
                u8 => {
                    const takeBuf = modBuf[0..1];
                    modBuf = modBuf[1..];
                    @field(result, field.name) = takeBuf[0];
                },
                u16 => {
                    const takeBuf = modBuf[0..2];
                    modBuf = modBuf[2..];
                    const v = std.mem.readInt(u16, takeBuf, endian);
                    @field(result, field.name) = v;
                },
                bool => {
                    const takeBuf = modBuf[0..1];
                    modBuf = modBuf[1..];

                    if (takeBuf[0] == 1) {
                        @field(result, field.name) = true;
                    } else {
                        @field(result, field.name) = false;
                    }
                },
                []const u8 => {
                    const takeBuf = modBuf[0..2];
                    modBuf = modBuf[2..];
                    const lnStr = std.mem.readInt(u16, takeBuf, endian);

                    const str = modBuf[0..lnStr];
                    modBuf = modBuf[lnStr..];
                    @field(result, field.name) = str;
                },
                character_screen.structs.Look => {
                    modBuf = modBuf[2..];

                    const unpack_struct = unpackBytes(field.type, modBuf, std.builtin.Endian.little);

                    @field(result, field.name) = unpack_struct.return_type;
                    modBuf = unpack_struct.buf;
                },
                [10]character_screen.structs.ItemGrid => {
                    const typeOfArray = std.meta.Elem(field.type);

                    var itemGrids: [10]character_screen.structs.ItemGrid = undefined;
                    for (0..10) |x| {
                        const unpack_struct = unpackBytes(typeOfArray, modBuf, endian);

                        itemGrids[x] = unpack_struct.return_type;
                        modBuf = unpack_struct.buf;
                    }

                    @field(result, field.name) = itemGrids;
                },
                [2]u16 => {
                    var u16s: [2]u16 = undefined;
                    for (0..2) |x| {
                        const takeBuf = modBuf[0..2];
                        modBuf = modBuf[2..];
                        const v = std.mem.readInt(u16, takeBuf, endian);

                        u16s[x] = v;
                    }

                    @field(result, field.name) = u16s;
                },
                [2]u32 => {
                    var u32s: [2]u32 = undefined;
                    for (0..2) |x| {
                        const takeBuf = modBuf[0..4];
                        modBuf = modBuf[4..];
                        const v = std.mem.readInt(u32, takeBuf, endian);

                        u32s[x] = v;
                    }

                    @field(result, field.name) = u32s;
                },
                [5]character_screen.structs.InstAttr => {
                    const typeOfArray = std.meta.Elem(field.type);

                    var instAttrs: [5]character_screen.structs.InstAttr = undefined;
                    for (0..5) |x| {
                        const unpack_struct = unpackBytes(typeOfArray, modBuf, endian);

                        instAttrs[x] = unpack_struct.return_type;
                        modBuf = unpack_struct.buf;
                    }

                    @field(result, field.name) = instAttrs;
                },
                [40]character_screen.structs.ItemAttr => {
                    const typeOfArray = std.meta.Elem(field.type);

                    var itemAttrs: [40]character_screen.structs.ItemAttr = undefined;
                    for (0..40) |x| {
                        const unpack_struct = unpackBytes(typeOfArray, modBuf, endian);

                        itemAttrs[x] = unpack_struct.return_type;
                        modBuf = unpack_struct.buf;
                    }

                    @field(result, field.name) = itemAttrs;
                },
                else => {
                    std.log.info("I don't know", .{});
                },
            }
        }
    }

    return unpack_return_func(T).init(result, modBuf);
}

fn shouldSkipField(comptime T: type, comptime fieldName: []const u8) bool {
    if (std.meta.hasMethod(T, fieldName)) {
        // Assuming `filter` could be checked at compile-time; otherwise, adjust the design
        // Dummy usage, you should replace this logic to correctly invoke the method or handle type
        return !T.filter();
    }

    return false;
}

pub fn packStructTypes(allocator: Allocator, v: anytype, field: std.builtin.Type.StructField, comptime endian: std.builtin.Endian) []u8 {
    _ = allocator; // autofix
    var buf: [default_buf_size]u8 = undefined;
    var finalOffset: u16 = 0;

    switch (field.type) {
        u8 => {
            var buf2: [1]u8 = undefined;
            const v2 = @field(v, field.name);
            std.mem.writeInt(u8, &buf2, v2, endian);
            std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + 1], buf2[0..]);
            finalOffset = finalOffset + 1;
        },
        bool => {
            var buf2: [1]u8 = undefined;
            const v2 = @field(v, field.name);

            if (v2) {
                std.mem.writeInt(u8, &buf2, 1, endian);
            } else {
                std.mem.writeInt(u8, &buf2, 0, endian);
            }

            std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + 1], buf2[0..]);
            finalOffset = finalOffset + 1;
        },
        [2]u16,
        []u16,
        => {
            const vs = @field(v, field.name);

            for (vs) |internal_v| {
                var buf2: [2]u8 = undefined;
                std.mem.writeInt(u16, &buf2, internal_v, endian);
                std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + 2], buf2[0..]);
                finalOffset = finalOffset + 2;
            }
        },
        [2]u32 => {
            const vs = @field(v, field.name);

            for (vs) |internal_v| {
                var buf2: [4]u8 = undefined;
                std.mem.writeInt(u32, &buf2, internal_v, endian);
                std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + 4], buf2[0..]);
                finalOffset = finalOffset + 4;
            }
        },
        u16 => {
            const v2 = @field(v, field.name);
            var buf2: [2]u8 = undefined;
            std.mem.writeInt(u16, &buf2, v2, endian);
            std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + 2], buf2[0..]);
            finalOffset = finalOffset + 2;
        },
        u32 => {
            const v2 = @field(v, field.name);
            var buf2: [4]u8 = undefined;
            std.mem.writeInt(u32, &buf2, v2, endian);
            std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + 4], buf2[0..]);
            finalOffset = finalOffset + 4;
        },
        []const u8 => {
            const v2 = @field(v, field.name);

            var buf2: [2]u8 = undefined;
            std.mem.writeInt(u16, &buf2, @as(u16, @intCast(v2.len + 1)), endian);
            std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + 2], buf2[0..]);
            finalOffset = finalOffset + 2;

            std.mem.copyForwards(u8, buf[finalOffset..], v2[0..]);
            finalOffset = finalOffset + @as(u16, @intCast(v2.len));

            std.mem.copyForwards(u8, buf[finalOffset..], "\x00");
            finalOffset = finalOffset + 1;
        },
        core.types.plain_string => {
            const v2 = @field(v, field.name);
            const value = v2.value;
            @memcpy(buf[finalOffset .. finalOffset + value.len], value[0..value.len]);
            finalOffset = finalOffset + @as(u8, @intCast(value.len));
        },
        core.types.bytes => {
            const v2 = @field(v, field.name).value;

            var buf2: [2]u8 = undefined;
            std.mem.writeInt(u16, &buf2, @as(u16, @intCast(v2.len)), endian);
            std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + 2], buf2[0..]);
            finalOffset = finalOffset + 2;

            std.mem.copyForwards(u8, buf[finalOffset..], v2[0..]);
            finalOffset = finalOffset + @as(u16, @intCast(v2.len));
        },
        ?u16 => {
            const v2 = @field(v, field.name).?;
            var buf2: [2]u8 = undefined;
            std.mem.writeInt(u16, &buf2, v2, endian);
            std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + 2], buf2[0..]);
            finalOffset = finalOffset + 2;
        },
        else => {
            std.debug.print("not found type for handle field.type: {any}\n", .{field.type});
        },
    }

    return buf[0..finalOffset];
}

pub fn packArrayAndStructTypes(allocator: Allocator, v: anytype, field: std.builtin.Type.StructField, i: u16, comptime endian: std.builtin.Endian) []u8 {
    var buf: [default_buf_size]u8 = undefined;
    var finalOffset: u16 = 0;

    const fieldTypeInfo = @typeInfo(field.type);

    switch (fieldTypeInfo) {
        .Array => {
            const element_type = fieldTypeInfo.Array.child;
            if (@typeInfo(element_type) == .Struct) {
                const items = @field(v, field.name);

                for (items) |ia| {
                    const pack_bytes = packBytes(allocator, ia, i + 1, endian);
                    std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + pack_bytes.len], pack_bytes);
                    finalOffset = finalOffset + @as(u16, @intCast(pack_bytes.len));
                }
            }
        },
        .Struct => {
            if (field.type == character_screen.structs.Look) {
                const pack_bytes = packBytes(allocator, @field(v, field.name), i + 1, endian);

                var buf2: [2]u8 = undefined;
                std.mem.writeInt(u16, &buf2, @as(u16, @intCast(pack_bytes.len)), std.builtin.Endian.little);
                std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + 2], buf2[0..]);
                finalOffset = finalOffset + 2;

                std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + pack_bytes.len], pack_bytes);
                finalOffset = finalOffset + @as(u16, @intCast(pack_bytes.len));
            } else {
                const pack_bytes = packBytes(allocator, @field(v, field.name), i + 1, endian);
                std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + pack_bytes.len], pack_bytes);
                finalOffset = finalOffset + @as(u16, @intCast(pack_bytes.len));
            }
        },
        else => {
            const pack_bytes = packStructTypes(allocator, v, field, endian);
            std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + pack_bytes.len], pack_bytes);
            finalOffset = finalOffset + @as(u16, @intCast(pack_bytes.len));
        },
    }

    return buf[0..finalOffset];
}

pub fn packBytes(allocator: Allocator, v: anytype, i: u16, comptime endian: std.builtin.Endian) []u8 {
    var buf: [default_buf_size]u8 = undefined;
    var finalOffset: u16 = 0;

    inline for (std.meta.fields(@TypeOf(v))) |field| {
        if (std.meta.hasMethod(@TypeOf(v), "filter")) {
            if (!v.filter()) {
                const pack_bytes = packArrayAndStructTypes(allocator, v, field, i, endian);
                std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + pack_bytes.len], pack_bytes);
                finalOffset = finalOffset + @as(u16, @intCast(pack_bytes.len));
            }
        } else {
            const pack_bytes = packArrayAndStructTypes(allocator, v, field, i, endian);
            std.mem.copyForwards(u8, buf[finalOffset .. finalOffset + pack_bytes.len], pack_bytes);
            finalOffset = finalOffset + @as(u16, @intCast(pack_bytes.len));
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
    var buf = packBytes(allocator, v, 0, std.builtin.Endian.big);
    var lenBuf: [6]u8 = std.mem.zeroes([6]u8);
    const len = buf.len;

    std.log.info("success pack bytes: {any}", .{buf.len});

    std.mem.writeInt(u16, lenBuf[0..2], @as(u16, @intCast(len)), std.builtin.Endian.big);
    std.mem.writeInt(u32, lenBuf[2..6], 0x80, std.builtin.Endian.little);
    std.mem.copyBackwards(u8, buf[0..6], lenBuf[0..6]);

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
