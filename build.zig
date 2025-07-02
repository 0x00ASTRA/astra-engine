const std = @import("std");
const sdl = @import("sdl");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ########[ Program Executable ]########
    const exe = b.addExecutable(.{
        .name = "AstraEngine",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const sdk = sdl.init(b, .{});
    sdk.link(exe, .dynamic, sdl.Library.SDL2);
    sdk.link(exe, .dynamic, sdl.Library.SDL2_ttf);
    exe.linkSystemLibrary("sdl2_image");
    exe.root_module.addImport("sdl2", sdk.getWrapperModule());

    // ########[ Lua Dependency ]########
    const lua_dep = b.dependency("zlua", .{
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("zlua", lua_dep.module("zlua"));

    // ########[ TOML Dependency ]########
    const toml_dep = b.dependency("toml", .{
        .target = target,
        .optimize = optimize,
    });

    exe.root_module.addImport("toml", toml_dep.module("zig-toml"));

    // ########[ Install ]########
    b.installArtifact(exe);

    // ########[ Run Step ]########
    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // ########[ Test ]########
    const unit_test = b.addTest(.{
        .root_source_file = b.path("src/test.zig"),
        .optimize = optimize,
        .target = target,
    });

    unit_test.root_module.addImport("toml", toml_dep.module("zig-toml"));
    unit_test.root_module.addImport("lua", lua_dep.module("zlua"));

    const run_test = b.addRunArtifact(unit_test);
    const test_step = b.step("test", "run unit tests");
    test_step.dependOn(&run_test.step);
    test_step.dependOn(&b.addRunArtifact(unit_test).step);

    // ########[ AI Workflow ]########
    const run_gemini = b.addSystemCommand(&[_][]const u8{
        "gemini",
    });
    const gemini_step = b.step("gemini", "run the Gemini AI project management workflow.");
    gemini_step.dependOn(&run_gemini.step);
}
