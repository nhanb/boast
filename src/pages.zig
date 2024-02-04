const std = @import("std");
const html = @import("./html.zig");
const git = @import("./git.zig");

pub fn index(allocator: std.mem.Allocator, writer: anytype, repos: [][]const u8) !void {
    var h = html.Builder{ .allocator = allocator };
    var repo_rows = std.ArrayList(html.Element).init(allocator);
    for (repos) |repo| {
        try repo_rows.append(h.li(
            .{},
            .{h.a(
                .{ .href = repo },
                .{repo},
            )},
        ));
    }
    var document = h.html(
        .{ .lang = "en" },
        .{
            h.head(.{}, .{
                h.meta(.{ .charset = "utf-8" }),
                h.title(.{}, .{"Hello"}),
                h.meta(.{ .name = "viewport", .content = "width=device-width, initial-scale=1.0" }),
            }),
            h.body(.{}, repo_rows.items),
        },
    );

    try document.writeTo(writer);
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
