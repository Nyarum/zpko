const std = @import("std");
const LazyPath = std.Build.LazyPath;

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) !void {
    const lmdb = b.addModule("lmdb", .{ .root_source_file = LazyPath.relative("libs/zig-lmdb/src/lib.zig") });
    const lmdb_dep = b.dependency("lmdb", .{});

    lmdb.addIncludePath(lmdb_dep.path("libraries/liblmdb"));
    lmdb.addCSourceFile(.{ .file = lmdb_dep.path("libraries/liblmdb/mdb.c") });
    lmdb.addCSourceFile(.{ .file = lmdb_dep.path("libraries/liblmdb/midl.c") });

    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    const xev_module = b.dependency("xev", .{}).module("xev");

    const core_module = b.createModule(.{ .root_source_file = LazyPath.relative("src/core/import.zig"), .imports = &.{ .{ .name = "xev", .module = xev_module }, .{ .name = "lmdb", .module = lmdb } } });

    const auth_module = b.createModule(.{
        .root_source_file = LazyPath.relative("src/auth/import.zig"),
    });
    core_module.addImport("auth", auth_module);
    auth_module.addImport("core", core_module);

    const character_screen_module = b.createModule(.{ .root_source_file = LazyPath.relative("src/character_screen/import.zig"), .imports = &.{
        .{ .name = "core", .module = core_module },
    } });
    core_module.addImport("character_screen", character_screen_module);
    auth_module.addImport("character_screen", character_screen_module);

    const exe = b.addExecutable(.{
        .name = "zpko",
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("xev", xev_module);
    exe.root_module.addImport("lmdb", lmdb);
    exe.root_module.addImport("core", core_module);
    exe.root_module.addImport("auth", auth_module);
    exe.root_module.addImport("character_screen", character_screen_module);

    const pretty = b.dependency("pretty", .{ .target = target, .optimize = optimize });
    exe.root_module.addImport("pretty", pretty.module("pretty"));

    exe.linkLibC();
    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const unit_tests_characters_screen = b.addTest(.{
        .root_source_file = .{ .path = "src/character_screen/tests.zig" },
        .target = target,
        .optimize = optimize,
    });

    unit_tests_characters_screen.linkLibC();

    unit_tests_characters_screen.root_module.addImport("pretty", pretty.module("pretty"));
    unit_tests_characters_screen.root_module.addImport("lmdb", lmdb);
    unit_tests_characters_screen.root_module.addImport("character_screen", character_screen_module);
    unit_tests_characters_screen.root_module.addImport("core", core_module);

    const run_unit_tests_c = b.addRunArtifact(unit_tests_characters_screen);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests_c.step);

    const unit_tests_core = b.addTest(.{
        .root_source_file = .{ .path = "src/core/tests.zig" },
        .target = target,
        .optimize = optimize,
    });

    unit_tests_core.root_module.addImport("character_screen", character_screen_module);
    unit_tests_core.root_module.addImport("core", core_module);

    const run_unit_tests_core = b.addRunArtifact(unit_tests_core);

    const test_step_core = b.step("test_core", "Run unit tests for storage");
    test_step_core.dependOn(&run_unit_tests_core.step);
}
