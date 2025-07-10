const builtin = @import("builtin");
const Build = std.Build;
const OptimizeMode = std.builtin.OptimizeMode;
const ResolvedTarget = Build.ResolvedTarget;
const Dependency = Build.Dependency;
// re-export the shader compiler module for use by upstream projects

pub const SokolBackend = enum {
    // auto, // Windows: D3D11, macOS/iOS: Metal, otherwise: GL
    // d3d11,
    // metal,
    // gl,
    gles3,
    wgpu,
};

pub const TargetPlatform = enum {
    // android,
    // linux,
    // darwin, // macos and ios
    // macos,
    // ios,
    // windows,
    web,
};

pub fn isPlatform(target: std.Target, platform: TargetPlatform) bool {
    return switch (platform) {
        // .android => target.abi.isAndroid(),
        // .linux => target.os.tag == .linux,
        // .darwin => target.os.tag.isDarwin(),
        // .macos => target.os.tag == .macos,
        // .ios => target.os.tag == .ios,
        // .windows => target.os.tag == .windows,
        .web => target.cpu.arch.isWasm(),
    };
}

const Emsdk = @This();

const std = @import("std");
const Config = @import("Config.zig");
const SharedDeps = @import("SharedDeps.zig");

/// The primary Ghostty executable.
// exe: *std.Build.Step.Compile,

// /// The install step for the executable.
// install_step: *std.Build.Step.InstallArtifact,

const ConfigureOptions = struct {
    name: []const u8,
    lazy: bool = true,
    artifact: ?[]const u8 = null,
    module: ?[]const u8 = null,
};

pub fn configureDependencies(b: *Build, target: ResolvedTarget, optimize: OptimizeMode, parent: *Dependency, deps: []const DEP, dep_config: DepsConfig) !void {
    _ = b; // autofix
    const builder = parent.builder;

    for (deps) |dep| {
        const dep_xxx = if (dep.lazy) builder.lazyDependency(dep.name, .{
            .target = target,
            .optimize = optimize,
        }) else builder.dependency(dep.name, .{
            .target = target,
            .optimize = optimize,
        });

        if (dep_xxx) |xx| {
            const artifactName = if (dep.artifact) |x| x else dep.name;
            const DOG = xx.artifact(artifactName);
            for (dep_config.systemIncludePaths) |emsdk_incl_path| {
                // add the Emscripten system include path to the C library
                // so that it can find the C stdlib headers
                DOG.addSystemIncludePath(emsdk_incl_path);
            }

            if (dep.module) |module_name| {
                const mod = xx.module(module_name);

                for (dep_config.systemIncludePaths) |emsdk_incl_path| {
                    // add the Emscripten system include path to the C library
                    // so that it can find the C stdlib headers
                    // DOG.addSystemIncludePath(emsdk_incl_path);
                    mod.addSystemIncludePath(emsdk_incl_path);
                }

                // add the module import to the main module
                // DOG.root_module.addImport(.{
                //     .name = module_name,
                //     .module = dep_xxx.module(dep.name),
                // });
            }

            // DOG.addSystemIncludePath(emsdk_incl_path);
        }
    }
}

pub fn configure(b: *std.Build, cfg: *const Config) !Emsdk {
    _ = b; // autofix
    _ = cfg; // autofix

}

