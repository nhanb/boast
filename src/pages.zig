const std = @import("std");
const html = @import("./html.zig");
const git = @import("./git.zig");

pub fn index(allocator: std.mem.Allocator, writer: anytype, repos: [][]const u8) void {
    var h = html.Builder2{ .allocator = allocator };
    var w = writer;

    {
        h.open(w, "html", .{ .lang = "en", .style = "font-family: 'sans-serif';" });
        defer h.close(w, "html");
        {
            h.open(w, "head", null);
            defer h.close(w, "head");
            {
                h.open(w, "title", null);
                defer h.close(w, "title");
                h.write(w, "Hello");
            }
            h.open(w, "meta", .{ .charset = "utf-8" });
            h.open(w, "meta", .{
                .name = "viewport",
                .content = "width=device-width, initial-scale=1.0",
            });
        }
        {
            h.open(w, "body", null);
            defer h.close(w, "body");
            {
                h.open(w, "h1", null);
                defer h.close(w, "h1");
                h.write(w, "My repos:");
            }
            h.open(w, "hr", null);
            {
                h.open(w, "ul", null);
                defer h.close(w, "ul");
                for (repos) |repo| {
                    h.open(w, "li", null);
                    defer h.close(w, "li");
                    {
                        h.open(w, "a", .{ .href = repo });
                        defer h.close(w, "a");
                        h.write(w, repo);
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
    index(arena_alloc, output.writer(), repos);

    const file = try std.fs.cwd().createFile("index.html", .{});
    defer file.close();
    try file.writeAll(output.items);
}
