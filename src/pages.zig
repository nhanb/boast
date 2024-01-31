const std = @import("std");
const HtmlBuilder = @import("./HtmlBuilder.zig");

pub fn index(allocator: std.mem.Allocator) []const u8 {
    var h = try HtmlBuilder.init(allocator);
    return h.html(
        .{ .lang = "en" },
        .{
            h.head(.{}, .{
                h.meta(.{ .charset = "utf-8" }),
                h.title(.{}, .{"Hello"}),
                h.meta(.{ .name = "viewport", .content = "width=device-width, initial-scale=1.0" }),
            }),
            h.body(
                .{},
                .{"This is my body."},
            ),
        },
    );
}

test "index" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arena_alloc = arena.allocator();
    const index_html = index(arena_alloc);
    std.debug.print("{s}\n", .{index_html});
}