pub fn init(b: *std.Build, cfg: *const Config) !Emsdk {
    _ = b; // autofix
    _ = cfg; // autofix

    return .{};
    // const opt_use_gl = b.option(bool, "gl", "Force OpenGL (default: false)") orelse false;
    // const opt_use_gles3 = b.option(bool, "gles3", "Force OpenGL ES3 (default: false)") orelse false;
    // const opt_use_wgpu = b.option(bool, "wgpu", "Force WebGPU (default: false, web only)") orelse false;
    // const opt_use_x11 = b.option(bool, "x11", "Force X11 (default: true, Linux only)") orelse true;
    // const opt_use_wayland = b.option(bool, "wayland", "Force Wayland (default: false, Linux only, not supported in main-line headers)") orelse false;
    // const opt_use_egl = b.option(bool, "egl", "Force EGL (default: false, Linux only)") orelse false;
    // const opt_with_sokol_imgui = b.option(bool, "with_sokol_imgui", "Add support for sokol_imgui.h bindings") orelse true;
    // const opt_dont_link_system_libs = b.option(bool, "dont_link_system_libs", "Do not link system libraries required by sokol (default: false)") orelse false;
    // const opt_sokol_imgui_cprefix = b.option([]const u8, "sokol_imgui_cprefix", "Override Dear ImGui C bindings prefix for sokol_imgui.h (see SOKOL_IMGUI_CPREFIX)");
    // const opt_cimgui_header_path = b.option([]const u8, "cimgui_header_path", "Override the Dear ImGui C bindings header name (default: cimgui.h)");
    // const opt_dynamic_linkage = b.option(bool, "dynamic_linkage", "Build sokol_clib artifact as dynamic link library.") orelse false;
    // const sokol_backend: SokolBackend = if (opt_use_gl) .gl else if (opt_use_gles3) .gles3 else if (opt_use_wgpu) .wgpu else .auto;

    // const target = b.standardTargetOptions(.{});
    // const optimize = b.standardOptimizeOption(.{});
    // const emsdk = b.dependency("emsdk", .{});

    // // a module for the actual bindings, and a static link library with the C code
    // const mod_sokol = b.addModule("sokol", .{ .root_source_file = b.path("src/sokol/sokol.zig") });
    // const lib_sokol = try buildLibSokol(b, .{
    //     .target = target,
    //     .optimize = optimize,
    //     .backend = sokol_backend,
    //     .dynamic_linkage = opt_dynamic_linkage,
    //     .use_wayland = opt_use_wayland,
    //     .use_x11 = opt_use_x11,
    //     .use_egl = opt_use_egl,
    //     .with_sokol_imgui = opt_with_sokol_imgui,
    //     .sokol_imgui_cprefix = opt_sokol_imgui_cprefix,
    //     .cimgui_header_path = opt_cimgui_header_path,
    //     .emsdk = emsdk,
    //     .dont_link_system_libs = opt_dont_link_system_libs,
    // });
    // mod_sokol.linkLibrary(lib_sokol);

}

pub fn build(b: *Build) !void {
    const opt_use_gl = b.option(bool, "gl", "Force OpenGL (default: false)") orelse false;
    const opt_use_gles3 = b.option(bool, "gles3", "Force OpenGL ES3 (default: false)") orelse false;
    const opt_use_wgpu = b.option(bool, "wgpu", "Force WebGPU (default: false, web only)") orelse false;
    const opt_use_x11 = b.option(bool, "x11", "Force X11 (default: true, Linux only)") orelse true;
    const opt_use_wayland = b.option(bool, "wayland", "Force Wayland (default: false, Linux only, not supported in main-line headers)") orelse false;
    const opt_use_egl = b.option(bool, "egl", "Force EGL (default: false, Linux only)") orelse false;
    const opt_with_sokol_imgui = b.option(bool, "with_sokol_imgui", "Add support for sokol_imgui.h bindings") orelse true;
    const opt_dont_link_system_libs = b.option(bool, "dont_link_system_libs", "Do not link system libraries required by sokol (default: false)") orelse false;
    const opt_sokol_imgui_cprefix = b.option([]const u8, "sokol_imgui_cprefix", "Override Dear ImGui C bindings prefix for sokol_imgui.h (see SOKOL_IMGUI_CPREFIX)");
    const opt_cimgui_header_path = b.option([]const u8, "cimgui_header_path", "Override the Dear ImGui C bindings header name (default: cimgui.h)");
    const opt_dynamic_linkage = b.option(bool, "dynamic_linkage", "Build sokol_clib artifact as dynamic link library.") orelse false;
    const sokol_backend: SokolBackend = if (opt_use_gl) .gl else if (opt_use_gles3) .gles3 else if (opt_use_wgpu) .wgpu else .auto;

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const emsdk = b.dependency("emsdk", .{});

    // a module for the actual bindings, and a static link library with the C code
    const mod_sokol = b.addModule("sokol", .{ .root_source_file = b.path("src/sokol/sokol.zig") });
    const lib_sokol = try buildLibSokol(b, .{
        .target = target,
        .optimize = optimize,
        .backend = sokol_backend,
        .dynamic_linkage = opt_dynamic_linkage,
        .use_wayland = opt_use_wayland,
        .use_x11 = opt_use_x11,
        .use_egl = opt_use_egl,
        .with_sokol_imgui = opt_with_sokol_imgui,
        .sokol_imgui_cprefix = opt_sokol_imgui_cprefix,
        .cimgui_header_path = opt_cimgui_header_path,
        .emsdk = emsdk,
        .dont_link_system_libs = opt_dont_link_system_libs,
    });
    mod_sokol.linkLibrary(lib_sokol);
}

