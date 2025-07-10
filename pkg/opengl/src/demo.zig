const gl = @import("opengl");
const std = @import("std");

pub fn main() !void {
    // const allocator = std.heap.page_allocator;

    // // Initialize OpenGL context
    // const context = try gl.Context.init(allocator);
    // defer context.deinit();

    // // Create a buffer
    // const buffer = try gl.Buffer(i32).initFill(.{ .target = .array, .usage = .dynamic_draw }, &.{ 1, 2, 3, 4 });
    // defer buffer.buffer.destroy();

    // // Bind the buffer
    // const binding = try buffer.buffer.bind(buffer.opts.target);
    // defer binding.unbind();

    // // Set data to the buffer
    // try binding.setData(&.{ 5, 6, 7, 8 }, buffer.opts.usage);

    std.debug.print("Buffer initialized and data set successfully.\n {}", .{gl});
}
