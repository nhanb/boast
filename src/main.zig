const std = @import("std");
const git = @import("./git.zig");
const pages = @import("./pages.zig");

const concat = std.mem.concat;
const ArenaAllocator = std.heap.ArenaAllocator;
const fs = std.fs;
const print = std.debug.print;
const path_sep = std.fs.path.sep_str;

pub fn main() !void {
    // Init arena allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa_alloc = gpa.allocator();
    defer if (gpa.deinit() == .leak) @panic("Memory leaked.");

    var arena = ArenaAllocator.init(gpa_alloc);
    defer arena.deinit();
    const arena_alloc = arena.allocator();

    const repos_path = "/home/nhanb/pj/";
    const output_path = "/home/nhanb/pj/boast/boast-out";

    fs.makeDirAbsolute(output_path) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };

    var timer = try std.time.Timer.start();
    defer print("Everything took {d}s\n", .{timer.read() / 1000 / 1000 / 1000});

    // Write repos index
    const repos = try git.findRepos(arena_alloc, repos_path);
    print("Processing {d} repos at {s}\n", .{ repos.len, repos_path });
    const index_path = try fs.path.join(arena_alloc, &.{ output_path, "index.html" });
    const file = try std.fs.createFileAbsolute(index_path, .{});
    defer file.close();
    try pages.writeIndex(arena_alloc, file.writer(), repos);

    // Write repo commits
    var thread_pool: std.Thread.Pool = undefined;
    try thread_pool.init(.{ .allocator = arena_alloc });
    defer thread_pool.deinit();
    for (repos) |repo| {
        try thread_pool.spawn(processRepo, .{ repos_path, output_path, repo });
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
        const repo_index_file = std.fs.createFileAbsolute(file_path, .{}) catch unreachable;
        defer repo_index_file.close();
        pages.writeRepoIndex(
            raa,
            repo_index_file.writer(),
            repo,
            commits,
        ) catch unreachable;
    }

    // Create commit files
    const commits_dir_path = fs.path.join(raa, &.{ out_repo_path, "commits" }) catch unreachable;
    fs.makeDirAbsolute(commits_dir_path) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => unreachable,
    };
    for (commits) |commit| {
        const file_path = concat(raa, u8, &.{
            commits_dir_path,
            path_sep,
            commit.hash,
            ".html",
        }) catch unreachable;
        const file = std.fs.createFileAbsolute(file_path, .{}) catch unreachable;
        defer file.close();

        pages.writeCommit(
            raa,
            file,
            repo_path,
            commit,
        ) catch unreachable;
    }
}
