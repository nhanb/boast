const std = @import("std");
const html = @import("./html.zig");
const git = @import("./git.zig");

pub fn index(allocator: std.mem.Allocator, writer: anytype, repos: [][]const u8) !void {
    var h = html.Builder{ .allocator = allocator };
    var repo_rows = std.ArrayList(html.Element).init(allocator);
    for (repos) |repo| {
        std.debug.print("{s}\n", .{repo});
        const text = try allocator.dupe(u8, repo);
        try repo_rows.append(html.Element{
            .tag = "li",
            .children = &.{
                .{ .text = text },
            },
        });
    }

    var document = html.Element{
        .tag = "html",
        .attrs = &.{.{ "lang", "en" }},
        .children = &.{
            .{
                .tag = "head",
                .children = &.{
                    .{ .tag = "meta", .attrs = &.{.{ "charset", "utf-8" }} },
                    .{ .tag = "meta", .attrs = &.{
                        .{ "name", "viewport" },
                        .{ "content", "width=device-width, initial-scale=1.0" },
                    } },
                    .{ .tag = "title", .children = &.{.{ .text = "Hello" }} },
                },
            },
            .{
                .tag = "body",
                .children = repo_rows.items,
            },
        },
    };

    try h.write(document, writer);
}

test "index" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arena_alloc = arena.allocator();

    var repos = try git.findRepos(arena_alloc, "/home/nhanb/pj/");
    var output = std.ArrayList(u8).init(arena_alloc);
    try index(arena_alloc, output.writer(), repos);

    const file = try std.fs.cwd().createFile("index.html", .{});
    defer file.close();
    try file.writeAll(output.items);
}
