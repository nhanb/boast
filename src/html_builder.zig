const std = @import("std");

const HtmlBuilder = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !HtmlBuilder {
        return HtmlBuilder{ .allocator = allocator };
    }

    pub fn Div(self: HtmlBuilder, attributes: anytype, _: anytype) !Element {
        var el = try Element.init(self.allocator, "div");

        inline for (@typeInfo(@TypeOf(attributes)).Struct.fields) |field| {
            try el.attrs.put(field.name, @field(attributes, field.name));
        }

        //inline for (children) |child| {

        //}

        return el;
    }

    pub fn B(self: HtmlBuilder, _: anytype, _: anytype) !Element {
        const el = try Element.init(self.allocator, "b");
        return el;
    }
};

const ChildType = enum {
    elem,
    text,
};

pub const Element = struct {
    allocator: std.mem.Allocator,
    tag: []const u8,
    attrs: std.StringHashMap([]const u8),
    children: union(ChildType) {
        elem: *Element,
        text: []const u8,
    },

    pub fn init(alloc: std.mem.Allocator, tag: []const u8) !Element {
        return .{
            .allocator = alloc,
            .tag = tag,
            .attrs = std.StringHashMap([]const u8).init(alloc),
            .children = .{ .text = "" },
        };
    }

    fn toString(self: Element) ![]const u8 {
        var attrs: []const u8 = "";
        var it = self.attrs.iterator();
        while (it.next()) |kv| {
            var old_attrs = attrs;
            defer self.allocator.free(old_attrs);
            const attr_str = try std.fmt.allocPrint(
                self.allocator,
                " {s}=\"{s}\"",
                .{ kv.key_ptr.*, kv.value_ptr.* },
            );
            defer self.allocator.free(attr_str);
            attrs = try concat(self.allocator, attrs, attr_str);
        }
        defer self.allocator.free(attrs);

        var children: []const u8 = switch (self.children) {
            ChildType.text => |value| value,
            ChildType.elem => |elem| try elem.toString(),
        };

        return std.fmt.allocPrint(self.allocator, "<{s}{s}>{s}</{s}>", .{
            self.tag,
            attrs,
            children,
            self.tag,
        });
    }
};

test "Element" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const gpa_alloc = gpa.allocator();
    var arena = std.heap.ArenaAllocator.init(gpa_alloc);
    defer arena.deinit();
    const arena_alloc = arena.allocator();

    const h = try HtmlBuilder.init(arena_alloc);

    const elem = try h.Div(.{
        .id = "foo",
        .class = "bar",
    }, .{
        "This is ",
        h.B(.{}, "bold"),
    });
    const result = try elem.toString();
    try std.testing.expectEqualStrings(
        "<div id=\"foo\" class=\"bar\">This is <b>bold</b></div>",
        result,
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
