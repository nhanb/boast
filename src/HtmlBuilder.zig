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
        escaped = self.allocator.alloc(u8, size) catch unreachable;
        _ = std.mem.replace(u8, unescaped, needle, replacement, escaped);
        unescaped = escaped;
    }
    return escaped;
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

// The following is generate_html_tags.py's output

pub fn area(self: HtmlBuilder, attributes: anytype) Element {
    return self.el("area", attributes, null);
}

pub fn base(self: HtmlBuilder, attributes: anytype) Element {
    return self.el("base", attributes, null);
}

pub fn br(self: HtmlBuilder, attributes: anytype) Element {
    return self.el("br", attributes, null);
}

pub fn col(self: HtmlBuilder, attributes: anytype) Element {
    return self.el("col", attributes, null);
}

pub fn embed(self: HtmlBuilder, attributes: anytype) Element {
    return self.el("embed", attributes, null);
}

pub fn hr(self: HtmlBuilder, attributes: anytype) Element {
    return self.el("hr", attributes, null);
}

pub fn img(self: HtmlBuilder, attributes: anytype) Element {
    return self.el("img", attributes, null);
}

pub fn input(self: HtmlBuilder, attributes: anytype) Element {
    return self.el("input", attributes, null);
}

pub fn link(self: HtmlBuilder, attributes: anytype) Element {
    return self.el("link", attributes, null);
}

pub fn meta(self: HtmlBuilder, attributes: anytype) Element {
    return self.el("meta", attributes, null);
}

pub fn source(self: HtmlBuilder, attributes: anytype) Element {
    return self.el("source", attributes, null);
}

pub fn track(self: HtmlBuilder, attributes: anytype) Element {
    return self.el("track", attributes, null);
}

pub fn wbr(self: HtmlBuilder, attributes: anytype) Element {
    return self.el("wbr", attributes, null);
}

pub fn a(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("a", attributes, children);
}

pub fn abbr(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("abbr", attributes, children);
}

pub fn acronym(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("acronym", attributes, children);
}

pub fn address(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("address", attributes, children);
}

pub fn article(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("article", attributes, children);
}

pub fn aside(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("aside", attributes, children);
}

pub fn audio(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("audio", attributes, children);
}

pub fn b(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("b", attributes, children);
}

pub fn bdi(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("bdi", attributes, children);
}

pub fn bdo(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("bdo", attributes, children);
}

pub fn big(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("big", attributes, children);
}

pub fn blockquote(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("blockquote", attributes, children);
}

pub fn body(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("body", attributes, children);
}

pub fn button(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("button", attributes, children);
}

pub fn canvas(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("canvas", attributes, children);
}

pub fn caption(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("caption", attributes, children);
}

pub fn center(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("center", attributes, children);
}

pub fn cite(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("cite", attributes, children);
}

pub fn code(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("code", attributes, children);
}

pub fn colgroup(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("colgroup", attributes, children);
}

pub fn data(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("data", attributes, children);
}

pub fn datalist(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("datalist", attributes, children);
}

pub fn dd(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("dd", attributes, children);
}

pub fn del(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("del", attributes, children);
}

pub fn details(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("details", attributes, children);
}

pub fn dfn(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("dfn", attributes, children);
}

pub fn dialog(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("dialog", attributes, children);
}

pub fn dir(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("dir", attributes, children);
}

pub fn div(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("div", attributes, children);
}

pub fn dl(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("dl", attributes, children);
}

pub fn dt(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("dt", attributes, children);
}

pub fn em(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("em", attributes, children);
}

pub fn fieldset(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("fieldset", attributes, children);
}

pub fn figcaption(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("figcaption", attributes, children);
}

pub fn figure(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("figure", attributes, children);
}

pub fn font(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("font", attributes, children);
}

pub fn footer(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("footer", attributes, children);
}

pub fn form(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("form", attributes, children);
}

pub fn frame(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("frame", attributes, children);
}

pub fn frameset(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("frameset", attributes, children);
}

