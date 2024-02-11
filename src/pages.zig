const std = @import("std");
const html = @import("./html.zig");
const git = @import("./git.zig");

const concat = std.mem.concat;
const Allocator = std.mem.Allocator;
const allocPrint = std.fmt.allocPrint;
const ArrayList = std.ArrayList;

const TemplateArgs = struct {
    builder: html.Builder,
    title: html.Element,
    breadcrumbs: struct {
        urls: []const struct {
            href: []const u8,
            text: []const u8,
        } = &.{},
        current: []const u8,
    },
    main: html.Element,
};

pub fn applyTemplate(args: TemplateArgs) html.Element {
    const h = args.builder;
    var breadcrumbs_anchors = ArrayList(html.Child).init(h.allocator);
    for (args.breadcrumbs.urls) |url| {
        breadcrumbs_anchors.append(.{ .elem = h.a(
            .{ .href = url.href },
            .{url.text},
        ) }) catch unreachable;
        breadcrumbs_anchors.append(.{ .text = " / " }) catch unreachable;
    }

    return h.html(
        .{ .lang = "en", .style = "font-family: monospace;" },
        .{
            h.head(null, .{
                args.title,
                h.meta(.{ .charset = "utf-8" }),
                h.meta(.{ .name = "viewport", .content = "width=device-width, initial-scale=1.0" }),
            }),
            h.body(null, .{
                h.b(null, .{
                    breadcrumbs_anchors.items,
                    args.breadcrumbs.current,
                }),
                h.hr(null),
                args.main,
            }),
        },
    );
}

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

    const document = applyTemplate(.{
        .builder = h,
        .title = h.title(null, .{"Boast Index"}),
        .breadcrumbs = .{
            .current = "Repos",
        },
        .main = h.ul(null, .{repo_lis.items}),
    });

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

    const document = applyTemplate(.{
        .builder = h,
        .title = h.title(null, .{ repo_name, " | Boast" }),
        .breadcrumbs = .{
            .urls = &.{
                .{ .href = "../", .text = "Repos" },
            },
            .current = repo_name,
        },
        .main = h.main(null, .{
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
    });

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

    const document = applyTemplate(.{
        .builder = h,
        .title = h.title(null, .{
            "[",
            commit.hash[0..10],
            "] ",
            commit.subject,
            " | ",
            repo_name,
            " | Boast",
        }),
        .breadcrumbs = .{
            .urls = &.{
                .{ .href = "../../", .text = "Repos" },
                .{ .href = "../", .text = repo_name },
            },
            .current = commit.hash[0..10],
        },
        .main = h.pre(null, .{text_diff}),
    });

    try h.writeDoctype(&writer);
    try document.writeTo(&writer);
}
