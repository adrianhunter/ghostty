const std = @import("std");
const builtin = @import("builtin");
const Build = std.Build;
const ResolvedTarget = Build.ResolvedTarget;
const Dependency = Build.Dependency;
const OptimizeMode = std.builtin.OptimizeMode;

pub const Backend = enum {
    gl,
    gles3,
    wgpu,
};

pub const TargetPlatform = enum {
    browser,
};

pub fn isPlatform(target: std.Target, platform: TargetPlatform) bool {
    return switch (platform) {
        .browser => target.cpu.arch.isWasm(),
    };
}

const Dep = struct {
    name: []const u8,
    lazy: bool = true,
    artifact: ?[]const u8 = null,
    module: ?[]const u8 = null,
};

const Config = struct {
    deps: []const Dep = &.{},
    target: ResolvedTarget,
    optimize: OptimizeMode,
    builder: *Build,
    name: []const u8,
    emit_wat: bool = true,

    output_ext: []const u8 = "js",
    install_subdir: []const u8 = "",
    extra_args: []const []const u8 = &.{},
    environment: Environment = .web,

    // module:  *Build.Module,
    step: *std.Build.Step.Compile,
};

pub fn configure(config: Config) !void {
    const builder = config.builder;
    const deps = config.deps;
    const target = config.target;
    const optimize = config.optimize;
    const b = builder;
    const step = config.step;

    const mod = config.step.root_module;
    const self = builder.dependency("emsdk", .{});

    const dep_emsdk = self.builder.dependency("emsdk", .{});

    // need to inject the Emscripten system header include path into
    // the cimgui C library otherwise the C/C++ code won't find
    // C stdlib headers
    const emsdk_incl_path = dep_emsdk.path("upstream/emscripten/cache/sysroot/include");

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

            DOG.addSystemIncludePath(emsdk_incl_path);
            DOG.linkSystemLibrary2("pthread", .{
                .needed = true,
            });

            if (dep.module) |module_name| {
                const mod_ = xx.module(module_name);

                mod_.addSystemIncludePath(emsdk_incl_path);
            }
        }
    }

    const dep_sokol = b.dependency("sokol", .{
        .target = target,
        .optimize = optimize,
        .with_sokol_imgui = true,
    });

    const dep_cimgui = b.dependency("cimgui", .{
        .target = target,
        .optimize = optimize,
    });

    dep_sokol.artifact("sokol_clib").addIncludePath(dep_cimgui.path("src"));

    //   const dep_emsdk = dep_sokol.builder.dependency("emsdk", .{});

    // need to inject the Emscripten system header include path into
    // the cimgui C library otherwise the C/C++ code won't find
    // C stdlib headers
    // const emsdk_incl_path = dep_emsdk.path("upstream/emscripten/cache/sysroot/include");
    dep_cimgui.artifact("cimgui_clib").addSystemIncludePath(emsdk_incl_path);

    // all C libraries need to depend on the sokol library, when building for
    // WASM this makes sure that the Emscripten SDK has been setup before
    // C compilation is attempted (since the sokol C library depends on the
    // Emscripten SDK setup step)
    dep_cimgui.artifact("cimgui_clib").step.dependOn(&dep_sokol.artifact("sokol_clib").step);

    step.root_module.addImport("sokol", dep_sokol.module("sokol"));
    step.root_module.addImport("cimgui", dep_cimgui.module("cimgui"));

    // create a build step which invokes the Emscripten linker
    const link_step = try emLinkStep(builder, .{
        .lib_main = config.step,
        .target = mod.resolved_target.?,
        .optimize = mod.optimize.?,
        .emsdk = dep_emsdk,
        .use_webgl2 = true,
        .use_emmalloc = true,
        .extra_args = config.extra_args,
        .use_filesystem = false,
        .output_ext = config.output_ext,
        .install_subdir = config.install_subdir,
        .shell_file_path = self.path("src/web/shell.html"),
    });

    // attach to default target
    b.getInstallStep().dependOn(&link_step.step);
    // ...and a special run step to start the web build output via 'emrun'
    const run = emRunStep(b, .{ .name = config.name, .emsdk = dep_emsdk });
    run.step.dependOn(&link_step.step);
    b.step("run", "Run demo").dependOn(&run.step);
}

