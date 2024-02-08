const std = @import("std");
const html = @import("./html.zig");
const git = @import("./git.zig");

const concat = std.mem.concat;
const Allocator = std.mem.Allocator;
const allocPrint = std.fmt.allocPrint;

pub fn writeIndex(
    aa: Allocator,
    writer: anytype,
    repos: [][]const u8,
) !void {
    var h = html.Builder(@TypeOf(writer), true).init(aa, writer);
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
    aa: Allocator,
    writer: anytype,
    repo_name: []const u8,
    commits: []git.Commit,
) !void {
    var h = html.Builder(@TypeOf(writer), false).init(aa, writer);
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
                    try h.text(commit.hash[0..10]);
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
    text_writer: anytype,
    html_writer: anytype,
    repo_path: []const u8,
    commit_hash: []const u8,
) !void {
    // Plaintext diff
    const text_diff = (try std.ChildProcess.run(.{
        .allocator = aa,
        .argv = &.{ "git", "show", commit_hash },
        .cwd = repo_path,
        .max_output_bytes = 1024 * 1024 * 1024,
    })).stdout;
    try text_writer.writeAll(text_diff);

    // HTML diff requires piping git's colored result to `aha`

    const html_diff = (try std.ChildProcess.run(.{
        .allocator = aa,
        .argv = &.{ "git", "show", "--color", commit_hash },
        .cwd = repo_path,
        .max_output_bytes = 1024 * 1024 * 1024,
    })).stdout;

    var cp = std.ChildProcess.init(&.{"aha"}, aa);
    cp.stdin_behavior = .Pipe;
    cp.stdout_behavior = .Pipe;
    cp.stderr_behavior = .Pipe;

    var stdout = std.ArrayList(u8).init(aa);
    var stderr = std.ArrayList(u8).init(aa);

    try cp.spawn();

    // Concurrently drain aha's stdout so it doesn't deadlock on stdin
    const thread = try std.Thread.spawn(.{}, drainStdout, .{ &cp, &stdout, &stderr });

    try cp.stdin.?.writeAll(html_diff);
    cp.stdin.?.close();
    cp.stdin = null;

    thread.join();
    _ = try cp.wait();

    try html_writer.writeAll(try stdout.toOwnedSlice());
}

fn drainStdout(c: *std.ChildProcess, stdout: anytype, stderr: anytype) !void {
    try c.collectOutput(stdout, stderr, 1024 * 1024 * 1024);
}
