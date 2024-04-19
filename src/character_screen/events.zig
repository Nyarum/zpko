const cs = @import("import.zig");
const core = @import("core");
const std = @import("std");
const Allocator = std.mem.Allocator;

storage: *core.storage,
allocator: Allocator,

pub fn reactCreateCharacter(self: *@This(), login: []const u8, data: cs.structs.createCharacter) !cs.structs.createCharacterResp {
    const name = try self.allocator.dupe(u8, data.name);
    const map = try self.allocator.dupe(u8, data.map);

    try self.storage.saveCharacter(core.storage.UserLogin{ .value = login }, core.storage.Character{
        .name = name,
        .map = map,
        .look = data.look,
        .active = true,
        .job = "Newbie",
        .level = 1,
    });

    return cs.structs.createCharacterResp{};
}

pub fn reactEnterWorld(self: *@This(), login: []const u8, data: cs.structs.enterGameRequest) !cs.structs.EnterGame {
    const user = self.storage.getUser(core.storage.UserLogin{
        .value = login,
    });

    if (user == null) {
        return error.UserNotFound;
    }

    var character: core.storage.Character = undefined;

    for (user.?.characters.?.items) |char| {
        if (std.mem.eql(u8, char.name, data.characterName)) {
            character = char;
        }
    }

    var characterLookItems: [10]cs.structs.CharacterLookItem = undefined;

    for (0..10) |i| {
        var instAttrs: [5]cs.structs.InstAttr = undefined;

        for (0..5) |index| {
            instAttrs[index] = cs.structs.InstAttr{
                .id = 0,
                .value = 0,
            };
        }

        characterLookItems[i] = cs.structs.CharacterLookItem{
            .dbParams = [2]u32{ 0, 0 },
            .id = 0,
            .instAttrs = instAttrs,
            .isDbParams = 0,
            .isInstAttrs = 0,
            .itemShow = cs.structs.CharacterLookItemShow{
                .endure = [2]u16{ 0, 0 },
                .energy = [2]u16{ 0, 0 },
                .forgeLevel = 0,
                .isValid = 0,
                .num = 0,
            },
            .itemSync = cs.structs.CharacterLookItemSync{
                .endure = 0,
                .energy = 0,
                .isValid = 0,
            },
        };
    }

    var characterAppendLook: [core.enums.Constants.espeKbgridNum]cs.structs.CharacterAppendLook = undefined;

    for (0..core.enums.Constants.espeKbgridNum) |i| {
        characterAppendLook[i] = cs.structs.CharacterAppendLook{
            .isValid = 0,
            .lookId = 0,
        };
    }

    var shortcuts: [core.enums.Constants.shortCutNum]cs.structs.Shortcut = undefined;

    for (0..core.enums.Constants.shortCutNum) |i| {
        shortcuts[i] = cs.structs.Shortcut{
            .gridId = 0,
            .type = 0,
        };
    }

    return cs.structs.EnterGame{
        .enterRet = 0,
        .autoLock = 0,
        .kitbagLock = 0,
        .enterType = 1,
        .isNewChar = 1,
        .mapName = character.map,
        .canTeam = 1,
        .characterBase = cs.structs.CharacterBase{
            .chaId = 0,
            .worldId = 0,
            .commId = 0,
            .commName = "test",
            .gmLvl = 0,
            .handle = 0,
            .ctrlType = 0,
            .name = character.name,
            .mottoName = "motto",
            .icon = 0,
            .guildId = 0,
            .guildName = "",
            .guildMotto = "",
            .stallName = "",
            .state = 0,
            .position = cs.structs.Position{
                .radius = 0,
                .x = 0,
                .y = 0,
            },
            .angle = 0,
            .teamLeaderId = 0,
            .side = cs.structs.CharacterSide{
                .sideId = 0,
            },
            .entityEvent = cs.structs.EntityEvent{
                .entityId = 0,
                .entityType = 0,
                .eventId = 0,
                .eventName = "",
            },
            .look = cs.structs.CharacterLook{ .isBoat = 0, .typeId = 0, .synType = 0, .lookHuman = cs.structs.CharacterLookHuman{
                .hairId = 0,
                .itemGrid = characterLookItems,
            }, .lookBoat = cs.structs.CharacterLookBoat{
                .boatId = 0,
                .body = 0,
                .cannon = 0,
                .engine = 0,
                .equipment = 0,
                .header = 0,
                .posId = 0,
            } },
            .pkCtrl = cs.structs.CharacterPK{
                .pkCtrl = 0,
            },
            .lookAppend = characterAppendLook,
        },
        .characterSkillBag = cs.structs.CharacterSkillBag{
            .skillId = 0,
            .skillNum = 0,
            .skills = &[_]cs.structs.CharacterSkill{},
            .type = 0,
        },
        .characterSkillState = cs.structs.CharacterSkillState{
            .states = &[_]cs.structs.SkillState{},
            .statesLen = 0,
        },
        .characterAttribute = cs.structs.CharacterAttribute{
            .attributes = &[_]cs.structs.Attribute{},
            .num = 0,
            .type = 0,
        },
        .characterKitbag = cs.structs.CharacterKitbag{
            .items = &[_]cs.structs.KitbagItem{},
            .keybagNum = 0,
            .type = 0,
        },
        .characterShortcut = cs.structs.CharacterShortcut{
            .shortcuts = shortcuts,
        },
        .boatLen = 0,
        .characterBoats = &[_]cs.structs.CharacterBoat{},
        .chaMainId = 0,
    };
}
