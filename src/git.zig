const std = @import("std");

pub fn findRepos(allocator: std.mem.Allocator, absolute_path: []const u8) ![][]const u8 {
    var repos = std.ArrayList([]const u8).init(allocator);

    var dir = try std.fs.openIterableDirAbsolute(absolute_path, .{});
    defer dir.close();

    var it = dir.iterate();
    while (try it.next()) |entry| {
        if (entry.kind != std.fs.File.Kind.directory) {
            continue;
        }

        // Skip subdir if it's not a git repo
        if (!std.mem.endsWith(u8, entry.name, ".git")) {
            var git_subfolder_path = try std.mem.concat(allocator, u8, &[_][]const u8{
                entry.name,
                std.fs.path.sep_str,
                ".git",
            });
            if (dir.dir.access(git_subfolder_path, .{})) |_| {} else |_| {
                continue;
            }
        }

        const dir_name = try allocator.dupe(u8, entry.name);
        try repos.append(dir_name);
    }

    return repos.items;
}

test "findRepos" {
    var test_allocator = std.testing.allocator;

    var arena = std.heap.ArenaAllocator.init(test_allocator);
    defer arena.deinit();
    var arena_allocator = arena.allocator();

    var repos = try findRepos(arena_allocator, "/home/nhanb/pj/");

    std.debug.print("\n", .{});
    for (repos) |path| {
        std.debug.print(">> {s}\n", .{path});
    }
}
