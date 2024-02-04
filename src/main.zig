const std = @import("std");
const html = @import("./html.zig");

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

    const b = html.Builder{ .allocator = arena_alloc };
    var document = b.html(
        .{ .lang = "en" },
        .{
            b.head(.{}, .{
                b.meta(.{ .charset = "utf-8" }),
                b.title(.{}, .{"Hello'"}),
                b.meta(.{ .name = "viewport", .content = "width=device-width, initial-scale=1.0" }),
            }),
            b.body(
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

    try document.writeTo(cp.stdin.?.writer());
    cp.stdin.?.close();
    cp.stdin = null;

    try cp.collectOutput(&stdout, &stderr, 102400);

    _ = try cp.wait();
    std.debug.print("{s}\n", .{try stdout.toOwnedSlice()});
}
