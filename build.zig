const std = @import("std");
const log = std.log.scoped(.@"build");

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });


    const exe = b.addExecutable(.{
        .name = "gfx-app",
        .root_module = exe_mod,
    });


    const wgpu_dep = b.dependency("wgpu", .{});


    if (target.result.os.tag == .windows) {
        // move lib dir to zig-out/bin, since windows needs it
        b.installDirectory(.{
            .source_dir = wgpu_dep.path("lib"),
            .install_dir = .bin,
            .install_subdir = ""
        });
        // log.debug("path: {s}", .{b.install_path});
        exe.addLibraryPath(.{ .cwd_relative = b.pathJoin( &.{ b.install_path, "bin" }) });
    } else {
        exe.addLibraryPath(wgpu_dep.path("lib"));

    }
    exe.linkSystemLibrary("wgpu_native");

    const translate_c = b.addTranslateC(.{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("include/c.h")
    });

    translate_c.addIncludePath(wgpu_dep.path("include/webgpu"));
    translate_c.addIncludePath(wgpu_dep.path("include/wgpu"));

    exe.root_module.addImport("c", translate_c.createModule());

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);


    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
