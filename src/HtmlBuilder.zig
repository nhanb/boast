//! HTML builder, inspired by the Mithril.js API. See test case for example usage.
//! Doesn't free any memory itself - intended to be used with an arena allocator that deinit()s
//! at the call site.
const std = @import("std");
const HtmlBuilder = @This();

const Element = []const u8;

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

pub fn hr(self: HtmlBuilder, attributes: anytype) []const u8 {
    return self.el("hr", attributes, null);
}

pub fn el(
    self: HtmlBuilder,
    comptime tag: []const u8,
    attributes: anytype,
    children: anytype,
) Element {
    var result = std.ArrayList(u8).init(self.allocator);
    var writer = result.writer();

    // Tag opening + attributes
    writer.writeAll("<" ++ tag) catch unreachable;
    inline for (@typeInfo(@TypeOf(attributes)).Struct.fields) |field| {
        writer.writeAll(" " ++ field.name ++ "=\"") catch unreachable;
        writer.writeAll(self.escape(@field(attributes, field.name))) catch unreachable;
        writer.writeAll("\"") catch unreachable;
    }
    writer.writeAll(">") catch unreachable;

    if (@TypeOf(children) == @TypeOf(null)) {
        return result.items; // is a void element a.k.a. self-closing
    }

    // Children
    inline for (children) |child| {
        var child_str = @as([]const u8, child);
        if (@TypeOf(child) != Element) {
            child_str = self.escape(child_str);
        }
        writer.writeAll(child_str) catch unreachable;
    }

    // Tag closing
    writer.writeAll("</" ++ tag ++ ">") catch unreachable;

    return result.items;
}

fn escape(self: HtmlBuilder, attr: []const u8) []const u8 {
    var output: []u8 = undefined;
    var input: []const u8 = attr;
    inline for (.{
        "&",
        "\"",
        "'",
        "<",
        ">",
    }, .{
        "&amp;",
        "&quot;",
        "&#39;",
        "&lt;",
        "&gt;",
    }) |needle, replacement| {
        const size = std.mem.replacementSize(u8, input, needle, replacement);
        output = self.allocator.alloc(u8, size) catch unreachable;
        _ = std.mem.replace(u8, input, needle, replacement, output);
        input = output;
    }
    return output;
}

test "HttpBuilder" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const arena_alloc = arena.allocator();

    const h = try HtmlBuilder.init(arena_alloc);

    const elem = h.div(
        .{
            .id = "foo",
            .escapes = "\" ' < > &",
        },
        .{
            "This is ",
            h.b(.{}, .{"bold"}),
            h.hr(.{}),
        },
    );
    try std.testing.expectEqualStrings(
        \\<div id="foo" escapes="&quot; &#39; &lt; &gt; &amp;">This is <b>bold</b><hr></div>
    ,
        elem,
    );
}
