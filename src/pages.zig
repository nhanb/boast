const std = @import("std");
const html = @import("./html.zig");
const git = @import("./git.zig");

const concat = std.mem.concat;
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const fs = std.fs;

pub fn index(
    comptime WriterT: type,
    aa: Allocator,
    writer: WriterT,
    repos: [][]const u8,
) !void {
    var h = html.Builder(WriterT, true).init(aa, writer);
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
                try h.text("Boast Index");
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
                        try h.open("a", .{ .href = try concat(aa, u8, &.{ "./", repo, "/index.html" }) });
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
    aa: Allocator,
    writer: WriterT,
    repo_name: []const u8,
    commits: []git.Commit,
) !void {
    var h = html.Builder(WriterT, false).init(aa, writer);
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
                    try h.open("a", .{ .href = "../index.html" });
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
    var arena = ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arena_alloc = arena.allocator();

    const repos_path = "/home/nhanb/pj";
    const output_path = "/home/nhanb/pj/boast/boast-out";

    fs.makeDirAbsolute(output_path) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };

    var repos = try git.findRepos(arena_alloc, repos_path);
    var output = std.ArrayList(u8).init(arena_alloc);
    try index(std.ArrayList(u8).Writer, arena_alloc, output.writer(), repos);

    const index_path = try fs.path.join(arena_alloc, &.{ output_path, "index.html" });
    const file = try std.fs.createFileAbsolute(index_path, .{});
    defer file.close();
    try file.writeAll(output.items);

    for (repos) |repo| {
        var repo_arena = ArenaAllocator.init(std.testing.allocator);
        defer repo_arena.deinit();
        const raa = repo_arena.allocator();

        const repo_path = try fs.path.join(raa, &.{ repos_path, repo });
        var commits = try git.listCommits(raa, repo_path);

        const out_repo_path = try fs.path.join(raa, &.{ output_path, repo });
        fs.makeDirAbsolute(out_repo_path) catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };

        const file_path = try fs.path.join(raa, &.{ out_repo_path, "index.html" });
        std.debug.print("file: {s}\n", .{file_path});
        const repo_index_file = try std.fs.createFileAbsolute(file_path, .{});
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
