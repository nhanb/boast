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
        try h.open("html", .{ .lang = "en", .style = "font-family: monospace;" });
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
                try h.open("h2", null);
                defer h.close();
                try h.text("Repos");
            }
            try h.open("hr", null);
            {
                try h.open("ul", null);
                defer h.close();
                for (repos) |repo| {
                    try h.open("li", null);
                    defer h.close();
                    {
                        try h.open("a", .{ .href = try std.mem.concat(allocator, u8, &.{ repo, ".html" }) });
                        defer h.close();
                        try h.text(repo);
                    }
                }
            }
        }
    }
}

pub fn repo_index(
    comptime WriterT: type,
    allocator: std.mem.Allocator,
    writer: WriterT,
    repo_name: []const u8,
    commits: []git.Commit,
) !void {
    var h = html.Builder(WriterT, false).init(allocator, writer);
    try h.doctype();
    {
        try h.open("html", .{ .lang = "en", .style = "font-family: monospace;" });
        defer h.close();
        {
            try h.open("head", null);
            defer h.close();
            {
                try h.open("title", null);
                defer h.close();
                try h.text(repo_name);
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
                try h.open("h2", null);
                defer h.close();
                {
                    try h.open("a", .{ .href = "index.html" });
                    defer h.close();
                    try h.text("Repos");
                }
                try h.text("/");
                try h.text(repo_name);
            }
            try h.open("hr", null);
            {
                try h.open("ul", null);
                defer h.close();
                for (commits) |commit| {
                    try h.open("li", null);
                    defer h.close();
                    try h.text(commit.hash);
                    try h.text(" | ");
                    try h.text(commit.date);
                    try h.text(" | ");
                    {
                        try h.open("a", .{ .href = commit.hash });
                        defer h.close();
                        try h.text(commit.subject);
                    }
                }
            }
        }
    }
}

test "index and repos" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arena_alloc = arena.allocator();

    const repos_path = "/home/nhanb/pj/";

    var repos = try git.findRepos(arena_alloc, repos_path);
    var output = std.ArrayList(u8).init(arena_alloc);
    try index(std.ArrayList(u8).Writer, arena_alloc, output.writer(), repos);

    const file = try std.fs.cwd().createFile("index.html", .{});
    defer file.close();
    try file.writeAll(output.items);

    for (repos) |repo| {
        var repo_arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer repo_arena.deinit();
        const raa = repo_arena.allocator();

        const path = try std.mem.concat(raa, u8, &.{ repos_path, repo });
        var commits = try git.listCommits(raa, path);

        const file_path = try std.mem.concat(raa, u8, &.{ repo, ".html" });
        std.debug.print("file: {s}\n", .{file_path});
        const repo_index_file = try std.fs.cwd().createFile(file_path, .{});
        defer repo_index_file.close();

        var repo_index_content = std.ArrayList(u8).init(raa);
        try repo_index(
            std.ArrayList(u8).Writer,
            raa,
            repo_index_content.writer(),
            repo,
            commits,
        );
        try repo_index_file.writeAll(repo_index_content.items);
    }
}