/// Add the ghostty exe to the install target.
pub fn install(self: *const Emsdk) !void {
    _ = self; // autofix
    // const b = self.install_step.step.owner;
    // b.getInstallStep().dependOn(&self.install_step.step);
}

// helper function to resolve .auto backend based on target platform
pub fn resolveSokolBackend(backend: SokolBackend, target: std.Target) SokolBackend {
    if (backend != .auto) {
        return backend;
    } else if (isPlatform(target, .darwin)) {
        return .metal;
    } else if (isPlatform(target, .windows)) {
        return .d3d11;
    } else if (isPlatform(target, .web)) {
        return .gles3;
    } else if (isPlatform(target, .android)) {
        return .gles3;
    } else {
        return .gl;
    }
}

// build the sokol C headers into a static library
pub const LibSokolOptions = struct {
    target: Build.ResolvedTarget,
    optimize: OptimizeMode,
    backend: SokolBackend = .auto,
    use_egl: bool = false,
    use_x11: bool = true,
    dynamic_linkage: bool = false,
    use_wayland: bool = false,
    emsdk: ?*Build.Dependency = null,
    with_sokol_imgui: bool = false,
    sokol_imgui_cprefix: ?[]const u8 = null,
    cimgui_header_path: ?[]const u8 = null,
    dont_link_system_libs: bool = true,
};
pub fn buildLibSokol(b: *Build, options: LibSokolOptions) !*Build.Step.Compile {
    const csrc_root = "src/sokol/c/";
    const csources = [_][]const u8{
        "sokol_log.c",
        "sokol_app.c",
        "sokol_gfx.c",
        "sokol_time.c",
        "sokol_audio.c",
        "sokol_gl.c",
        "sokol_debugtext.c",
        "sokol_shape.c",
        "sokol_glue.c",
        "sokol_fetch.c",
    };
    const mod = b.addModule("mod_sokol_clib", .{
        .target = options.target,
        .optimize = options.optimize,
        .link_libc = true,
    });
    const mod_target = options.target.result;
    const backend = resolveSokolBackend(options.backend, mod_target);
    const lib = b.addLibrary(.{
        .name = "sokol_clib",
        .linkage = if (options.dynamic_linkage) .dynamic else .static,
        .root_module = mod,
    });
    if (isPlatform(mod_target, .web) and mod_target.os.tag == .emscripten) {
        const emsdk = options.emsdk orelse {
            std.log.err("Must provide emsdk dependency when building for web (LibSokolOptions.emsdk)", .{});
            return error.EmscriptenSdkDepenencyExpected;
        };
        // make sure we're building for the wasm32-emscripten target, not wasm32-freestanding
        if (mod_target.os.tag != .emscripten) {
            std.log.err("Please build with 'zig build -Dtarget=wasm32-emscripten", .{});
            return error.TargetWasm32EmscriptenExpected;
        }
        const opt_emsdk_setup_step = try emSdkSetupStep(b, emsdk);

        // for WebGPU, need to run embuilder for `emdawnwebgpu` after emsdk setup and before C library build
        if (options.backend == .wgpu) {
            const embuilder_step = emBuilderStep(b, .{
                .port_name = "emdawnwebgpu",
                .emsdk = emsdk,
            });
            if (opt_emsdk_setup_step) |emsdk_setup_step| {
                embuilder_step.step.dependOn(&emsdk_setup_step.step);
            }
            lib.step.dependOn(&embuilder_step.step);
            // need to add include path to find emdawnwebgpu <webgpu/webgpu.h> before Emscripten SDK webgpu.h
            mod.addSystemIncludePath(emSdkLazyPath(b, emsdk, &.{ "upstream", "emscripten", "cache", "ports", "emdawnwebgpu", "emdawnwebgpu_pkg", "webgpu", "include" }));
        } else {
            if (opt_emsdk_setup_step) |emsdk_setup_step| {
                lib.step.dependOn(&emsdk_setup_step.step);
            }
        }

        // add the Emscripten system include seach path
        mod.addSystemIncludePath(emSdkLazyPath(b, emsdk, &.{ "upstream", "emscripten", "cache", "sysroot", "include" }));
    }

    // resolve .auto backend into specific backend by platform
    var cflags = try std.BoundedArray([]const u8, 64).init(0);
    try cflags.append("-DIMPL");
    if (options.optimize != .Debug) {
        try cflags.append("-DNDEBUG");
    }
    switch (backend) {
        .d3d11 => try cflags.append("-DSOKOL_D3D11"),
        .metal => try cflags.append("-DSOKOL_METAL"),
        .gl => try cflags.append("-DSOKOL_GLCORE"),
        .gles3 => try cflags.append("-DSOKOL_GLES3"),
        .wgpu => try cflags.append("-DSOKOL_WGPU"),
        else => @panic("unknown sokol backend"),
    }

    // platform specific compile and link options
    const link_system_libs = !options.dont_link_system_libs;
    if (isPlatform(mod_target, .darwin)) {
        try cflags.append("-ObjC");
        if (link_system_libs) {
            mod.linkFramework("Foundation", .{});
            mod.linkFramework("AudioToolbox", .{});
            if (.metal == backend) {
                mod.linkFramework("MetalKit", .{});
                mod.linkFramework("Metal", .{});
            }
            if (mod_target.os.tag == .ios) {
                mod.linkFramework("UIKit", .{});
                mod.linkFramework("AVFoundation", .{});
                if (.gl == backend) {
                    mod.linkFramework("OpenGLES", .{});
                    mod.linkFramework("GLKit", .{});
                }
            } else if (mod_target.os.tag == .macos) {
                mod.linkFramework("Cocoa", .{});
                mod.linkFramework("QuartzCore", .{});
                if (.gl == backend) {
                    mod.linkFramework("OpenGL", .{});
                }
            }
        }
    } else if (isPlatform(mod_target, .android)) {
        if (.gles3 != backend) {
            @panic("For android targets, you must have backend set to GLES3");
        }
        if (link_system_libs) {
            mod.linkSystemLibrary("GLESv3", .{});
            mod.linkSystemLibrary("EGL", .{});
            mod.linkSystemLibrary("android", .{});
            mod.linkSystemLibrary("log", .{});
        }
    } else if (isPlatform(mod_target, .linux)) {
        if (options.use_egl) try cflags.append("-DSOKOL_FORCE_EGL");
        if (!options.use_x11) try cflags.append("-DSOKOL_DISABLE_X11");
        if (!options.use_wayland) try cflags.append("-DSOKOL_DISABLE_WAYLAND");
        const link_egl = options.use_egl or options.use_wayland;
        if (link_system_libs) {
            mod.linkSystemLibrary("asound", .{});
            mod.linkSystemLibrary("GL", .{});
            if (options.use_x11) {
                mod.linkSystemLibrary("X11", .{});
                mod.linkSystemLibrary("Xi", .{});
                mod.linkSystemLibrary("Xcursor", .{});
            }
            if (options.use_wayland) {
                mod.linkSystemLibrary("wayland-client", .{});
                mod.linkSystemLibrary("wayland-cursor", .{});
                mod.linkSystemLibrary("wayland-egl", .{});
                mod.linkSystemLibrary("xkbcommon", .{});
            }
            if (link_egl) {
                mod.linkSystemLibrary("EGL", .{});
            }
        }
    } else if (isPlatform(mod_target, .windows)) {
        if (link_system_libs) {
            mod.linkSystemLibrary("kernel32", .{});
            mod.linkSystemLibrary("user32", .{});
            mod.linkSystemLibrary("gdi32", .{});
            mod.linkSystemLibrary("ole32", .{});
            if (.d3d11 == backend) {
                mod.linkSystemLibrary("d3d11", .{});
                mod.linkSystemLibrary("dxgi", .{});
            }
        }
    } else if (isPlatform(mod_target, .web)) {
        // mod.linkSystemLibrary("GLESv3", .{});
        // mod.linkSystemLibrary("EGL", .{});
        mod.linkSystemLibrary("pthread", .{});

        // mod.linkSystemLibrary("android", .{});
        // mod.linkSystemLibrary("log", .{});
        try cflags.append("-fno-sanitize=undefined");
    }

    // finally add the C source files
    inline for (csources) |csrc| {
        mod.addCSourceFile(.{
            .file = b.path(csrc_root ++ csrc),
            .flags = cflags.slice(),
        });
    }

    // optional Dear ImGui support, the called is required to also
    // add the cimgui include path to the returned compile step
    if (options.with_sokol_imgui) {
        if (options.sokol_imgui_cprefix) |cprefix| {
            try cflags.append(b.fmt("-DSOKOL_IMGUI_CPREFIX={s}", .{cprefix}));
        }
        if (options.cimgui_header_path) |cimgui_header_path| {
            try cflags.append(b.fmt("-DCIMGUI_HEADER_PATH=\"{s}\"", .{cimgui_header_path}));
        }
        mod.addCSourceFile(.{
            .file = b.path(csrc_root ++ "sokol_imgui.c"),
            .flags = cflags.slice(),
        });
    }

    // make sokol headers available to users of `sokol_clib` via `#include "sokol/sokol_gfx.h"
    lib.installHeadersDirectory(b.path("src/sokol/c"), "sokol", .{});

    // installArtifact allows us to find the lib_sokol compile step when
    // sokol is used as package manager dependency via 'dep_sokol.artifact("sokol_clib")'
    b.installArtifact(lib);

    return lib;
}

