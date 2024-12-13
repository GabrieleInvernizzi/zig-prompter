const std = @import("std");
const mibu = @import("mibu");

const Allocator = std.mem.Allocator;

fn is_string_empty(str: []const u8) bool {
    for (str) |c| {
        if (!std.ascii.isWhitespace(c)) return false;
    }

    return true;
}

pub const ValidatorFn = fn ([]const u8) bool;

pub const Prompt = struct {
    const Self = @This();

    allocator: Allocator,
    max_input_size: usize = 1024,

    pub fn init(alloc: Allocator) Self {
        return Prompt{ .allocator = alloc };
    }

    pub fn string(self: *Self, prompt: []const u8, default: ?[]const u8) ![]const u8 {
        const stdout = std.io.getStdOut();
        const stdin = std.io.getStdIn().reader();

        if (default) |def| {
            try stdout.writer().print("{s} ({s}) > ", .{ prompt, def });
        } else {
            try stdout.writer().print("{s} > ", .{prompt});
        }

        var buf = std.ArrayList(u8).init(self.allocator);
        const writer = buf.writer();

        try stdin.streamUntilDelimiter(writer, '\n', self.max_input_size);

        var input: []u8 = try buf.toOwnedSlice();
        if (@import("builtin").os.tag == .windows) {
            input = std.mem.trimRight(u8, input, "\r");
        }

        const out = input;

        if (is_string_empty(out) and default != null) {
            buf.deinit();
            var out_buf = std.ArrayList(u8).init(self.allocator);
            try out_buf.appendSlice(default.?);
            return try out_buf.toOwnedSlice();
        } else {
            return std.mem.trim(u8, out, &std.ascii.whitespace);
        }
    }

    pub fn stringValidated(self: *Self, prompt: []const u8, default: ?[]const u8, validator: ValidatorFn) ![]const u8 {
        const stdout_w = std.io.getStdOut().writer();

        while (true) {
            const str = try self.string(prompt, default);
            if (validator(str)) {
                return str;
            } else {
                try stdout_w.print("The string: \"{s}\" is invalid. Try again.\n", .{str});
                self.allocator.free(str);
            }
        }
    }
};

const testing = std.testing;

test "is_string_empty" {
    try testing.expect(is_string_empty("    \t\t \n  ") == true);
    try testing.expect(is_string_empty("") == true);
    try testing.expect(is_string_empty("  this shouldn't be empty  ") == false);
}
