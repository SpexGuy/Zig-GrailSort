const std = @import("std");
const path = std.fs.path;
const Builder = std.build.Builder;
const LibExeObjStep = std.build.LibExeObjStep;

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const target = b.standardTargetOptions(.{});
    const tracy_enabled = b.option(bool, "tracy", "Enable tracy in the benchmarks.  Defaults to true.") orelse true;

    const bench_exe = b.addExecutable("bench", "src/benchmark.zig");
    setDependencies(b, bench_exe, mode, target);
    linkTracy(bench_exe, tracy_enabled);

    bench_exe.install();

    const build_bench = b.step("build-bench", "Build benchmarks");
    build_bench.dependOn(&bench_exe.install_step.?.step);

    const bench_run = bench_exe.run();
    if (b.args) |args| bench_run.addArgs(args);

    const bench_step = b.step("bench", "Run benchmarks");
    bench_step.dependOn(&bench_run.step);

    const vscode_exe = b.addExecutable("vscode", "src/vscode.zig");
    setDependencies(b, vscode_exe, mode, target);

    const vscode_install = b.addInstallArtifact(vscode_exe);

    const vscode_step = b.step("vscode", "Build for VSCode");
    vscode_step.dependOn(&vscode_install.step);
}

fn setDependencies(b: *Builder, step: *LibExeObjStep, mode: anytype, target: anytype) void {
    step.setBuildMode(mode);
    step.setTarget(target);
    step.linkLibC();
}

fn linkTracy(step: *LibExeObjStep, enable: bool) void {
    step.addBuildOption(bool, "tracy_enabled", enable);
    step.addIncludeDir("tracy");
    if (enable) {
        step.addCSourceFile("tracy/TracyClient.cpp", &[_][]const u8{
            "-DTRACY_ENABLE",
            "-fno-sanitize=undefined",
        });
    }
    
    if (step.target.isWindows()) {
        step.linkSystemLibrary("Advapi32");
        step.linkSystemLibrary("User32");
    }
}
