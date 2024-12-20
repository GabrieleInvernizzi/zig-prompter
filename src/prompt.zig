const std = @import("std");
const PromptTheme = @import("promptTheme.zig").PromptTheme;
const mibu = @import("mibu");

const Allocator = std.mem.Allocator;

fn is_string_empty(str: []const u8) bool {
    for (str) |c| {
        if (!std.ascii.isWhitespace(c)) return false;
    }

    return true;
}

fn strToLower(str: []u8) []u8 {
    var i: usize = 0;
    while (i < str.len) : (i += 1) {
        str[i] = std.ascii.toLower(str[i]);
    }
    return str;
}

fn parse_confirmation(str: []const u8) error{NotConfStr}!bool {
    const toLower = std.ascii.toLower;

    if (str.len == 1) {
        const c = toLower(str[0]);
        switch (c) {
            'y' => return true,
            'n' => return false,
            else => return error.NotConfStr,
        }
    } else if (str.len == 2) {
        if (toLower(str[0]) == 'n' and toLower(str[1]) == 'o') return false;
    } else if (str.len == 3) {
        if (toLower(str[0]) == 'y' and toLower(str[1]) == 'e' and toLower(str[2]) == 's') return true;
    }

    return error.NotConfStr;
}

pub const Prompt = struct {
    const Self = @This();

    pub const PromptError = error{DefaultNotInOptions};
    pub const ValidatorFn = fn ([]const u8) bool;

    allocator: Allocator,
    theme: PromptTheme,

    pub fn init(allocator: Allocator, theme: PromptTheme) Self {
        return Prompt{ .allocator = allocator, .theme = theme };
    }

    pub fn string(self: *Self, prompt: []const u8, default: ?[]const u8) ![]const u8 {
        const out = std.io.getStdOut().writer();
        const in = std.io.getStdIn().reader();

        if (default) |def| {
            try out.print("{s}{s} ({s}) {s} ", .{ self.theme.prefix, prompt, def, self.theme.infix });
        } else {
            try out.print("{s}{s} {s} ", .{ self.theme.prefix, prompt, self.theme.infix });
        }

        var buf = std.ArrayList(u8).init(self.allocator);
        const buf_writer = buf.writer();

        try in.streamUntilDelimiter(buf_writer, '\n', self.theme.max_input_size);

        var input: []u8 = try buf.toOwnedSlice();
        if (@import("builtin").os.tag == .windows) {
            input = std.mem.trimRight(u8, input, "\r");
        }

        const ret = input;

        if (is_string_empty(ret) and default != null) {
            buf.deinit();
            var out_buf = std.ArrayList(u8).init(self.allocator);
            try out_buf.appendSlice(default.?);
            return try out_buf.toOwnedSlice();
        } else {
            return std.mem.trim(u8, ret, &std.ascii.whitespace);
        }
    }

    pub fn stringValidated(self: *Self, prompt: []const u8, default: ?[]const u8, validator: ValidatorFn) ![]const u8 {
        const out = std.io.getStdOut().writer();

        while (true) {
            const str = try self.string(prompt, default);
            if (validator(str)) {
                return str;
            } else {
                try out.print("The string: \"{s}\" is invalid. Try again.\n", .{str});
                self.allocator.free(str);
            }
        }
    }

    pub fn confirm(self: *Self, prompt: []const u8) !bool {
        const out = std.io.getStdOut().writer();

        while (true) {
            const str = try self.string(prompt, null);
            const ret = parse_confirmation(str) catch {
                try out.print("{s}\n", .{self.theme.confirm_invalid_msg});
                self.allocator.free(str);
                continue;
            };
            self.allocator.free(str);
            return ret;
        }
    }

    pub fn option(self: *Self, prompt: []const u8, opts: []const []const u8, default: ?usize) !?usize {
        const stdin = std.io.getStdIn();
        const out = std.io.getStdOut().writer();

        // Enable terminal raw mode, its very recommended when listening for events
        var raw_term = try mibu.term.enableRawMode(stdin.handle);
        defer raw_term.disableRawMode() catch {};

        var selected_opt: ?usize = undefined;
        if (default) |d| {
            if (d >= opts.len) {
                return PromptError.DefaultNotInOptions;
            }
            selected_opt = d;
        } else {
            selected_opt = 0;
        }
        try out.print("{s}{s} {s} \n", .{ self.theme.prefix, prompt, self.theme.infix });

        try mibu.cursor.hide(out);

        while (true) {
            for (opts, 0..) |o, i| {
                try mibu.clear.entire_line(out);
                const c: u8 = if (i == selected_opt) 'X' else ' ';
                try out.print("\r[{c}] {s}\n", .{ c, o });
            }
            try mibu.cursor.goUp(out, opts.len);

            const next = try mibu.events.next(stdin);
            switch (next) {
                .key => |k| switch (k) {
                    .ctrl => |c| switch (c) {
                        'c' => {
                            selected_opt = null;
                            break;
                        },
                        else => continue,
                    },
                    .down => if (selected_opt.? < (opts.len - 1)) {
                        selected_opt.? += 1;
                    },
                    .up => if (selected_opt.? > 0) {
                        selected_opt.? -= 1;
                    },
                    .enter => break,
                    else => continue,
                },
                else => continue,
            }
        }

        try mibu.cursor.goUp(out, 1);
        try mibu.clear.screenFromCursor(out);
        try mibu.cursor.show(out);

        if (selected_opt) |o| {
            try out.print("\r{s}{s} {s} {s}\n\r", .{ self.theme.prefix, prompt, self.theme.infix, opts[o] });
        } else {
            try out.print("\r{s}{s} {s} {s}\n\r", .{ self.theme.prefix, prompt, self.theme.infix, self.theme.option_aborted_msg });
        }

        return selected_opt;
    }
};

const testing = std.testing;

test "is_string_empty" {
    try testing.expect(is_string_empty("    \t\t \n  ") == true);
    try testing.expect(is_string_empty("") == true);
    try testing.expect(is_string_empty("  this shouldn't be empty  ") == false);
}
