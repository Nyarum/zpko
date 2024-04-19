pub const SynLook = enum {
    switching,
    changing,
};

pub const SyncKitBag = enum {
    init,
    equip,
    unfix,
    pick,
    throw,
    switchTo,
    trade,
    fromNpc,
    toNpc,
    system,
    forges,
    forgef,
    bank,
    attribute,
};

pub const Constants = struct {
    pub const maxFastRow: u32 = 3;
    pub const maxFastCol: u32 = 12;
    pub const shortCutNum: u32 = maxFastRow * maxFastCol;
    pub const espeKbgridNum: u8 = 4;
};

pub const Actions = enum {
    none,
    move,
    skill,
    skillSource,
    skillTarget,
    look,
    kitBag,
    skillBag,
    itemPick,
    itemThrow,
    itemUnfix,
    itemUse,
    itemPos,
    itemDelete,
    itemInfo,
};

pub const MiscState = enum { on, arrive, block, cancel, inRange, noTarget, cantMove };
pub const Pose = enum { stand, lean, seat };

pub const EntitySeen = enum { seenNew, seenSwitch };

pub const ErrorMailbox = enum {
    default,
    netError,
    notSelectCha,
    notPlay,
    notArrive,
    tooManyPLY,
    notLogin,
    verError,
    enterError,
    enterPos,
    banUser,
    pBanUser,
};
