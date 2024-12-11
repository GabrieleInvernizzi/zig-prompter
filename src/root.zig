const std = @import("std");

fn is_string_empty(str: []const u8) bool {
    for (str) |c| {
        if (!std.ascii.isWhitespace(c)) return false;
    }

    return true;
}

pub fn string(prompt: []const u8, buffer: []u8, default: ?[]const u8) anyerror![]const u8 {
    @memset(buffer, ' ');

    const stdout = std.io.getStdOut();
    const stdin = std.io.getStdIn().reader();

    try stdout.writeAll(prompt);

    var buf_stream = std.io.fixedBufferStream(buffer);
    const writer = buf_stream.writer();

    try stdin.streamUntilDelimiter(writer, '\n', buffer.len);

    var input: []u8 = buf_stream.buffer;
    if (@import("builtin").os.tag == .windows) {
        input = std.mem.trimRight(u8, input, "\r");
    }

    const out = input;

    if (is_string_empty(out) and default != null) {
        return default.?;
    } else {
        return std.mem.trim(u8, out, &std.ascii.whitespace);
    }
}

const testing = std.testing;

test "is_string_empty" {
    try testing.expect(is_string_empty("    \t\t \n  ") == true);
    try testing.expect(is_string_empty("") == true);
    try testing.expect(is_string_empty("  this shouldn't be empty  ") == false);
}