//== EMSCRIPTEN INTEGRATION ============================================================================================

// for wasm32-emscripten, need to run the Emscripten linker from the Emscripten SDK
// NOTE: ideally this would go into a separate emsdk-zig package
pub const EmLinkOptions = struct {
    target: Build.ResolvedTarget,
    optimize: OptimizeMode,
    lib_main: *Build.Step.Compile, // the actual Zig code must be compiled to a static link library
    emsdk: *Build.Dependency,
    release_use_closure: bool = true,
    release_use_lto: bool = false,
    use_webgpu: bool = false,
    use_webgl2: bool = false,
    use_emmalloc: bool = false,
    use_offset_converter: bool = false, // needed for @returnAddress builtin used by Zig allocators
    use_filesystem: bool = true,
    shell_file_path: ?Build.LazyPath,
    extra_args: []const []const u8 = &.{},
};
pub fn emLinkStep(b: *Build, options: EmLinkOptions) !*Build.Step.InstallDir {
    const emcc_path = emTool(b, options.emsdk, "emcc").getPath(b);
    const emcc = b.addSystemCommand(&.{emcc_path});
    emcc.setName("emcc"); // hide emcc path
    if (options.optimize == .Debug) {
        emcc.addArgs(&.{ "-Og", "-sSAFE_HEAP=1", "-sSTACK_OVERFLOW_CHECK=1" });
    } else {
        emcc.addArg("-sASSERTIONS=0");
        if (options.optimize == .ReleaseSmall) {
            emcc.addArg("-Oz");
        } else {
            emcc.addArg("-O3");
        }
        if (options.release_use_lto) {
            emcc.addArg("-flto");
        }
        if (options.release_use_closure) {
            emcc.addArgs(&.{ "--closure", "1" });
        }
    }
    if (options.use_webgpu) {
        emcc.addArg("--use-port=emdawnwebgpu");
    }
    if (options.use_webgl2) {
        emcc.addArg("-sUSE_WEBGL2=1");
    }
    if (!options.use_filesystem) {
        emcc.addArg("-sNO_FILESYSTEM=1");
    }
    if (options.use_emmalloc) {
        emcc.addArg("-sMALLOC='emmalloc'");
    }
    if (options.use_offset_converter) {
        emcc.addArg("-sUSE_OFFSET_CONVERTER");
    }
    if (options.shell_file_path) |shell_file_path| {
        emcc.addPrefixedFileArg("--shell-file=", shell_file_path);
    }
    for (options.extra_args) |arg| {
        emcc.addArg(arg);
    }

    emcc.addArg("-sUSE_OFFSET_CONVERTER");

    // add the main lib, and then scan for library dependencies and add those too
    emcc.addArtifactArg(options.lib_main);
    for (options.lib_main.getCompileDependencies(false)) |item| {
        if (item.kind == .lib) {
            emcc.addArtifactArg(item);
        }
    }
    emcc.addArg("-o");
    const out_file = emcc.addOutputFileArg(b.fmt("{s}.html", .{options.lib_main.name}));

    // the emcc linker creates 3 output files (.html, .wasm and .js)
    const install_ = b.addInstallDirectory(.{
        .source_dir = out_file.dirname(),
        .install_dir = .prefix,
        .install_subdir = "web",
    });
    install_.step.dependOn(&emcc.step);
    return install_;
}

