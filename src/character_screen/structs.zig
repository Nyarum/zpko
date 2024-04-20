const std = @import("std");
const core = @import("core");

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

pub const CharactersChoice = struct {
    opcode: u16 = 931,
    error_code: u16 = 0,
    key: core.types.bytes = core.types.bytes{ .value = &[_]u8{ 0x7C, 0x35, 0x09, 0x19, 0xB2, 0x50, 0xD3, 0x49 } },
    character_len: u8 = 0,
    characters: []Character = undefined,
    pincode: u8 = 1,
    encryption: u32 = 0,
    dw_flag: u32 = 12820,
};

pub const createCharacter = struct {
    name: []const u8,
    map: []const u8,
    look: Look,
};

pub const createCharacterResp = struct {
    opcode: u16 = 935,
    error_code: u16 = 0,
};

pub const CharacterBoat = struct {
    characterBase: CharacterBase,
    characterAttribute: CharacterAttribute,
    characterKitbag: CharacterKitbag,
    characterSkillState: CharacterSkillState,
};

pub const Shortcut = struct {
    type: u8,
    gridId: u16,
};

pub const CharacterShortcut = struct {
    shortcuts: [core.enums.Constants.shortCutNum]Shortcut,
};

pub const KitbagItem = struct {
    gridId: u16,
    id: u16,
    num: u16,
    endure: [2]u16,
    energy: [2]u16,
    forgeLevel: u8,
    isValid: bool,
    itemDbInstId: u32,
    itemDbForge: u32,
    isParams: bool,
    instAttrs: [5]InstAttr,
};

pub const CharacterKitbag = struct {
    type: u8,
    keybagNum: u16,
    items: [40]KitbagItem,
};

pub const Attribute = struct {
    id: u8,
    value: u32,
};

pub const CharacterAttribute = struct {
    type: u8,
    num: u16,
    attributes: [40]Attribute,
};

pub const SkillState = struct {
    id: u8,
    level: u8,
};

pub const CharacterSkillState = struct {
    statesLen: u8,
    states: [40]SkillState,
};

pub const CharacterSkill = struct {
    id: u16,
    state: u8,
    level: u8,
    useSp: u16,
    useEndure: u16,
    useEnergy: u16,
    resumeTime: u32,
    rangeType: u16,
    params: []u16, // Optional based on use?

};

pub const CharacterSkillBag = struct {
    skillId: u16,
    type: u8,
    skillNum: u16,
    skills: [40]CharacterSkill,
};

pub const CharacterAppendLook = struct {
    lookId: u16,
    isValid: u8,
};

pub const CharacterPK = struct {
    pkCtrl: u8,
};

pub const CharacterLookBoat = struct {
    posId: u16,
    boatId: u16,
    header: u16,
    body: u16,
    engine: u16,
    cannon: u16,
    equipment: u16,
};

pub const CharacterLookItemSync = struct {
    endure: u16,
    energy: u16,
    isValid: u8,
};

pub const CharacterLookItemShow = struct {
    num: u16,
    endure: [2]u16,
    energy: [2]u16,
    forgeLevel: u8,
    isValid: u8,
};

pub const CharacterLookItem = struct {
    id: u16,
    itemSync: CharacterLookItemSync,
    itemShow: CharacterLookItemShow,
    isDbParams: u8,
    dbParams: [2]u32,
    isInstAttrs: u8,
    instAttrs: [5]InstAttr,

    pub fn filter(item: @This()) bool {
        if (item.id == 0) {
            return true;
        }

        return false;
    }
};

pub const CharacterLookHuman = struct {
    hairId: u16,
    itemGrid: [10]CharacterLookItem,
};

pub const CharacterLook = struct {
    synType: u8,
    typeId: u16,
    isBoat: u8,
    lookBoat: CharacterLookBoat,
    lookHuman: CharacterLookHuman,
};

pub const EntityEvent = struct {
    entityId: u32,
    entityType: u8,
    eventId: u16,
    eventName: []const u8,
};

pub const CharacterSide = struct {
    sideId: u8,
};

pub const Position = struct {
    x: u32,
    y: u32,
    radius: u32,
};

pub const CharacterBase = struct {
    chaId: u32,
    worldId: u32,
    commId: u32,
    commName: []const u8,
    gmLvl: u8,
    handle: u32,
    ctrlType: u8,
    name: []const u8,
    mottoName: []const u8,
    icon: u16,
    guildId: u32,
    guildName: []const u8,
    guildMotto: []const u8,
    stallName: []const u8,
    state: u16,
    position: Position,
    angle: u16,
    teamLeaderId: u32,
    side: CharacterSide,
    entityEvent: EntityEvent,
    look: CharacterLook,
    pkCtrl: CharacterPK,
    lookAppend: [core.enums.Constants.espeKbgridNum]CharacterAppendLook,
};

pub const EnterGame = struct {
    opcode: u16 = 516,
    enterRet: u16,
    autoLock: u8,
    kitbagLock: u8,
    enterType: u8,
    isNewChar: u8,
    mapName: []const u8,
    canTeam: u8,
    characterBase: CharacterBase,
    characterSkillBag: CharacterSkillBag,
    characterSkillState: CharacterSkillState,
    characterAttribute: CharacterAttribute,
    characterKitbag: CharacterKitbag,
    characterShortcut: CharacterShortcut,
    boatLen: u8,
    characterBoats: [3]CharacterBoat,
    chaMainId: u32,
};

pub const enterGameRequest = struct {
    characterName: []const u8,
};
