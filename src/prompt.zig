const std = @import("std");
const utils = @import("utils.zig");
const PromptTheme = @import("promptTheme.zig").PromptTheme;
const mibu = @import("mibu");

const Allocator = std.mem.Allocator;

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

        if (utils.is_string_empty(ret) and default != null) {
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
            const ret = utils.parse_confirmation(str) catch {
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

    pub fn password(self: *Self, prompt: []const u8, buf: []u8) !?[]const u8 {
        const stdin = std.io.getStdIn();
        const out = std.io.getStdOut().writer();

        // Enable terminal raw mode, its very recommended when listening for events
        var raw_term = try mibu.term.enableRawMode(stdin.handle);
        defer raw_term.disableRawMode() catch {};

        try out.print("{s}{s} (max length: {d}) {s} ", .{ self.theme.prefix, prompt, buf.len, self.theme.infix });

        var read_count: usize = 0;
        while (true) {
            const next = try mibu.events.next(stdin);
            switch (next) {
                .key => |k| switch (k) {
                    .char => |c| {
                        const c_u8: u8 = @intCast(c);
                        if (read_count < buf.len) {
                            buf[read_count] = c_u8;
                            read_count += 1;
                            if (self.theme.passwd_print_indicator) {
                                try out.writeAll(&[_]u8{self.theme.passwd_indicator});
                            }
                        }
                    },
                    .backspace => {
                        if (read_count > 0) {
                            read_count -= 1;
                            if (self.theme.passwd_print_indicator) {
                                try mibu.cursor.goLeft(out, 1);
                                try out.writeAll(" ");
                                try mibu.cursor.goLeft(out, 1);
                            }
                        }
                    },
                    .ctrl => |c| switch (c) {
                        'c' => return null,
                        else => continue,
                    },
                    .enter => break,
                    else => continue,
                },
                else => continue,
            }
        }

        try out.writeAll("\n\r");

        return buf[0..read_count];
    }
};
