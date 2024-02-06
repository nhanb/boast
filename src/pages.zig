const std = @import("std");
const html = @import("./html.zig");
const git = @import("./git.zig");

const concat = std.mem.concat;
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const fs = std.fs;
const print = std.debug.print;
const allocPrint = std.fmt.allocPrint;
const path_sep = std.fs.path.sep_str;

pub fn writeIndex(
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

pub fn writeRepoIndex(
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
                try h.open("p", null);
                defer h.close();
                {
                    try h.open("b", null);
                    defer h.close();
                    try h.text(try allocPrint(aa, "{d}", .{commits.len}));
                }
                try h.text(" commits:");
            }

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
                        try h.open(
                            "a",
                            .{ .href = try concat(aa, u8, &.{ "commits/", commit.hash, ".html" }) },
                        );
                        defer h.close();
                        try h.text(commit.subject);
                    }
                }
            }
        }
    }
}

pub fn writeCommit(
    aa: Allocator,
    writer: anytype,
    repo_path: []const u8,
    commit_hash: []const u8,
) !void {
    print("commit: {s}\n", .{commit_hash});
    var git_result = try std.ChildProcess.exec(.{
        .allocator = aa,
        .argv = &.{ "git", "show", "--color", commit_hash },
        .cwd = repo_path,
        .max_output_bytes = 1024 * 1024 * 1024,
    });
    try writer.writeAll(git_result.stdout);

    //var cp = std.ChildProcess.init(&.{"aha"}, aa);
    //cp.stdin_behavior = .Pipe;
    //cp.stdout_behavior = .Pipe;
    //cp.stderr_behavior = .Pipe;

    //var stdout = std.ArrayList(u8).init(aa);
    //var stderr = std.ArrayList(u8).init(aa);

    //print("spawning\n", .{});
    //try cp.spawn();

    //print("writing\n", .{});
    //print("{s}\n", .{git_result.stdout});
    //try cp.stdin.?.writeAll(git_result.stdout);
    //print("closing\n", .{});
    //cp.stdin.?.close();
    //cp.stdin = null;
    //print("collecting\n", .{});
    //try cp.collectOutput(&stdout, &stderr, 1024 * 1024 * 1024);
    //_ = try cp.wait();

    //try writer.writeAll(try stdout.toOwnedSlice());
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
    try writeIndex(std.ArrayList(u8).Writer, arena_alloc, output.writer(), repos);

    const index_path = try fs.path.join(arena_alloc, &.{ output_path, "index.html" });
    const file = try std.fs.createFileAbsolute(index_path, .{});
    defer file.close();
    try file.writeAll(output.items);

    for (repos) |repo| {
        var repo_arena = ArenaAllocator.init(std.testing.allocator);
        defer repo_arena.deinit();
        const raa = repo_arena.allocator();

        const repo_path = try fs.path.join(raa, &.{ repos_path, repo });

        // Make sure output dir exists
        const out_repo_path = try fs.path.join(raa, &.{ output_path, repo });
        fs.makeDirAbsolute(out_repo_path) catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };

        var commits = try git.listCommits(raa, repo_path);

        {
            // Create repo index file
            const file_path = try fs.path.join(raa, &.{ out_repo_path, "index.html" });
            print("file: {s}\n", .{file_path});
            const repo_index_file = try std.fs.createFileAbsolute(file_path, .{});
            defer repo_index_file.close();
            var repo_index_content = std.ArrayList(u8).init(raa);
            try writeRepoIndex(
                std.ArrayList(u8).Writer,
                raa,
                repo_index_content.writer(),
                repo,
                commits,
            );
            try repo_index_file.writeAll(repo_index_content.items);
        }

        // Create commit files
        const commits_dir_path = try fs.path.join(raa, &.{ out_repo_path, "commits" });
        fs.makeDirAbsolute(commits_dir_path) catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };
        for (commits) |commit| {
            const commit_file_path = try concat(raa, u8, &.{
                commits_dir_path,
                path_sep,
                commit.hash,
                ".html",
            });
            const commit_file = try std.fs.createFileAbsolute(commit_file_path, .{});
            defer commit_file.close();
            try writeCommit(
                raa,
                commit_file,
                repo_path,
                commit.hash,
            );
        }
    }
}
