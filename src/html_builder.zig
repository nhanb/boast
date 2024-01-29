const std = @import("std");

pub const HtmlBuilder = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !HtmlBuilder {
        return HtmlBuilder{ .allocator = allocator };
    }

    pub fn El(
        self: HtmlBuilder,
        comptime tag: []const u8,
        attributes: anytype,
        children: anytype,
    ) []const u8 {
        var result = std.ArrayList(u8).init(self.allocator);
        var writer = result.writer();

        // Tag opening + attributes
        writer.writeAll("<" ++ tag) catch unreachable;
        inline for (@typeInfo(@TypeOf(attributes)).Struct.fields) |field| {
            writer.writeAll(
                " " ++
                    field.name ++
                    "=\"" ++
                    @field(attributes, field.name) ++
                    "\"",
            ) catch unreachable;
        }
        writer.writeAll(">") catch unreachable;

        // Children
        inline for (children) |child| {
            writer.writeAll(@as([]const u8, child)) catch unreachable;
        }

        // Tag closing
        writer.writeAll("</" ++ tag ++ ">") catch unreachable;

        return result.items;
    }
};

test "Element" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arena_alloc = arena.allocator();

    const h = try HtmlBuilder.init(arena_alloc);

    const elem = h.El(
        "div",
        .{
            .id = "foo",
            .class = "bar",
        },
        .{
            "This is ",
            h.El("b", .{}, .{"bold"}),
        },
    );
    try std.testing.expectEqualStrings(
        "<div id=\"foo\" class=\"bar\">This is <b>bold</b></div>",
        elem,
    );
}

fn concat(allocator: std.mem.Allocator, a: []const u8, b: []const u8) ![]const u8 {
    var result = try allocator.alloc(u8, a.len + b.len);
    @memcpy(result[0..a.len], a);
    @memcpy(result[a.len..], b);
    return result;
}
test "concat" {
    const allocator = std.testing.allocator;
    const output = try concat(allocator, "hello", " world");
    defer allocator.free(output);
    try std.testing.expectEqualSlices(u8, output, "hello world");
}
