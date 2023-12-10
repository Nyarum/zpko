const uuid4 = @cImport(@cInclude("uuid4.h"));

pub const UUID4 = struct {
    pub fn generate() []const u8 {
        var uuidGen: [36]u8 = undefined;
        _ = uuid4.uuid4_init();
        uuid4.uuid4_generate(&uuidGen);

        return &uuidGen;
    }
};
