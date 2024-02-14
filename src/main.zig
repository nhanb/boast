const std = @import("std");
const git = @import("./git.zig");
const pages = @import("./pages.zig");
const utils = @import("./utils.zig");

const concat = std.mem.concat;
const ArenaAllocator = std.heap.ArenaAllocator;
const fs = std.fs;
const print = std.debug.print;

var cpu_count: usize = undefined;
const num_concurrent_repos = 2;

pub fn main() !void {
    var timer = try std.time.Timer.start();
    defer print("Everything took {d}s\n", .{timer.read() / 1_000_000_000});

    cpu_count = std.Thread.getCpuCount() catch unreachable;

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa_alloc = gpa.allocator();
    defer if (gpa.deinit() == .leak) @panic("Memory leaked.");
    var arena = ArenaAllocator.init(gpa_alloc);
    defer arena.deinit();
    const arena_alloc = arena.allocator();

    const args = try std.process.argsAlloc(arena_alloc);
    defer std.process.argsFree(arena_alloc, args);
    if (args.len != 3) {
        print("Usage: boast <repos-path> <output-path>\n", .{});
        std.os.exit(1);
    }

    var src_dir = try fs.cwd().openDir(args[1], .{});
    defer src_dir.close();
    var dest_dir = try fs.cwd().makeOpenPath(args[2], .{});
    defer dest_dir.close();
    const src_abs_path = try src_dir.realpathAlloc(arena_alloc, ".");
    const dest_abs_path = try dest_dir.realpathAlloc(arena_alloc, ".");
    print("Source: {s}\n", .{src_abs_path});
    print("Dest  : {s}\n", .{dest_abs_path});

    // Write repos index
    const repos = try git.findRepos(arena_alloc, src_abs_path);
    print("Found {d} repos\n", .{repos.len});
    const index_path = try fs.path.join(arena_alloc, &.{ dest_abs_path, "index.html" });
    const file = try fs.createFileAbsolute(index_path, .{});
    defer file.close();
    try pages.writeIndex(arena_alloc, file.writer(), repos);

    // Write repo commits
    var thread_pool: std.Thread.Pool = undefined;
    try thread_pool.init(.{ .allocator = arena_alloc, .n_jobs = num_concurrent_repos });
    defer thread_pool.deinit();
    for (repos) |repo| {
        try thread_pool.spawn(processRepo, .{ src_abs_path, dest_abs_path, repo });
    }
}

fn processRepo(
    repos_path: []const u8,
    output_path: []const u8,
    repo: []const u8,
) void {
    //print("Repo {s}...\n", .{repo});
    var repo_timer = std.time.Timer.start() catch unreachable;
    defer print(">> {s} took {d}ms\n", .{ repo, repo_timer.read() / 1000 / 1000 });

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa_alloc = gpa.allocator();
    defer if (gpa.deinit() == .leak) @panic("Memory leaked.");
    var repo_arena = ArenaAllocator.init(gpa_alloc);
    defer repo_arena.deinit();
    const raa = repo_arena.allocator();

    const repo_path = fs.path.join(raa, &.{ repos_path, repo }) catch unreachable;

    // Make sure output dir exists
    const out_repo_path = fs.path.join(raa, &.{ output_path, repo }) catch unreachable;
    fs.makeDirAbsolute(out_repo_path) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => unreachable,
    };

    const commits = git.listCommits(raa, repo_path) catch unreachable;

    {
        // Create repo index file
        const file_path = fs.path.join(raa, &.{ out_repo_path, "index.html" }) catch unreachable;
        const repo_index_file = fs.createFileAbsolute(file_path, .{}) catch unreachable;
        defer repo_index_file.close();
        pages.writeRepoIndex(
            raa,
            repo_index_file.writer(),
            repo,
            commits,
        ) catch unreachable;
    }

    {
        // Prepare data for git clones over dumb http protocol

        // Generate [.git/]info/refs in source repo
        _ = std.ChildProcess.run(.{
            .allocator = raa,
            .argv = &.{ "git", "update-server-info" },
            .cwd = repo_path,
        }) catch unreachable;

        // Copy over just the necessary data:
        // - info/refs
        // - HEAD
        // - objects/

        var src_repo_path = repo_path;
        if (!std.mem.endsWith(u8, repo_path, ".git")) {
            src_repo_path = fs.path.join(raa, &.{ src_repo_path, ".git" }) catch unreachable;
        }

        const src_dir = fs.openDirAbsolute(src_repo_path, .{ .iterate = true }) catch unreachable;
        const dest_dir = fs.openDirAbsolute(out_repo_path, .{ .iterate = true }) catch unreachable;

        // info/refs
        dest_dir.makePath("info") catch unreachable;
        const refs_path = fs.path.join(raa, &.{ "info", "refs" }) catch unreachable;
        src_dir.copyFile(refs_path, dest_dir, refs_path, .{}) catch unreachable;

        // HEAD
        src_dir.copyFile("HEAD", dest_dir, "HEAD", .{}) catch unreachable;

        // objects/
        const src_objects_dir = src_dir.openDir("objects", .{ .iterate = true }) catch unreachable;
        const dest_objects_dir = dest_dir.makeOpenPath("objects", .{}) catch unreachable;
        utils.copyDir(raa, &src_objects_dir, &dest_objects_dir) catch unreachable;
    }

    // Create commit files
    const commits_dir_path = fs.path.join(raa, &.{ out_repo_path, "commits" }) catch unreachable;
    fs.makeDirAbsolute(commits_dir_path) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => unreachable,
    };
    var thread_pool: std.Thread.Pool = undefined;
    thread_pool.init(.{
        .allocator = raa,
        .n_jobs = @intCast(@max(1, cpu_count / num_concurrent_repos)),
    }) catch unreachable;
    defer thread_pool.deinit();
    for (commits) |commit| {
        thread_pool.spawn(
            processCommit,
            .{ commits_dir_path, repo_path, commit },
        ) catch unreachable;
    }
}

fn processCommit(
    commits_dir_path: []const u8,
    repo_path: []const u8,
    commit: git.Commit,
) void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa_alloc = gpa.allocator();
    defer if (gpa.deinit() == .leak) @panic("Memory leaked.");
    var arena = ArenaAllocator.init(gpa_alloc);
    defer arena.deinit();
    const aa = arena.allocator();

    const file_path = concat(aa, u8, &.{
        commits_dir_path,
        fs.path.sep_str,
        commit.hash,
        ".html",
    }) catch unreachable;
    const file = fs.createFileAbsolute(file_path, .{}) catch unreachable;
    defer file.close();

    pages.writeCommit(
        aa,
        file,
        repo_path,
        commit,
    ) catch unreachable;
}
