const std = @import("std");

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

pub fn Builder(comptime WriterT: type, comptime pretty: bool) type {
    return struct {
        allocator: std.mem.Allocator,
        writer: WriterT,
        tag_stack: std.ArrayList([]const u8),

        pub fn init(allocator: std.mem.Allocator, writer: WriterT) @This() {
            return @This(){
                .allocator = allocator,
                .writer = writer,
                .tag_stack = std.ArrayList([]const u8).init(allocator),
            };
        }

        pub fn doctype(self: *@This()) !void {
            try self.writer.writeAll("<!DOCTYPE html>\n");
        }

        pub fn open(self: *@This(), tag: []const u8, attributes: anytype) !void {
            try self.indent();
            try self.writer.writeAll("<");
            try self.writer.writeAll(tag);

            if (@TypeOf(attributes) != @TypeOf(null)) {
                inline for (@typeInfo(@TypeOf(attributes)).Struct.fields) |field| {
                    // https://html.spec.whatwg.org/multipage/syntax.html#attributes-2
                    // Attribute names must consist of one or more characters other than
                    // controls, U+0020 SPACE, U+0022 ("), U+0027 ('), U+003E (>), U+002F (/),
                    // U+003D (=), and noncharacters. In the HTML syntax, attribute names, even
                    // those for foreign elements, may be written with any mix of ASCII lower
                    // and ASCII upper alphas.
                    comptime for (field.name) |char| {
                        if (!std.ascii.isASCII(char)) {
                            unreachable; // found non-ascii char in html attribute name
                        }
                        if (std.ascii.isControl(char)) {
                            unreachable; // found forbidden control char in html attribute name
                        }
                        for (" \"'>/=") |forbidden_char| {
                            if (char == forbidden_char) {
                                unreachable; // found forbidden char in html attribute name
                            }
                        }
                    };
                    try self.writer.writeAll(" ");
                    try self.writer.writeAll(field.name);
                    try self.writer.writeAll("=\"");
                    try self.writer.writeAll(escape(self.allocator, @field(attributes, field.name)));
                    try self.writer.writeAll("\"");
                }
            }

            try self.writer.writeAll(">");
            if (pretty) {
                try self.writer.writeAll("\n");
            }

            // Add tag to stack only if it's not a void HTML element
            for (void_tags) |vtag| {
                if (std.mem.eql(u8, tag, vtag)) {
                    return;
                }
            }
            try self.tag_stack.append(tag);
        }

        // TODO: cannot bubble error up here because `defer try close()` isn't supported.
        // Crashing during a write isn't ideal either, because that rules out writing to a network
        // writer. Is there a better way?
        pub fn close(self: *@This()) void {
            const tag = self.tag_stack.pop();
            self.indent() catch unreachable;
            self.writer.writeAll("</") catch unreachable;
            self.writer.writeAll(tag) catch unreachable;
            self.writer.writeAll(">") catch unreachable;
            if (pretty) {
                self.writer.writeAll("\n") catch unreachable;
            }
        }

        pub fn text(self: *@This(), content: []const u8) !void {
            try self.indent();
            try self.writer.writeAll(escape(self.allocator, content));
            if (pretty) {
                self.writer.writeAll("\n") catch unreachable;
            }
        }

        fn indent(self: *@This()) !void {
            if (pretty) {
                for (0..self.tag_stack.items.len) |_| {
                    try self.writer.writeAll("  ");
                }
            }
        }
    };
}

const void_tags = &[_][]const u8{
    "area",
    "base",
    "br",
    "col",
    "embed",
    "hr",
    "img",
    "input",
    "link",
    "meta",
    "source",
    "track",
    "wbr",
};

test "Builder" {
    const test_allocator = std.testing.allocator;
    var arena = std.heap.ArenaAllocator.init(test_allocator);

    var output = std.ArrayList(u8).init(test_allocator);
    defer output.deinit();

    var h = Builder(std.ArrayList(u8).Writer, true).init(arena.allocator(), output.writer());
    {
        try h.open("p", .{ .@"escapes<&" = "&<>\"'" });
        defer h.close();
        try h.text("I'm");
        {
            try h.open("b", null);
            defer h.close();
            try h.text("bold.");
            try h.text("&<>\"'");
        }
    }

    // we can safely free the builder's arena now because `output` isn't in it.
    arena.deinit();

    try std.testing.expectEqualStrings(
        \\<p escapes<&="&amp;&lt;&gt;&quot;&#39;">
        \\  I&#39;m
        \\  <b>
        \\    bold.
        \\    &amp;&lt;&gt;&quot;&#39;
        \\  </b>
        \\</p>
        \\
    , output.items);
}
