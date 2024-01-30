const std = @import("std");
const HtmlBuilder = @import("./HtmlBuilder.zig");

pub fn main() !void {
    // Init arena allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa_alloc = gpa.allocator();
    var arena = std.heap.ArenaAllocator.init(gpa_alloc);
    defer arena.deinit();
    const arena_alloc = arena.allocator();

    //// Get user input as string (actually an array list)
    //std.debug.print("Input please: ", .{});
    //const stdin = std.io.getStdIn().reader();
    //var user_input = std.ArrayList(u8).init(arena_alloc);
    //try stdin.streamUntilDelimiter(user_input.writer(), '\n', null);

    const h = try HtmlBuilder.init(arena_alloc);
    var html = h.html(
        .{ .lang = "en" },
        .{
            h.head(.{}, .{
                h.meta(.{ .charset = "utf-8" }),
                h.title(.{}, .{"Hello"}),
                h.meta(.{ .name = "viewport", .content = "width=device-width, initial-scale=1.0" }),
            }),
            h.body(
                .{},
                .{"This is my body."},
            ),
        },
    );

    var argv = [_][]const u8{ "prettier", "--stdin-filepath=.html" };
    var cp = std.ChildProcess.init(&argv, arena_alloc);
    cp.stdin_behavior = .Pipe;
    cp.stdout_behavior = .Pipe;
    cp.stderr_behavior = .Pipe;

    var stdout = std.ArrayList(u8).init(arena_alloc);
    var stderr = std.ArrayList(u8).init(arena_alloc);

    try cp.spawn();

    try cp.stdin.?.writeAll(html);
    cp.stdin.?.close();
    cp.stdin = null;

    try cp.collectOutput(&stdout, &stderr, 102400);

    _ = try cp.wait();
    std.debug.print("{s}\n", .{try stdout.toOwnedSlice()});
}
