const std = @import("std");
var allocator: *const std.mem.Allocator = undefined;

const Elem = struct {
    pub fn toString(_: *Elem) []const u8 {
        return "";
    }
};
pub fn div(_: anytype, _: anytype) Elem {
    //std.debug.print("{any}", attrs);
    //std.debug.print("{any}", children);
    return .{};
}
pub fn bold(_: anytype, _: anytype) Elem {
    //std.debug.print("{any}", attrs);
    //std.debug.print("{any}", children);
    return .{};
}
pub fn text(_: []const u8) Elem {
    //std.debug.print("{any}", attrs);
    //std.debug.print("{any}", children);
    return .{};
}

test "div and b" {
    var el = div(
        .{
            .id = "foo",
            .class = "bar",
        },
        .{
            text("I like to be in"),
            bold(.{}, text("America")),
        },
    );
    std.debug.print("{s}", .{el.toString()});
}

//////////////////////////////////////////////

pub const Attr = struct {
    key: []const u8,
    val: []const u8,
};

const ChildType = enum {
    elem,
    text,
};

pub const Element = struct {
    tag: []const u8,
    attrs: []const Attr,
    children: union(ChildType) {
        elem: *Element,
        text: []const u8,
    },

    fn toString(self: Element) ![]const u8 {
        var attrs: []const u8 = "";
        for (self.attrs) |attr| {
            var old_attrs = attrs;
            defer allocator.free(old_attrs);
            const attr_str = try std.fmt.allocPrint(
                allocator.*,
                " {s}=\"{s}\"",
                .{ attr.key, attr.val },
            );
            defer allocator.free(attr_str);
            attrs = try concat(attrs, attr_str);
        }
        defer allocator.free(attrs);

        var children: []const u8 = switch (self.children) {
            ChildType.text => |value| value,
            ChildType.elem => |elem| try elem.toString(),
        };

        return std.fmt.allocPrint(allocator.*, "<{s}{s}>{s}</{s}>", .{
            self.tag,
            attrs,
            children,
            self.tag,
        });
    }
};

test "Element" {
    allocator = &std.testing.allocator;
    const attrs = [_]Attr{
        .{
            .key = "id",
            .val = "foo",
        },
        .{
            .key = "class",
            .val = "bar",
        },
    };
    const elem = Element{
        .tag = "div",
        .attrs = attrs[0..attrs.len],
        .children = .{ .text = "wow" },
    };
    const result = try elem.toString();
    defer allocator.free(result);
    try std.testing.expectEqualSlices(
        u8,
        result,
        "<div id=\"foo\" class=\"bar\">wow</div>",
    );
}

fn concat(a: []const u8, b: []const u8) ![]const u8 {
    var result = try allocator.alloc(u8, a.len + b.len);
    @memcpy(result[0..a.len], a);
    @memcpy(result[a.len..], b);
    return result;
}
test "concat" {
    allocator = &std.testing.allocator;
    const output = try concat("hello", " world");
    defer allocator.free(output);
    try std.testing.expectEqualSlices(u8, output, "hello world");
}

pub fn p(content: []const u8) ![]const u8 {
    return try std.fmt.allocPrint(allocator.*, "<p>{s}</p>", .{content});
}

test "p tag" {
    allocator = &std.testing.allocator;
    const output = try p(@as([]const u8, "hello"));
    defer allocator.free(output);
    try std.testing.expectEqualSlices(u8, output, "<p>hello</p>");
}
