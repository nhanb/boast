const std = @import("std");
const html = @import("./html.zig");
const git = @import("./git.zig");

const concat = std.mem.concat;
const Allocator = std.mem.Allocator;
const allocPrint = std.fmt.allocPrint;
const ArrayList = std.ArrayList;

pub fn writeIndex(
    aa: Allocator,
    writer: anytype,
    repos: [][]const u8,
) !void {
    var h = html.Builder{ .allocator = aa };

    var repo_lis = ArrayList(html.Element).init(aa);
    for (repos) |repo| {
        try repo_lis.append(
            h.li(null, .{h.a(
                .{ .href = try concat(aa, u8, &.{ "./", repo, "/" }) },
                .{repo},
            )}),
        );
    }

    const document = h.html(
        .{ .lang = "en", .style = "font-family: monospace;" },
        .{
            h.head(null, .{
                h.title(null, .{"Boast Index"}),
                h.meta(.{ .charset = "utf-8" }),
                h.meta(.{ .name = "viewport", .content = "width=device-width, initial-scale=1.0" }),
            }),
            h.body(null, .{
                h.strong(null, .{"Repos"}),
                h.hr(null),
                h.ul(null, .{repo_lis.items}),
            }),
        },
    );
    try h.writeDoctype(&writer);
    try document.writeTo(&writer);
}

pub fn writeRepoIndex(
    aa: Allocator,
    writer: anytype,
    repo_name: []const u8,
    commits: []git.Commit,
) !void {
    var h = html.Builder{ .allocator = aa };

    var commit_lis = ArrayList(html.Element).init(aa);
    for (commits) |commit| {
        try commit_lis.append(h.li(null, .{
            commit.hash[0..10],
            " | ",
            commit.date,
            " | ",
            h.a(
                .{ .href = try concat(aa, u8, &.{ "commits/", commit.hash, ".html" }) },
                .{commit.subject},
            ),
        }));
    }

    const document = h.html(
        .{ .lang = "en", .style = "font-family: monospace;" },
        .{
            h.head(null, .{
                h.title(null, .{ repo_name, " | Boast" }),
                h.meta(.{ .charset = "utf-8" }),
                h.meta(.{ .name = "viewport", .content = "width=device-width, initial-scale=1.0" }),
            }),
            h.body(null, .{
                h.strong(null, .{
                    h.a(.{ .href = "../" }, .{"Repos"}),
                    " / ",
                    repo_name,
                }),
                h.hr(null),
                h.p(null, .{
                    "To clone this repo, run ",
                    h.code(
                        .{ .style = "background-color: gainsboro; padding: 4px;" },
                        .{"git clone <this-url>"},
                    ),
                }),
                h.p(null, .{
                    h.b(null, .{try allocPrint(aa, "{d}", .{commits.len})}),
                    " commits:",
                }),
                h.ul(null, .{commit_lis.items}),
            }),
        },
    );
    try h.writeDoctype(&writer);
    try document.writeTo(&writer);
}

pub fn writeCommit(
    aa: Allocator,
    writer: anytype,
    repo_path: []const u8,
    commit: git.Commit,
) !void {
    const text_diff = (try std.ChildProcess.run(.{
        .allocator = aa,
        .argv = &.{ "git", "show", commit.hash },
        .cwd = repo_path,
        .max_output_bytes = 1024 * 1024 * 1024,
    })).stdout;

    const repo_name = std.fs.path.basename(repo_path);

    var h = html.Builder{ .allocator = aa };
    const document = h.html(
        .{ .lang = "en", .style = "font-family: monospace;" },
        .{
            h.head(null, .{
                h.title(null, .{
                    "[",
                    commit.hash[0..10],
                    "] ",
                    commit.subject,
                    " | ",
                    repo_name,
                    " | Boast",
                }),
                h.meta(.{ .charset = "utf-8" }),
                h.meta(.{ .name = "viewport", .content = "width=device-width, initial-scale=1.0" }),
            }),
            h.body(null, .{
                h.strong(null, .{
                    h.a(.{ .href = "../.." }, .{"Repos"}),
                    " / ",
                    h.a(.{ .href = "../" }, .{repo_name}),
                    " / ",
                    commit.hash[0..10],
                }),
                h.hr(null),
                h.pre(null, .{text_diff}),
            }),
        },
    );

    try h.writeDoctype(&writer);
    try document.writeTo(&writer);
}
