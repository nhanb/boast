const std = @import("std");

pub const Element = struct {
    tag: []const u8 = "",
    text: []const u8 = "",

    attrs: []const Attr = &[0]Attr{},
    children: ?[]const Element = &[0]Element{},
};

//pub const A = makeTag("a", true);
//pub const Div = makeTag("div", true);
//fn makeTag(name: []const u8, is_void: bool) type {
//    return @Type(.{
//        .Struct = .{
//            .layout = .Auto,
//            .fields = &[_]std.builtin.TypeInfo.StructField{},
//            .decls = &[_]std.builtin.TypeInfo.Declaration{},
//            .is_tuple = false,
//        }
//    });
//}

pub const Attr = struct { []const u8, []const u8 };

fn escape(allocator: std.mem.Allocator, attr: []const u8) []const u8 {
    var escaped: []u8 = undefined;
    var unescaped: []const u8 = attr;
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
        const size = std.mem.replacementSize(u8, unescaped, needle, replacement);
        escaped = allocator.alloc(u8, size) catch unreachable;
        _ = std.mem.replace(u8, unescaped, needle, replacement, escaped);
        unescaped = escaped;
    }
    return escaped;
}

test "Builder" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    var b = Builder{ .allocator = arena.allocator() };

    const elem = Element{
        .tag = "div",
        .attrs = &.{
            .{ "id", "foo" },
            .{ "escapes", "\" ' < > &" },
        },
        .children = &.{
            .{ .text = "This is " },
            .{
                .tag = "b",
                .children = &.{.{ .text = "bold" }},
            },
            .{ .tag = "hr", .children = null },
        },
    };

    var out = std.ArrayList(u8).init(std.testing.allocator);
    defer out.deinit();

    try b.write(elem, out.writer());

    // This frees the html builder's resources but doesn't affect `out`
    arena.deinit();

    try std.testing.expectEqualStrings(
        \\<div id="foo" escapes="&quot; &#39; &lt; &gt; &amp;">This is <b>bold</b><hr></div>
    , out.items);
}

pub const Builder = struct {
    allocator: std.mem.Allocator,

    pub fn write(self: Builder, element: Element, writer: anytype) !void {
        if (!std.mem.eql(u8, element.text, "")) {
            try writer.writeAll(escape(self.allocator, element.text));
            return;
        }

        try writer.writeAll("<");
        try writer.writeAll(element.tag);
        for (element.attrs) |attr| {
            const name = escape(self.allocator, attr[0]);
            const value = escape(self.allocator, attr[1]);
            try writer.writeAll(" ");
            try writer.writeAll(name);
            try writer.writeAll("=\"");
            try writer.writeAll(value);
            try writer.writeAll("\"");
        }
        try writer.writeAll(">");

        if (element.children) |children| {
            for (children) |child| {
                try self.write(child, writer);
            }

            try writer.writeAll("</");
            try writer.writeAll(element.tag);
            try writer.writeAll(">");
        }
    }
};

const tags: struct {
    []const u8, // tag name
    bool, // is void element?
} = .{
    .{ "area", true },
    .{ "base", true },
    .{ "br", true },
    .{ "col", true },
    .{ "embed", true },
    .{ "hr", true },
    .{ "img", true },
    .{ "input", true },
    .{ "link", true },
    .{ "meta", true },
    .{ "source", true },
    .{ "track", true },
    .{ "wbr", true },

    .{ "a", false },
    .{ "abbr", false },
    .{ "acronym", false },
    .{ "address", false },
    .{ "article", false },
    .{ "aside", false },
    .{ "audio", false },
    .{ "b", false },
    .{ "bdi", false },
    .{ "bdo", false },
    .{ "big", false },
    .{ "blockquote", false },
    .{ "body", false },
    .{ "button", false },
    .{ "canvas", false },
    .{ "caption", false },
    .{ "center", false },
    .{ "cite", false },
    .{ "code", false },
    .{ "colgroup", false },
    .{ "data", false },
    .{ "datalist", false },
    .{ "dd", false },
    .{ "del", false },
    .{ "details", false },
    .{ "dfn", false },
    .{ "dialog", false },
    .{ "dir", false },
    .{ "div", false },
    .{ "dl", false },
    .{ "dt", false },
    .{ "em", false },
    .{ "fieldset", false },
    .{ "figcaption", false },
    .{ "figure", false },
    .{ "font", false },
    .{ "footer", false },
    .{ "form", false },
    .{ "frame", false },
    .{ "frameset", false },
    .{ "h1", false },
    .{ "head", false },
    .{ "header", false },
    .{ "hgroup", false },
    .{ "html", false },
    .{ "i", false },
    .{ "iframe", false },
    .{ "image", false },
    .{ "ins", false },
    .{ "kbd", false },
    .{ "label", false },
    .{ "legend", false },
    .{ "li", false },
    .{ "main", false },
    .{ "map", false },
    .{ "mark", false },
    .{ "marquee", false },
    .{ "menu", false },
    .{ "menuitem", false },
    .{ "meter", false },
    .{ "nav", false },
    .{ "nobr", false },
    .{ "noembed", false },
    .{ "noframes", false },
    .{ "noscript", false },
    .{ "object", false },
    .{ "ol", false },
    .{ "optgroup", false },
    .{ "option", false },
    .{ "output", false },
    .{ "p", false },
    .{ "param", false },
    .{ "picture", false },
    .{ "plaintext", false },
    .{ "portal", false },
    .{ "pre", false },
    .{ "progress", false },
    .{ "q", false },
    .{ "rb", false },
    .{ "rp", false },
    .{ "rt", false },
    .{ "rtc", false },
    .{ "ruby", false },
    .{ "s", false },
    .{ "samp", false },
    .{ "script", false },
    .{ "search", false },
    .{ "section", false },
    .{ "select", false },
    .{ "slot", false },
    .{ "small", false },
    .{ "span", false },
    .{ "strike", false },
    .{ "strong", false },
    .{ "style", false },
    .{ "sub", false },
    .{ "summary", false },
    .{ "sup", false },
    .{ "table", false },
    .{ "tbody", false },
    .{ "td", false },
    .{ "template", false },
    .{ "textarea", false },
    .{ "tfoot", false },
    .{ "th", false },
    .{ "thead", false },
    .{ "time", false },
    .{ "title", false },
    .{ "tr", false },
    .{ "tt", false },
    .{ "u", false },
    .{ "ul", false },
    .{ "var", false },
    .{ "video", false },
    .{ "xmp", false },
};