// build a run step which uses the emsdk emrun command to run a build target in the browser
// NOTE: ideally this would go into a separate emsdk-zig package
pub const EmRunOptions = struct {
    name: []const u8,
    emsdk: *Build.Dependency,
};
pub fn emRunStep(b: *Build, options: EmRunOptions) *Build.Step.Run {
    const emrun_path = emTool(b, options.emsdk, "emrun").getPath(b);
    const emrun = b.addSystemCommand(&.{ emrun_path, b.fmt("{s}/web/{s}.html", .{ b.install_path, options.name }) });
    return emrun;
}

// build a system command step which runs the `embuilder command`
pub const EmBuilderOptions = struct {
    port_name: []const u8,
    lto: bool = false,
    pic: bool = false,
    force: bool = false,
    emsdk: *Build.Dependency,
};
pub fn emBuilderStep(b: *Build, options: EmBuilderOptions) *Build.Step.Run {
    const embuilder_path = emTool(b, options.emsdk, "embuilder").getPath(b);
    const embuilder = b.addSystemCommand(&.{embuilder_path});
    if (options.lto) {
        embuilder.addArg("--lto");
    }
    if (options.pic) {
        embuilder.addArg("--pic");
    }
    if (options.force) {
        embuilder.addArg("--force");
    }
    embuilder.addArgs(&.{ "build", options.port_name });
    return embuilder;
}

