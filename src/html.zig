const std = @import("std");

const Element = struct {
    allocator: std.mem.Allocator,
    tag: []const u8,
    attrs: []Attr,
    children: ?[]const Child,

    pub fn writeTo(self: Element, writer: anytype) !void {
        try writer.writeAll("<");
        try writer.writeAll(self.tag);
        for (self.attrs) |attr| {
            const name = escape(self.allocator, attr[0]);
            const value = escape(self.allocator, attr[1]);
            try writer.writeAll(" ");
            try writer.writeAll(name);
            try writer.writeAll("=\"");
            try writer.writeAll(value);
            try writer.writeAll("\"");
        }
        try writer.writeAll(">");

        if (self.children) |children| {
            for (children) |child| {
                switch (child) {
                    Child.elem => |elem| try elem.writeTo(writer),
                    Child.text => |text| try writer.writeAll(escape(self.allocator, text)),
                }
            }

            try writer.writeAll("</");
            try writer.writeAll(self.tag);
            try writer.writeAll(">");
        }
    }
};

const Attr = struct { []const u8, []const u8 };

const Child = union(enum) {
    elem: Element,
    text: []const u8,
};

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
    const elem = b.div(
        .{
            .id = "foo",
            .escapes = "\" ' < > &",
        },
        .{
            "This is ",
            b.b(.{}, .{"bold"}),
            b.hr(.{}),
        },
    );

    var out = std.ArrayList(u8).init(std.testing.allocator);
    defer out.deinit();

    try elem.writeTo(out.writer());

    // This frees the html builder's resources but doesn't affect `out`
    arena.deinit();

    try std.testing.expectEqualStrings(
        \\<div id="foo" escapes="&quot; &#39; &lt; &gt; &amp;">This is <b>bold</b><hr></div>
    , out.items);
}

