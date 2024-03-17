const lmdb = @import("lmdb");

pub fn saveCharacter(env: lmdb.Environment) !void {
    const txn = try lmdb.Transaction.init(env, .{ .mode = .ReadWrite });
    errdefer txn.abort();

    try txn.set("aaa", "foo");
    try txn.set("bbb", "bar");

    try txn.commit();
}
