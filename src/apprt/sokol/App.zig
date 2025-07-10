const ig = @import("cimgui");
const sokol = @import("sokol");
const std = @import("std");
const assert = std.debug.assert;
const testing = std.testing;
const Allocator = std.mem.Allocator;
const builtin = @import("builtin");
const build_config = @import("../../build_config.zig");
const xev = @import("../../global.zig").xev;
const build_options = @import("build_options");
const apprt = @import("../../apprt.zig");
const configpkg = @import("../../config.zig");
const input = @import("../../input.zig");
const internal_os = @import("../../os/main.zig");
const systemd = @import("../../os/systemd.zig");
const terminal = @import("../../terminal/main.zig");
const Config = configpkg.Config;
const CoreApp = @import("../../App.zig");
const CoreSurface = @import("../../Surface.zig");

const slog = sokol.log;
const sg = sokol.gfx;
const sapp = sokol.app;
const sglue = sokol.glue;
const simgui = sokol.imgui;

const App = @This();
const state = struct {
    var pass_action: sg.PassAction = .{};
};

export fn init() void {
    std.debug.print("Initializing Ghostty with sokol-zig + Dear Imgui.. \n", .{});
    // initialize sokol-gfx
    sg.setup(.{
        .environment = sglue.environment(),
        .logger = .{ .func = slog.func },
    });
    // initialize sokol-imgui
    simgui.setup(.{
        .logger = .{ .func = slog.func },
    });

    // initial clear color
    state.pass_action.colors[0] = .{
        .load_action = .CLEAR,
        .clear_value = .{ .r = 0.0, .g = 0.5, .b = 1.0, .a = 1.0 },
    };
}

pub const Options = struct {};

core_app: *CoreApp,
config: Config,

// app: *sapp,
// ctx: *glib.MainContext,

/// State and logic for the underlying windowing protocol.
// winproto: winprotopkg.App,

/// True if the app was launched with single instance mode.
single_instance: bool = true,

/// The "none" cursor. We use one that is shared across the entire app.
// cursor_none: ?*gdk.Cursor,

/// The clipboard confirmation window, if it is currently open.
// clipboard_confirmation_window: ?*ClipboardConfirmationWindow = null,

/// The config errors dialog, if it is currently open.
// config_errors_dialog: ?ConfigErrorsDialog = null,

/// The window containing the quick terminal.
/// Null when never initialized.
// quick_terminal: ?*Window = null,

/// This is set to false when the main loop should exit.
running: bool = true,

/// The base path of the transient cgroup used to put all surfaces
/// into their own cgroup. This is only set if cgroups are enabled
/// and initialization was successful.
transient_cgroup_base: ?[]const u8 = null,

/// CSS Provider for any styles based on ghostty configuration values
// css_provider: *gtk.CssProvider,

/// Providers for loading custom stylesheets defined by user
// custom_css_providers: std.ArrayListUnmanaged(*gtk.CssProvider) = .{},

// global_shortcuts: ?GlobalShortcuts,

/// The timer used to quit the application after the last window is closed.
quit_timer: union(enum) {
    off: void,
    active: c_uint,
    expired: void,
} = .{ .off = {} },

pub fn init_app(self: *App, core_app: *CoreApp, opts: Options) !void {
    _ = opts; // autofix

    var config = try Config.load(core_app.alloc);
    errdefer config.deinit();

    self.* = .{
        .core_app = core_app,
        // .app = sapp,
        .config = config,
        // .ctx = ctx,
        // .cursor_none = cursor_none,
        // .winproto = winproto_app,
        // .single_instance = single_instance,
        // If we are NOT the primary instance, then we never want to run.
        // This means that another instance of the GTK app is running and
        // our "activate" call above will open a window.
        // .running = gio_app.getIsRemote() == 0,
        // .css_provider = css_provider,
        // .global_shortcuts = .init(core_app.alloc, gio_app),
    };
}

export fn frame() void {
    // call simgui.newFrame() before any ImGui calls
    simgui.newFrame(.{
        .width = sapp.width(),
        .height = sapp.height(),
        .delta_time = sapp.frameDuration(),
        .dpi_scale = sapp.dpiScale(),
    });

    //=== UI CODE STARTS HERE
    ig.igSetNextWindowPos(.{ .x = 10, .y = 10 }, ig.ImGuiCond_Once);
    ig.igSetNextWindowSize(.{ .x = 400, .y = 100 }, ig.ImGuiCond_Once);
    _ = ig.igBegin("Hello Dear ImGui!", 0, ig.ImGuiWindowFlags_None);
    _ = ig.igColorEdit3("Background", &state.pass_action.colors[0].clear_value.r, ig.ImGuiColorEditFlags_None);
    _ = ig.igText("Dear ImGui Version: %s", ig.IMGUI_VERSION);
    ig.igEnd();
    //=== UI CODE ENDS HERE

    // call simgui.render() inside a sokol-gfx pass
    sg.beginPass(.{ .action = state.pass_action, .swapchain = sglue.swapchain() });
    simgui.render();
    sg.endPass();
    sg.commit();
}

export fn cleanup() void {
    simgui.shutdown();
    sg.shutdown();
}

export fn event(ev: [*c]const sapp.Event) void {
    // forward input events to sokol-imgui
    _ = simgui.handleEvent(ev.*);
}

pub fn run(self: *App) !void {
    _ = self; // autofix
    sapp.run(.{
        .init_cb = init,
        .frame_cb = frame,
        .cleanup_cb = cleanup,
        .event_cb = event,
        .window_title = "Ghostty",
        .width = 800,
        .height = 600,
        .icon = .{ .sokol_default = true },
        .logger = .{ .func = slog.func },
    });
}
