const std = @import("std");
const fs = std.fs;
const Allocator = std.mem.Allocator;

pub fn copyDir(aa: Allocator, src_dir: *const fs.Dir, dest_dir: *const fs.Dir) !void {
    var walker = src_dir.walk(aa) catch unreachable;
    defer walker.deinit();
    while (walker.next() catch unreachable) |entry| {
        switch (entry.kind) {
            .file => {
                entry.dir.copyFile(
                    entry.basename,
                    dest_dir.*,
                    entry.path,
                    .{},
                ) catch unreachable;
            },
            .directory => {
                dest_dir.makePath(entry.path) catch unreachable;
            },
            else => unreachable,
        }
    }
}