pub const Builder = struct {
    allocator: std.mem.Allocator,

    pub fn el(
        self: Builder,
        comptime tag: []const u8,
        attributes: anytype,
        children: anytype,
    ) Element {
        const attr_fields = @typeInfo(@TypeOf(attributes)).Struct.fields;
        var attrs = self.allocator.alloc(Attr, attr_fields.len) catch unreachable;
        inline for (attr_fields, 0..) |field, idx| {
            attrs[idx] = Attr{ field.name, @field(attributes, field.name) };
        }

        var elem = Element{
            .allocator = self.allocator,
            .tag = tag,
            .attrs = attrs,
            .children = null,
        };

        if (@TypeOf(children) != @TypeOf(null)) {
            var childs = self.allocator.alloc(Child, children.len) catch unreachable;
            inline for (children, 0..) |child, idx| {
                if (@TypeOf(child) == Element) {
                    childs[idx] = Child{ .elem = child };
                } else {
                    childs[idx] = Child{ .text = child };
                }
            }
            elem.children = childs;
        }

        return elem;
    }

    // The following is generate_html_tags.py's output

    pub fn area(self: Builder, attributes: anytype) Element {
        return self.el("area", attributes, null);
    }

    pub fn base(self: Builder, attributes: anytype) Element {
        return self.el("base", attributes, null);
    }

    pub fn br(self: Builder, attributes: anytype) Element {
        return self.el("br", attributes, null);
    }

    pub fn col(self: Builder, attributes: anytype) Element {
        return self.el("col", attributes, null);
    }

    pub fn embed(self: Builder, attributes: anytype) Element {
        return self.el("embed", attributes, null);
    }

    pub fn hr(self: Builder, attributes: anytype) Element {
        return self.el("hr", attributes, null);
    }

    pub fn img(self: Builder, attributes: anytype) Element {
        return self.el("img", attributes, null);
    }

    pub fn input(self: Builder, attributes: anytype) Element {
        return self.el("input", attributes, null);
    }

    pub fn link(self: Builder, attributes: anytype) Element {
        return self.el("link", attributes, null);
    }

    pub fn meta(self: Builder, attributes: anytype) Element {
        return self.el("meta", attributes, null);
    }

    pub fn source(self: Builder, attributes: anytype) Element {
        return self.el("source", attributes, null);
    }

    pub fn track(self: Builder, attributes: anytype) Element {
        return self.el("track", attributes, null);
    }

    pub fn wbr(self: Builder, attributes: anytype) Element {
        return self.el("wbr", attributes, null);
    }

    pub fn a(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("a", attributes, children);
    }

    pub fn abbr(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("abbr", attributes, children);
    }

    pub fn acronym(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("acronym", attributes, children);
    }

    pub fn address(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("address", attributes, children);
    }

    pub fn article(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("article", attributes, children);
    }

    pub fn aside(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("aside", attributes, children);
    }

    pub fn audio(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("audio", attributes, children);
    }

    pub fn b(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("b", attributes, children);
    }

    pub fn bdi(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("bdi", attributes, children);
    }

    pub fn bdo(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("bdo", attributes, children);
    }

    pub fn big(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("big", attributes, children);
    }

    pub fn blockquote(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("blockquote", attributes, children);
    }

    pub fn body(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("body", attributes, children);
    }

    pub fn button(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("button", attributes, children);
    }

    pub fn canvas(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("canvas", attributes, children);
    }

    pub fn caption(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("caption", attributes, children);
    }

    pub fn center(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("center", attributes, children);
    }

    pub fn cite(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("cite", attributes, children);
    }

    pub fn code(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("code", attributes, children);
    }

    pub fn colgroup(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("colgroup", attributes, children);
    }

    pub fn data(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("data", attributes, children);
    }

    pub fn datalist(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("datalist", attributes, children);
    }

    pub fn dd(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("dd", attributes, children);
    }

    pub fn del(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("del", attributes, children);
    }

    pub fn details(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("details", attributes, children);
    }

    pub fn dfn(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("dfn", attributes, children);
    }

    pub fn dialog(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("dialog", attributes, children);
    }

    pub fn dir(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("dir", attributes, children);
    }

    pub fn div(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("div", attributes, children);
    }

    pub fn dl(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("dl", attributes, children);
    }

    pub fn dt(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("dt", attributes, children);
    }

    pub fn em(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("em", attributes, children);
    }

    pub fn fieldset(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("fieldset", attributes, children);
    }

    pub fn figcaption(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("figcaption", attributes, children);
    }

    pub fn figure(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("figure", attributes, children);
    }

    pub fn font(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("font", attributes, children);
    }

    pub fn footer(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("footer", attributes, children);
    }

    pub fn form(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("form", attributes, children);
    }

    pub fn frame(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("frame", attributes, children);
    }

    pub fn frameset(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("frameset", attributes, children);
    }

    pub fn h1(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("h1", attributes, children);
    }

    pub fn head(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("head", attributes, children);
    }

    pub fn header(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("header", attributes, children);
    }

    pub fn hgroup(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("hgroup", attributes, children);
    }

    pub fn html(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("html", attributes, children);
    }

    pub fn i(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("i", attributes, children);
    }

    pub fn iframe(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("iframe", attributes, children);
    }

    pub fn image(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("image", attributes, children);
    }

    pub fn ins(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("ins", attributes, children);
    }

    pub fn kbd(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("kbd", attributes, children);
    }

    pub fn label(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("label", attributes, children);
    }

    pub fn legend(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("legend", attributes, children);
    }

    pub fn li(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("li", attributes, children);
    }

    pub fn main(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("main", attributes, children);
    }

    pub fn map(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("map", attributes, children);
    }

    pub fn mark(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("mark", attributes, children);
    }

    pub fn marquee(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("marquee", attributes, children);
    }

    pub fn menu(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("menu", attributes, children);
    }

    pub fn menuitem(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("menuitem", attributes, children);
    }

    pub fn meter(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("meter", attributes, children);
    }

    pub fn nav(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("nav", attributes, children);
    }

    pub fn nobr(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("nobr", attributes, children);
    }

    pub fn noembed(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("noembed", attributes, children);
    }

    pub fn noframes(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("noframes", attributes, children);
    }

    pub fn noscript(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("noscript", attributes, children);
    }

    pub fn object(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("object", attributes, children);
    }

    pub fn ol(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("ol", attributes, children);
    }

    pub fn optgroup(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("optgroup", attributes, children);
    }

    pub fn option(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("option", attributes, children);
    }

    pub fn output(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("output", attributes, children);
    }

    pub fn p(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("p", attributes, children);
    }

    pub fn param(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("param", attributes, children);
    }

    pub fn picture(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("picture", attributes, children);
    }

    pub fn plaintext(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("plaintext", attributes, children);
    }

    pub fn portal(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("portal", attributes, children);
    }

    pub fn pre(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("pre", attributes, children);
    }

    pub fn progress(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("progress", attributes, children);
    }

    pub fn q(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("q", attributes, children);
    }

    pub fn rb(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("rb", attributes, children);
    }

    pub fn rp(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("rp", attributes, children);
    }

    pub fn rt(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("rt", attributes, children);
    }

    pub fn rtc(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("rtc", attributes, children);
    }

    pub fn ruby(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("ruby", attributes, children);
    }

    pub fn s(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("s", attributes, children);
    }

    pub fn samp(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("samp", attributes, children);
    }

    pub fn script(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("script", attributes, children);
    }

    pub fn search(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("search", attributes, children);
    }

    pub fn section(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("section", attributes, children);
    }

    pub fn select(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("select", attributes, children);
    }

    pub fn slot(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("slot", attributes, children);
    }

    pub fn small(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("small", attributes, children);
    }

    pub fn span(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("span", attributes, children);
    }

    pub fn strike(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("strike", attributes, children);
    }

    pub fn strong(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("strong", attributes, children);
    }

    pub fn style(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("style", attributes, children);
    }

    pub fn sub(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("sub", attributes, children);
    }

    pub fn summary(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("summary", attributes, children);
    }

    pub fn sup(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("sup", attributes, children);
    }

    pub fn table(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("table", attributes, children);
    }

    pub fn tbody(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("tbody", attributes, children);
    }

    pub fn td(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("td", attributes, children);
    }

    pub fn template(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("template", attributes, children);
    }

    pub fn textarea(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("textarea", attributes, children);
    }

    pub fn tfoot(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("tfoot", attributes, children);
    }

    pub fn th(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("th", attributes, children);
    }

    pub fn thead(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("thead", attributes, children);
    }

    pub fn time(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("time", attributes, children);
    }

    pub fn title(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("title", attributes, children);
    }

    pub fn tr(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("tr", attributes, children);
    }

    pub fn tt(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("tt", attributes, children);
    }

    pub fn u(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("u", attributes, children);
    }

    pub fn ul(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("ul", attributes, children);
    }

    pub fn @"var"(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("var", attributes, children);
    }

    pub fn video(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("video", attributes, children);
    }

    pub fn xmp(self: Builder, attributes: anytype, children: anytype) Element {
        return self.el("xmp", attributes, children);
    }
};
