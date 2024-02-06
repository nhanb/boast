const std = @import("std");

pub fn findRepos(allocator: std.mem.Allocator, absolute_path: []const u8) ![][]const u8 {
    var repos = std.ArrayList([]const u8).init(allocator);

    var dir = try std.fs.openDirAbsolute(absolute_path, .{ .iterate = true });
    defer dir.close();

    var it = dir.iterate();
    while (try it.next()) |entry| {
        if (entry.kind != std.fs.File.Kind.directory) {
            continue;
        }

        // Skip subdir if it's not a git repo
        if (!std.mem.endsWith(u8, entry.name, ".git")) {
            const git_subfolder_path = try std.mem.concat(allocator, u8, &[_][]const u8{
                entry.name,
                std.fs.path.sep_str,
                ".git",
            });
            if (dir.access(git_subfolder_path, .{})) |_| {} else |_| {
                continue;
            }
        }

        const dir_name = try allocator.dupe(u8, entry.name);
        try repos.append(dir_name);
    }

    return repos.items;
}

test "findRepos" {
    const test_allocator = std.testing.allocator;

    var arena = std.heap.ArenaAllocator.init(test_allocator);
    defer arena.deinit();
    const arena_allocator = arena.allocator();

    // TODO: how do I mock a filesystem?
    const repos = try findRepos(arena_allocator, "/home/nhanb/pj/");

    //std.debug.print("\n", .{});
    //for (repos) |path| {
    //    std.debug.print(">> {s}\n", .{path});
    //}

    try std.testing.expect(repos.len > 0);
}

pub const Commit = struct {
    hash: []const u8,
    subject: []const u8,
    date: []const u8,
};

pub fn listCommits(allocator: std.mem.Allocator, absolute_path: []const u8) ![]Commit {
    const result = try std.ChildProcess.run(.{
        .allocator = allocator,
        .argv = &.{
            "git",
            "log",
            "-z", // makes NUL byte the delimiter between commits instead of \n
            "--pretty=format:%H\n%s\n%ai",
        },
        .cwd = absolute_path,
        .max_output_bytes = 1024 * 1024 * 1000,
    });

    var commits = std.ArrayList(Commit).init(allocator);

    var commit_texts = std.mem.splitSequence(u8, result.stdout, "\x00");
    while (commit_texts.next()) |commit_text| {
        if (commit_text.len == 0) {
            continue;
        }
        var fields_iter = std.mem.splitSequence(u8, commit_text, "\n");
        try commits.append(Commit{
            .hash = fields_iter.next().?,
            .subject = fields_iter.next().?,
            .date = fields_iter.next().?,
        });
    }
    return commits.items;
}

test "listCommits" {
    const test_alloc = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(test_alloc);
    defer arena.deinit();

    // TODO: how do I mock a ChilProcess's result?
    const commits = try listCommits(arena.allocator(), "/home/nhanb/pj/boast");
    //for (commits) |c| {
    //    std.debug.print("{s} - {s} - {s}\n", .{ c.hash, c.date, c.subject });
    //}

    try std.testing.expect(commits.len > 0);
}