// helper function to build a LazyPath from the emsdk root and provided path components
fn emSdkLazyPath(b: *Build, emsdk: *Build.Dependency, sub_paths: []const []const u8) Build.LazyPath {
    return emsdk.path(b.pathJoin(sub_paths));
}

// helper function to get Emscripten SDK tool path
pub fn emTool(b: *Build, emsdk: *Build.Dependency, tool: []const u8) Build.LazyPath {
    return emSdkLazyPath(b, emsdk, &.{ "upstream", "emscripten", tool });
}

fn createEmsdkStep(b: *Build, emsdk: *Build.Dependency) *Build.Step.Run {
    if (builtin.os.tag == .windows) {
        return b.addSystemCommand(&.{emSdkLazyPath(b, emsdk, &.{"emsdk.bat"}).getPath(b)});
    } else {
        const step = b.addSystemCommand(&.{"bash"});
        step.addArg(emSdkLazyPath(b, emsdk, &.{"emsdk"}).getPath(b));
        return step;
    }
}

// One-time setup of the Emscripten SDK (runs 'emsdk install + activate'). If the
// SDK had to be setup, a run step will be returned which should be added
// as dependency to the sokol library (since this needs the emsdk in place),
// if the emsdk was already setup, null will be returned.
// NOTE: ideally this would go into a separate emsdk-zig package
// NOTE 2: the file exists check is a bit hacky, it would be cleaner
// to build an on-the-fly helper tool which takes care of the SDK
// setup and just does nothing if it already happened
// NOTE 3: this code works just fine when the SDK version is updated in build.zig.zon
// since this will be cloned into a new zig cache directory which doesn't have
// an .emscripten file yet until the one-time setup.
fn emSdkSetupStep(b: *Build, emsdk: *Build.Dependency) !?*Build.Step.Run {
    const dot_emsc_path = emSdkLazyPath(b, emsdk, &.{".emscripten"}).getPath(b);
    const dot_emsc_exists = !std.meta.isError(std.fs.accessAbsolute(dot_emsc_path, .{}));
    if (!dot_emsc_exists) {
        const emsdk_install = createEmsdkStep(b, emsdk);
        emsdk_install.addArgs(&.{ "install", "latest" });
        const emsdk_activate = createEmsdkStep(b, emsdk);
        emsdk_activate.addArgs(&.{ "activate", "latest" });
        emsdk_activate.step.dependOn(&emsdk_install.step);
        return emsdk_activate;
    } else {
        return null;
    }
}
