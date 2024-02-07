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

    const repos_path = "/home/nhanb/pj/boast/boast-repos";
    const output_path = "/home/nhanb/pj/boast/boast-out";

    fs.makeDirAbsolute(output_path) catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };

    var timer = try std.time.Timer.start();
    defer print("Everything took {d}s\n", .{timer.read() / 1000 / 1000 / 1000});

    // Write repos index
    const repos = try git.findRepos(arena_alloc, repos_path);
    const index_path = try fs.path.join(arena_alloc, &.{ output_path, "index.html" });
    const file = try std.fs.createFileAbsolute(index_path, .{});
    defer file.close();
    try pages.writeIndex(std.fs.File.Writer, arena_alloc, file.writer(), repos);

    for (repos) |repo| {
        print("Repo {s}...", .{repo});
        var repo_timer = try std.time.Timer.start();
        defer print(" took {d}ms\n", .{repo_timer.read() / 1000 / 1000});

        var repo_arena = ArenaAllocator.init(gpa_alloc);
        defer repo_arena.deinit();
        const raa = repo_arena.allocator();

        const repo_path = try fs.path.join(raa, &.{ repos_path, repo });

        // Make sure output dir exists
        const out_repo_path = try fs.path.join(raa, &.{ output_path, repo });
        fs.makeDirAbsolute(out_repo_path) catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };

        const commits = try git.listCommits(raa, repo_path);

        {
            // Create repo index file
            const file_path = try fs.path.join(raa, &.{ out_repo_path, "index.html" });
            const repo_index_file = try std.fs.createFileAbsolute(file_path, .{});
            defer repo_index_file.close();
            try pages.writeRepoIndex(
                std.fs.File.Writer,
                raa,
                repo_index_file.writer(),
                repo,
                commits,
            );
        }

        // Create commit files
        const commits_dir_path = try fs.path.join(raa, &.{ out_repo_path, "commits" });
        fs.makeDirAbsolute(commits_dir_path) catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return err,
        };
        for (commits) |commit| {
            const text_file_path = try concat(raa, u8, &.{
                commits_dir_path,
                path_sep,
                commit.hash,
                ".patch",
            });
            const text_file = try std.fs.createFileAbsolute(text_file_path, .{});
            defer text_file.close();

            const html_file_path = try concat(raa, u8, &.{
                commits_dir_path,
                path_sep,
                commit.hash,
                ".html",
            });
            const html_file = try std.fs.createFileAbsolute(html_file_path, .{});
            defer html_file.close();

            try pages.writeCommit(
                raa,
                text_file,
                html_file,
                repo_path,
                commit.hash,
            );
        }
    }
}
