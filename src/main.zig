const std = @import("std");
const html_builder = @import("./html_builder.zig");

pub fn main() !void {
    // Init arena allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa_alloc = gpa.allocator();
    var arena = std.heap.ArenaAllocator.init(gpa_alloc);
    defer arena.deinit();
    const arena_alloc = arena.allocator();

    // Get user input as string (actually an array list)
    std.debug.print("Input please: ", .{});
    const stdin = std.io.getStdIn().reader();
    var user_input = std.ArrayList(u8).init(arena_alloc);
    try stdin.streamUntilDelimiter(user_input.writer(), '\n', null);

    const h = try html_builder.HtmlBuilder.init(arena_alloc);
    var html = h.El(
        "div",
        .{
            .id = "foo",
            .class = "bar",
        },
        .{
            "This is ",
            h.El("b", .{}, .{user_input.items}),
        },
    );
    std.debug.print("Here's your html:\n{s}", .{html});
}
