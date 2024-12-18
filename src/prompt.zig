const std = @import("std");
const mibu = @import("mibu");

const Allocator = std.mem.Allocator;

fn is_string_empty(str: []const u8) bool {
    for (str) |c| {
        if (!std.ascii.isWhitespace(c)) return false;
    }

    return true;
}

pub const PromptTheme = struct {
    prefix: []const u8,
    infix: []const u8,
    option_aborted_msg: []const u8,
    max_input_size: usize,

    pub fn default() PromptTheme {
        return PromptTheme{ .prefix = "", .infix = ">", .option_aborted_msg = "Selection aborted", .max_input_size = 1024 };
    }
};

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
        const stdout = std.io.getStdOut();
        const stdin = std.io.getStdIn().reader();

        if (default) |def| {
            try stdout.writer().print("{s}{s} ({s}) {s} ", .{ self.theme.prefix, prompt, def, self.theme.infix });
        } else {
            try stdout.writer().print("{s}{s} {s} ", .{ self.theme.prefix, prompt, self.theme.infix });
        }

        var buf = std.ArrayList(u8).init(self.allocator);
        const writer = buf.writer();

        try stdin.streamUntilDelimiter(writer, '\n', self.theme.max_input_size);

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

    pub fn option(self: *Self, prompt: []const u8, opts: []const []const u8, default: ?usize) !?usize {
        const stdin = std.io.getStdIn();
        const stdout = std.io.getStdOut();
        const stdout_wrt = stdout.writer();

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
        try stdout_wrt.print("{s}{s} {s} \n", .{ self.theme.prefix, prompt, self.theme.infix });

        try mibu.cursor.hide(stdout_wrt);

        while (true) {
            for (opts, 0..) |o, i| {
                try mibu.clear.entire_line(stdout_wrt);
                const c: u8 = if (i == selected_opt) '*' else ' ';
                try stdout_wrt.print("\r[{c}] {s}\n", .{ c, o });
            }
            try mibu.cursor.goUp(stdout_wrt, opts.len);

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

        try mibu.cursor.goUp(stdout_wrt, 1);
        try mibu.clear.screenFromCursor(stdout_wrt);
        try mibu.cursor.show(stdout_wrt);

        if (selected_opt) |o| {
            try stdout_wrt.print("\r{s}{s} {s} {s}\n\r", .{ self.theme.prefix, prompt, self.theme.infix, opts[o] });
        } else {
            try stdout_wrt.print("\r{s}{s} {s} {s}\n\r", .{ self.theme.prefix, prompt, self.theme.infix, self.theme.option_aborted_msg });
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