pub fn build(b: *Build) !void {
    const target = b.standardTargetOptions(.{});
    _ = target; // autofix
    const optimize = b.standardOptimizeOption(.{});
    _ = optimize; // autofix
    const emsdk = b.dependency("emsdk", .{});
    _ = emsdk; // autofix

}

// helper function to resolve .auto backend based on target platform
pub fn resolveBackend(backend: Backend, target: std.Target) Backend {
    _ = backend; // autofix
    if (isPlatform(target, .browser)) {
        return .gles3;
    } else {
        return .gl;
    }
}

//== EMSCRIPTEN INTEGRATION ============================================================================================
const Environment = enum { web, worker, node, shell };
// for wasm32-emscripten, need to run the Emscripten linker from the Emscripten SDK
// NOTE: ideally this would go into a separate emsdk-zig package
pub const EmLinkOptions = struct {
    target: Build.ResolvedTarget,
    optimize: OptimizeMode,
    lib_main: *Build.Step.Compile, // the actual Zig code must be compiled to a static link library
    emsdk: *Build.Dependency,
    release_use_closure: bool = true,
    release_use_lto: bool = true,
    use_webgpu: bool = false,
    use_webgl2: bool = false,
    use_emmalloc: bool = false,
    output_ext: []const u8 = ".js",
    install_subdir: []const u8 = "web",
    environment: Environment = .web,

    use_offset_converter: bool = false, // needed for @returnAddress builtin used by Zig allocators
    use_filesystem: bool = true,
    shell_file_path: ?Build.LazyPath,
    extra_args: []const []const u8 = &.{},
};
pub fn emLinkStep(b: *Build, options: EmLinkOptions) !*Build.Step.InstallDir {
    const emcc_path = emTool(b, options.emsdk, "emcc").getPath(b);
    const emcc = b.addSystemCommand(&.{emcc_path});
    var exportedFnNames = std.ArrayList([]const u8).init(b.allocator);
    defer exportedFnNames.deinit();
    emcc.setName("emcc"); // hide emcc path

    for (options.lib_main.root_module.export_symbol_names) |name| {
        try exportedFnNames.append(b.fmt("_{s}", .{name}));
    }

    const exportedFnNamesFinal = try std.mem.join(b.allocator, ",", exportedFnNames.items);

    emcc.addArg(b.fmt("-sEXPORTED_FUNCTIONS={s}", .{exportedFnNamesFinal}));

    emcc.addArgs(&.{
        "-sEXPORT_ES6=1",
        "--no-entry",
        "-sPURE_WASI=1",

        "-sJSPI=1",
        // "-sEXPORT_ALL=1",
        // "-sEXPORT_KEEPALIVE=1",
        // "-sEXPORTED_RUNTIME_METHODS=libghostty.a",
        // "-sEXPORTED_FUNCTIONS=_default",
        // b.fmt("-sEXPORTED_FUNCTIONS={s}", .{options.lib_main.root_module.export_symbol_names}),
        //     try std.mem.concat(
        //     b.allocator,
        //     u8,
        //     &.{
        //         "-sENVIRONMENT=", @tagName(options.environment),
        //     },
        // ),
        try std.mem.concat(
            b.allocator,
            u8,
            &.{
                "-sENVIRONMENT=", @tagName(options.environment),
            },
        ),
        "-sJS_BASE64_API",
    });

    if (options.optimize == .Debug) {
        emcc.addArgs(&.{
            // "-Og",
            "-sSAFE_HEAP=1",
            "-sASSERTIONS=1",
            "-sSTACK_OVERFLOW_CHECK=1",
        });
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

    // add the main lib, and then scan for library dependencies and add those too
    emcc.addArtifactArg(options.lib_main);
    for (options.lib_main.getCompileDependencies(false)) |item| {
        if (item.kind == .lib) {
            emcc.addArtifactArg(item);
        }
    }
    emcc.addArg("-o");
    const out_file = emcc.addOutputFileArg(b.fmt("{s}.{s}", .{ options.lib_main.name, options.output_ext }));

    // the emcc linker creates 3 output files (.html, .wasm and .js)
    const install = b.addInstallDirectory(.{
        .source_dir = out_file.dirname(),
        .install_dir = .prefix,
        .install_subdir = options.install_subdir,
    });
    install.step.dependOn(&emcc.step);
    return install;
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
