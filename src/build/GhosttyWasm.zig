const Ghostty = @This();

const std = @import("std");
const Config = @import("Config.zig");
const SharedDeps = @import("SharedDeps.zig");

/// The primary Ghostty executable.
step: *std.Build.Step.Compile,

/// The install step for the executable.
// install_step: *std.Build.Step.InstallArtifact,

pub fn init(b: *std.Build, cfg: *const Config, deps: *const SharedDeps) !Ghostty {
    std.log.info("CONFIG: {}", .{Config});

    const exe: *std.Build.Step.Compile = b.addStaticLibrary(.{
        .name = "ghostty",
        // .pic = cfg.pie,
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main_wasm.zig"),
            .target = cfg.target,
            .optimize = cfg.optimize,
            // .strip = cfg.strip,
            // .omit_frame_pointer = cfg.strip,
            // .unwind_tables = if (cfg.strip) .none else .sync,
        }),
    });

    // exe.addSystemIncludePath(.{ .cwd_relative = "/opt/homebrew/opt/emscripten/libexec/cache/sysroot/include" });

    exe.root_module.export_symbol_names = &.{
        "default",
        // "frame",
        // "cleanup",
        // "event",
    };

    const bro = b.dependency("opengl", .{
        .target = cfg.target,
        .optimize = cfg.optimize,
    });
    exe.root_module.addImport("opengl", bro.module("opengl"));
    // const bin = exe.getEmittedBin();
    // const install_step = b.addInstallFile(bin, b.fmt("{s}.o", .{"ghostty"}));
    // const install_step = b.addInstallArtifact(exe, .{});

    // Set PIE if requested
    // if (cfg.pie) exe.pie = true;

    _ = try deps.add(exe);

    // std.debug.print(
    //     "Adding xev dependency with path: {}\n",
    //     .{stuff.path("")},
    // );

    // Add the shared dependencies
    // _ = try deps.add(exe);

    // Check for possible issues
    // try checkNixShell(exe, cfg);

    // // Patch our rpath if that option is specified.
    // if (cfg.patch_rpath) |rpath| {
    //     if (rpath.len > 0) {
    //         const run = std.Build.Step.Run.create(b, "patchelf rpath");
    //         run.addArgs(&.{ "patchelf", "--set-rpath", rpath });
    //         run.addArtifactArg(exe);
    //         install_step.step.dependOn(&run.step);
    //     }
    // }

    return .{
        .step = exe,
        // .install_step = install_step,
    };
}
// pub fn addInstallObjectFile(
//     b: *std.Build,
//     compile: *std.Build.Step.Compile,
//     name: []const u8,
//     // out_mode: ObjectFormat,
// ) *std.Build.Step.InstallFile {
//     // bin always needed to be computed or else the compilation will do nothing. zig build system bug?
//     const bin = compile.getEmittedBin();
//     return &b.addInstallFile(bin, b.fmt("{s}.o", .{name}));
// }
/// Add the ghostty exe to the install target.
pub fn install(self: *const Ghostty) void {
    const b = self.install_step.step.owner;
    b.getInstallStep().dependOn(&self.install_step.step);
}

/// If we're in NixOS but not in the shell environment then we issue
/// a warning because the rpath may not be setup properly. This doesn't modify
/// our build in any way but addresses a common build-from-source issue
/// for a subset of users.
fn checkNixShell(exe: *std.Build.Step.Compile, cfg: *const Config) !void {
    // Non-Linux doesn't have rpath issues.
    if (cfg.target.result.os.tag != .linux) return;

    // When cross-compiling, we don't need to worry about matching our
    // Nix shell rpath since the resulting binary will be run on a
    // separate system.
    if (!cfg.target.query.isNativeCpu()) return;
    if (!cfg.target.query.isNativeOs()) return;

    // Verify we're in NixOS
    std.fs.accessAbsolute("/etc/NIXOS", .{}) catch return;

    // If we're in a nix shell, not a problem
    if (cfg.env.get("IN_NIX_SHELL") != null) return;

    try exe.step.addError(
        "\x1b[" ++ color_map.get("yellow").? ++
            "\x1b[" ++ color_map.get("d").? ++
            \\Detected building on and for NixOS outside of the Nix shell environment.
            \\
            \\The resulting ghostty binary will likely fail on launch because it is
            \\unable to dynamically load the windowing libs (X11, Wayland, etc.).
            \\We highly recommend running only within the Nix build environment
            \\and the resulting binary will be portable across your system.
            \\
            \\To run in the Nix build environment, use the following command.
            \\Append any additional options like (`-Doptimize` flags). The resulting
            \\binary will be in zig-out as usual.
            \\
            \\  nix develop -c zig build
            \\
        ++
            "\x1b[0m",
        .{},
    );
}

/// ANSI escape codes for colored log output
const color_map = std.StaticStringMap([]const u8).initComptime(.{
    &.{ "black", "30m" },
    &.{ "blue", "34m" },
    &.{ "b", "1m" },
    &.{ "d", "2m" },
    &.{ "cyan", "36m" },
    &.{ "green", "32m" },
    &.{ "magenta", "35m" },
    &.{ "red", "31m" },
    &.{ "white", "37m" },
    &.{ "yellow", "33m" },
});
