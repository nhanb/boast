const std = @import("std");

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
