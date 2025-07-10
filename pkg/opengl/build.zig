const std = @import("std");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const module = b.addModule("opengl", .{
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"),
    });
    module.addIncludePath(b.path("../../vendor/glad/include"));

    const lib = b.addStaticLibrary(.{
        .name = "opengl",
        .root_module = module,
        // .link_libc = true,
        // .link_system_libraries = if (target.result.os.tag == .windows) &.{"gdi32", "opengl32"} else null,
    });

    b.installArtifact(lib);
}
