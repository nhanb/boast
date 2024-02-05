const std = @import("std");
const html = @import("./html.zig");
const git = @import("./git.zig");

pub fn index(
    comptime WriterT: type,
    allocator: std.mem.Allocator,
    writer: WriterT,
    repos: [][]const u8,
) !void {
    var h = html.Builder(WriterT, true).init(allocator, writer);
    try h.doctype();
    {
        try h.open("html", .{ .lang = "en", .style = "font-family: sans-serif;" });
        defer h.close();
        {
            try h.open("head", null);
            defer h.close();
            {
                try h.open("title", null);
                defer h.close();
                try h.text("Hello");
            }
            try h.open("meta", .{ .charset = "utf-8" });
            try h.open("meta", .{
                .name = "viewport",
                .content = "width=device-width, initial-scale=1.0",
            });
        }
        {
            try h.open("body", null);
            defer h.close();
            {
                try h.open("h1", null);
                defer h.close();
                try h.text("My repos:");
            }
            try h.open("hr", null);
            {
                try h.open("ul", null);
                defer h.close();
                for (repos) |repo| {
                    try h.open("li", null);
                    defer h.close();
                    {
                        try h.open("a", .{ .href = repo });
                        defer h.close();
                        try h.text(repo);
                    }
                }
            }
        }
    }
}

test "index" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arena_alloc = arena.allocator();

    var repos = try git.findRepos(arena_alloc, "/home/nhanb/pj/");
    var output = std.ArrayList(u8).init(arena_alloc);
    try index(std.ArrayList(u8).Writer, arena_alloc, output.writer(), repos);

    const file = try std.fs.cwd().createFile("index.html", .{});
    defer file.close();
    try file.writeAll(output.items);
}
