pub const InstAttr = struct {
    id: u16 = 0,
    value: u16 = 0,
};

pub const ItemAttr = struct {
    attr: u16 = 0,
    is_init: bool = false,
};

pub const ItemGrid = struct {
    id: u16 = 0,
    num: u16 = 0,
    endure: [2]u16 = [2]u16{ 0, 0 },
    energy: [2]u16 = [2]u16{ 0, 0 },
    forge_lv: u8 = 0,
    db_params: [2]u32 = [2]u32{ 0, 0 },
    inst_attrs: [5]InstAttr = undefined,
    item_attrs: [40]ItemAttr = undefined,
    is_change: bool = false,
};

pub const Look = struct {
    ver: u16,
    type_id: u16,
    item_grids: [10]ItemGrid = undefined,
    hair: u16,
};

pub const Character = struct {
    active: bool = false,
    name: []const u8,
    job: []const u8,
    level: u16,
    look: Look,
};
