const std = @import("std");
const core = @import("core");
const character_screen = @import("character_screen");

test "pack with header for characters choice" {
    const allocator = std.heap.page_allocator;
    _ = allocator; // autofix
    const characters_choice = character_screen.structs.CharactersChoice{};
    _ = characters_choice; // autofix
    //const auth_enter_pkt = core.bytes.packHeaderBytes(allocator, characters_choice);

    //std.debug.print("characters choice: {X:1}\n", .{std.fmt.fmtSliceHexUpper(auth_enter_pkt)});
}

test "pack with header for characters choice with one character" {
    const allocator = std.heap.page_allocator;

    const character = character_screen.structs.Character{
        .job = "test",
        .level = 0,
        .active = true,
        .name = "test",
        .look = .{
            .ver = 0,
            .type_id = 0,
            .hair = 0,
            .item_grids = undefined,
        },
    };

    var characters = std.ArrayList(character_screen.structs.Character).init(allocator);
    try characters.append(character);

    const characters_choice = character_screen.structs.CharactersChoice{ .characters = characters.items, .character_len = 1 };
    _ = characters_choice; // autofix

    //const auth_enter_pkt = core.bytes.packHeaderBytes(allocator, characters_choice);

    //std.debug.print("characters choice with one character: {X:1}\n", .{std.fmt.fmtSliceHexUpper(auth_enter_pkt)});
}

