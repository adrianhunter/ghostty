pub const Backend = enum { jspi };

pub const Dynamic = struct {
    pub const dynamic = false;
    pub const backend: Backend = .jspi;

    pub const Async = struct {};
    pub const Timer = struct {};
    pub const Loop = struct {};

    pub const Completion = struct {
        // pub const name = "xev";
        // pub const description = "X11 event viewer";
        // pub const version = "0.1.0";

    };
    // pub const authors = &[_][]const u8{"Adrian Cooney <

    // pub const xev = @import("xev.zig");
};

pub fn detect() !void {}
