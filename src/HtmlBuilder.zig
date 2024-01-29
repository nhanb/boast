//! HTML builder, inspired by the Mithril.js API. See test case for example usage.
//! Doesn't free any memory itself - intended to be used with an arena allocator that deinit()s
//! at the call site.
//! Doesn't do any escape yet, so for now don't feed it untrusted inputs.
//! Doesn't do self-closing tags yet either: TODO.
const std = @import("std");
const HtmlBuilder = @This();

allocator: std.mem.Allocator,

pub fn init(allocator: std.mem.Allocator) !HtmlBuilder {
    return HtmlBuilder{ .allocator = allocator };
}

pub fn div(self: HtmlBuilder, attributes: anytype, children: anytype) []const u8 {
    return self.el("div", attributes, children);
}

pub fn b(self: HtmlBuilder, attributes: anytype, children: anytype) []const u8 {
    return self.el("b", attributes, children);
}

pub fn el(
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

test "HttpBuilder" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arena_alloc = arena.allocator();

    const h = try HtmlBuilder.init(arena_alloc);

    const elem = h.div(
        .{
            .id = "foo",
            .class = "bar",
        },
        .{
            "This is ",
            h.b(.{}, .{"bold"}),
        },
    );
    try std.testing.expectEqualStrings(
        "<div id=\"foo\" class=\"bar\">This is <b>bold</b></div>",
        elem,
    );
}