test "pack with header for enter world" {
    const allocator = std.heap.page_allocator;

    const character = core.storage.Character{
        .job = "test",
        .level = 0,
        .active = true,
        .name = "test",
        .map = "test",
        .look = .{
            .ver = 0,
            .type_id = 0,
            .hair = 0,
            .item_grids = undefined,
        },
    };

    var characters = std.ArrayList(core.storage.Character).init(allocator);
    try characters.append(character);

    var characterLookItems: [10]character_screen.structs.CharacterLookItem = undefined;

    for (0..10) |i| {
        var instAttrs: [5]character_screen.structs.InstAttr = undefined;

        for (0..5) |index| {
            instAttrs[index] = character_screen.structs.InstAttr{
                .id = 0,
                .value = 0,
            };
        }

        characterLookItems[i] = character_screen.structs.CharacterLookItem{
            .dbParams = [2]u32{ 0, 0 },
            .id = 0,
            .instAttrs = instAttrs,
            .isDbParams = 0,
            .isInstAttrs = 0,
            .itemShow = character_screen.structs.CharacterLookItemShow{
                .endure = [2]u16{ 0, 0 },
                .energy = [2]u16{ 0, 0 },
                .forgeLevel = 0,
                .isValid = 0,
                .num = 0,
            },
            .itemSync = character_screen.structs.CharacterLookItemSync{
                .endure = 0,
                .energy = 0,
                .isValid = 0,
            },
        };
    }

    var characterAppendLook: [core.enums.Constants.espeKbgridNum]character_screen.structs.CharacterAppendLook = undefined;

    for (0..core.enums.Constants.espeKbgridNum) |i| {
        characterAppendLook[i] = character_screen.structs.CharacterAppendLook{
            .isValid = 0,
            .lookId = 0,
        };
    }

    var shortcuts: [core.enums.Constants.shortCutNum]character_screen.structs.Shortcut = undefined;

    for (0..core.enums.Constants.shortCutNum) |i| {
        shortcuts[i] = character_screen.structs.Shortcut{
            .gridId = 0,
            .type = 0,
        };
    }

    var skills: [40]character_screen.structs.CharacterSkill = undefined;

    for (0..40) |i| {
        skills[i] = character_screen.structs.CharacterSkill{
            .id = 0,
            .level = 0,
            .params = &[_]u16{},
            .rangeType = 0,
            .resumeTime = 0,
            .state = 0,
            .useEndure = 0,
            .useEnergy = 0,
            .useSp = 0,
        };
    }

    var skillStates: [40]character_screen.structs.SkillState = undefined;

    for (0..40) |i| {
        skillStates[i] = character_screen.structs.SkillState{
            .id = 0,
            .level = 0,
        };
    }

    var attributes: [40]character_screen.structs.Attribute = undefined;

    for (0..40) |i| {
        attributes[i] = character_screen.structs.Attribute{
            .id = 0,
            .value = 0,
        };
    }

    var kitbagItems: [40]character_screen.structs.KitbagItem = undefined;

    for (0..40) |i| {
        var instAttrs: [5]character_screen.structs.InstAttr = undefined;

        for (0..5) |index| {
            instAttrs[index] = character_screen.structs.InstAttr{
                .id = 0,
                .value = 0,
            };
        }

        kitbagItems[i] = character_screen.structs.KitbagItem{
            .endure = [2]u16{ 0, 0 },
            .energy = [2]u16{ 0, 0 },
            .forgeLevel = 0,
            .gridId = 0,
            .id = 0,
            .instAttrs = instAttrs,
            .isParams = false,
            .isValid = false,
            .itemDbForge = 0,
            .itemDbInstId = 0,
            .num = 4,
        };
    }

    var boats: [3]character_screen.structs.CharacterBoat = undefined;

    for (0..3) |i| {
        boats[i] = character_screen.structs.CharacterBoat{
            .characterAttribute = character_screen.structs.CharacterAttribute{
                .attributes = attributes,
                .num = 0,
                .type = 0,
            },
            .characterKitbag = character_screen.structs.CharacterKitbag{
                .items = kitbagItems,
                .keybagNum = 0,
                .type = 0,
            },
            .characterBase = character_screen.structs.CharacterBase{
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
                .position = character_screen.structs.Position{
                    .radius = 0,
                    .x = 0,
                    .y = 0,
                },
                .angle = 0,
                .teamLeaderId = 0,
                .side = character_screen.structs.CharacterSide{
                    .sideId = 0,
                },
                .entityEvent = character_screen.structs.EntityEvent{
                    .entityId = 0,
                    .entityType = 0,
                    .eventId = 0,
                    .eventName = "",
                },
                .look = character_screen.structs.CharacterLook{ .isBoat = 0, .typeId = 0, .synType = 0, .lookHuman = character_screen.structs.CharacterLookHuman{
                    .hairId = 0,
                    .itemGrid = characterLookItems,
                }, .lookBoat = character_screen.structs.CharacterLookBoat{
                    .boatId = 0,
                    .body = 0,
                    .cannon = 0,
                    .engine = 0,
                    .equipment = 0,
                    .header = 0,
                    .posId = 0,
                } },
                .pkCtrl = character_screen.structs.CharacterPK{
                    .pkCtrl = 0,
                },
                .lookAppend = characterAppendLook,
            },
            .characterSkillState = character_screen.structs.CharacterSkillState{
                .states = skillStates,
                .statesLen = 0,
            },
        };
    }

    const enterGame = character_screen.structs.EnterGame{
        .enterRet = 0,
        .autoLock = 0,
        .kitbagLock = 0,
        .enterType = 1,
        .isNewChar = 1,
        .mapName = character.map,
        .canTeam = 1,
        .characterBase = character_screen.structs.CharacterBase{
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
            .position = character_screen.structs.Position{
                .radius = 0,
                .x = 0,
                .y = 0,
            },
            .angle = 0,
            .teamLeaderId = 0,
            .side = character_screen.structs.CharacterSide{
                .sideId = 0,
            },
            .entityEvent = character_screen.structs.EntityEvent{
                .entityId = 0,
                .entityType = 0,
                .eventId = 0,
                .eventName = "",
            },
            .look = character_screen.structs.CharacterLook{ .isBoat = 0, .typeId = 0, .synType = 0, .lookHuman = character_screen.structs.CharacterLookHuman{
                .hairId = 0,
                .itemGrid = characterLookItems,
            }, .lookBoat = character_screen.structs.CharacterLookBoat{
                .boatId = 0,
                .body = 0,
                .cannon = 0,
                .engine = 0,
                .equipment = 0,
                .header = 0,
                .posId = 0,
            } },
            .pkCtrl = character_screen.structs.CharacterPK{
                .pkCtrl = 0,
            },
            .lookAppend = characterAppendLook,
        },
        .characterSkillBag = character_screen.structs.CharacterSkillBag{
            .skillId = 0,
            .skillNum = 0,
            .skills = skills,
            .type = 0,
        },
        .characterSkillState = character_screen.structs.CharacterSkillState{
            .states = skillStates,
            .statesLen = 0,
        },
        .characterAttribute = character_screen.structs.CharacterAttribute{
            .attributes = attributes,
            .num = 0,
            .type = 0,
        },
        .characterKitbag = character_screen.structs.CharacterKitbag{
            .items = kitbagItems,
            .keybagNum = 0,
            .type = 0,
        },
        .characterShortcut = character_screen.structs.CharacterShortcut{
            .shortcuts = shortcuts,
        },
        .boatLen = 0,
        .characterBoats = boats,
        .chaMainId = 0,
    };
    const enterGamePkt = core.bytes.packHeaderBytes(allocator, enterGame);

    std.debug.print("characters choice with one character: {X:1}\n", .{std.fmt.fmtSliceHexUpper(enterGamePkt)});
}