pub fn h1(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("h1", attributes, children);
}

pub fn head(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("head", attributes, children);
}

pub fn header(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("header", attributes, children);
}

pub fn hgroup(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("hgroup", attributes, children);
}

pub fn html(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("html", attributes, children);
}

pub fn i(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("i", attributes, children);
}

pub fn iframe(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("iframe", attributes, children);
}

pub fn image(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("image", attributes, children);
}

pub fn ins(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("ins", attributes, children);
}

pub fn kbd(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("kbd", attributes, children);
}

pub fn label(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("label", attributes, children);
}

pub fn legend(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("legend", attributes, children);
}

pub fn li(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("li", attributes, children);
}

pub fn main(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("main", attributes, children);
}

pub fn map(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("map", attributes, children);
}

pub fn mark(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("mark", attributes, children);
}

pub fn marquee(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("marquee", attributes, children);
}

pub fn menu(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("menu", attributes, children);
}

pub fn menuitem(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("menuitem", attributes, children);
}

pub fn meter(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("meter", attributes, children);
}

pub fn nav(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("nav", attributes, children);
}

pub fn nobr(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("nobr", attributes, children);
}

pub fn noembed(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("noembed", attributes, children);
}

pub fn noframes(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("noframes", attributes, children);
}

pub fn noscript(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("noscript", attributes, children);
}

pub fn object(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("object", attributes, children);
}

pub fn ol(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("ol", attributes, children);
}

pub fn optgroup(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("optgroup", attributes, children);
}

pub fn option(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("option", attributes, children);
}

pub fn output(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("output", attributes, children);
}

pub fn p(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("p", attributes, children);
}

pub fn param(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("param", attributes, children);
}

pub fn picture(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("picture", attributes, children);
}

pub fn plaintext(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("plaintext", attributes, children);
}

pub fn portal(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("portal", attributes, children);
}

pub fn pre(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("pre", attributes, children);
}

pub fn progress(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("progress", attributes, children);
}

pub fn q(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("q", attributes, children);
}

pub fn rb(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("rb", attributes, children);
}

pub fn rp(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("rp", attributes, children);
}

pub fn rt(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("rt", attributes, children);
}

pub fn rtc(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("rtc", attributes, children);
}

pub fn ruby(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("ruby", attributes, children);
}

pub fn s(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("s", attributes, children);
}

pub fn samp(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("samp", attributes, children);
}

pub fn script(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("script", attributes, children);
}

pub fn search(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("search", attributes, children);
}

pub fn section(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("section", attributes, children);
}

pub fn select(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("select", attributes, children);
}

pub fn slot(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("slot", attributes, children);
}

pub fn small(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("small", attributes, children);
}

pub fn span(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("span", attributes, children);
}

pub fn strike(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("strike", attributes, children);
}

pub fn strong(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("strong", attributes, children);
}

pub fn style(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("style", attributes, children);
}

pub fn sub(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("sub", attributes, children);
}

pub fn summary(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("summary", attributes, children);
}

pub fn sup(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("sup", attributes, children);
}

pub fn table(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("table", attributes, children);
}

pub fn tbody(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("tbody", attributes, children);
}

pub fn td(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("td", attributes, children);
}

pub fn template(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("template", attributes, children);
}

pub fn textarea(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("textarea", attributes, children);
}

pub fn tfoot(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("tfoot", attributes, children);
}

pub fn th(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("th", attributes, children);
}

pub fn thead(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("thead", attributes, children);
}

pub fn time(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("time", attributes, children);
}

pub fn title(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("title", attributes, children);
}

pub fn tr(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("tr", attributes, children);
}

pub fn tt(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("tt", attributes, children);
}

pub fn u(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("u", attributes, children);
}

pub fn ul(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("ul", attributes, children);
}

pub fn @"var"(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("var", attributes, children);
}

pub fn video(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("video", attributes, children);
}

pub fn xmp(self: HtmlBuilder, attributes: anytype, children: anytype) Element {
    return self.el("xmp", attributes, children);
}
