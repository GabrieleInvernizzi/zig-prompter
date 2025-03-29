//! The main struct of zig-prompter, it manages all the differet kinds of prompts.

const std = @import("std");
const utils = @import("utils.zig");
const Themes = @import("Themes/Themes.zig");
const Theme = Themes.Theme;
const StyledWriter = Themes.StyledWriter;

const mibu = @import("mibu");

const Allocator = std.mem.Allocator;

const Self = @This();

pub const PromptError = error{DefaultNotInOptions};
/// Validator Function signature, to be used with `stringValidated`.
pub const ValidatorFn = fn ([]const u8) bool;

allocator: Allocator,
theme: Theme,

/// Initialization function.
/// `theme` must be a valid `Theme` specification.
pub fn init(allocator: Allocator, theme: Theme) Self {
    return .{ .allocator = allocator, .theme = theme };
}

/// Asks the user for a string with the provided `prompt`.
/// If the user does not enter any non whitespace chars the function returns the `default`.
/// In case of success the function will return an owned slice.
/// Free the return value using the allocator provided in `init`.
pub fn string(self: *Self, prompt: []const u8, default: ?[]const u8) ![]const u8 {
    const out = std.io.getStdOut().writer();
    const in = std.io.getStdIn().reader();
    const out_styled = StyledWriter.styledWriter(out);

    try self.theme.format_string_prompt(out_styled, prompt, default, null);

    var buf = std.ArrayList(u8).init(self.allocator);
    const buf_writer = buf.writer();

    try in.streamUntilDelimiter(buf_writer, '\n', null);

    var input: []u8 = try buf.toOwnedSlice();
    if (@import("builtin").os.tag == .windows) {
        input = std.mem.trimRight(u8, input, "\r");
    }

    var ret: []const u8 = undefined;

    const const_input = input;
    if (utils.is_string_empty(const_input) and default != null) {
        buf.deinit();
        var out_buf = std.ArrayList(u8).init(self.allocator);
        try out_buf.appendSlice(default.?);
        ret = try out_buf.toOwnedSlice();
    } else {
        ret = std.mem.trim(u8, const_input, &std.ascii.whitespace);
    }

    return ret;
}

/// Similar to `Prompt.string(...)` but it also validate the input with `validator`.
/// In case of success the function will return an owned slice.
/// Free the return value using the allocator provided in `init`.
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

/// Asks the user a confirmation with the `prompt` provided.
/// In case of success the function will return `true` if the value inserted by the user
/// was affermative and `false` otherwise.
pub fn confirm(self: *Self, prompt: []const u8) !bool {
    const out = std.io.getStdOut().writer();

    while (true) {
        const str = try self.string(prompt, null);
        const ret = utils.parse_confirmation(str, self.theme.opts.confirm_yes_strings, self.theme.opts.confirm_no_strings) catch {
            try out.print("{s}\n", .{self.theme.opts.confirm_invalid_msg});
            self.allocator.free(str);
            continue;
        };
        self.allocator.free(str);
        return ret;
    }
}

/// Asks the user to select an option between `opts` (enter to confirm), then it returns the relative index.
/// The operation can be aborted using ctrl-c, then the function returns `null`.
pub fn option(self: *Self, prompt: []const u8, opts: []const []const u8, default: ?usize) !?usize {
    const stdin = std.io.getStdIn();
    const out = std.io.getStdOut().writer();
    const out_styled = StyledWriter.styledWriter(out);

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
    try self.theme.format_option_prompt(out_styled, prompt);

    try mibu.cursor.hide(out);

    while (true) {
        for (opts, 0..) |o, i| {
            try mibu.clear.entire_line(out);
            try self.theme.format_option_opt(out_styled, o, i == selected_opt);
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
                .char => |c| switch (c) {
                    'j' => if (selected_opt.? < (opts.len - 1)) {
                        selected_opt.? += 1;
                    },
                    'k' => if (selected_opt.? > 0) {
                        selected_opt.? -= 1;
                    },
                    else => continue,
                },
                else => continue,
            },
            else => continue,
        }
    }

    try mibu.cursor.goUp(out, 1);
    try mibu.clear.screenFromCursor(out);
    try mibu.cursor.show(out);

    try out.writeAll("\r");
    try self.theme.format_option_prompt(out_styled, prompt);
    if (selected_opt) |o| {
        try out.print("{s}\n\r", .{opts[o]});
    } else {
        try out.print("{s}\n\r", .{self.theme.opts.option_aborted_msg});
    }

    return selected_opt;
}

/// Asks the user for a password with the provieded `prompt`.
/// The echoing of an indicator character as the user types can be set via the `Theme`.
/// The operation can be aborted using ctrl-c, then the function returns `null`.
/// In case of success the function will return a slice over `buf`.
pub fn password(self: *Self, prompt: []const u8, buf: []u8) !?[]const u8 {
    const stdin = std.io.getStdIn();
    const out = std.io.getStdOut().writer();
    const out_styled = StyledWriter.styledWriter(out);

    var raw_term = try mibu.term.enableRawMode(stdin.handle);
    defer raw_term.disableRawMode() catch {};

    try self.theme.format_passwd_prompt(out_styled, prompt, buf.len);

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
                        if (self.theme.opts.passwd_echo_indicator) {
                            try out.writeAll(&[_]u8{self.theme.opts.passwd_indicator});
                        }
                    }
                },
                .backspace => {
                    if (read_count > 0) {
                        read_count -= 1;
                        if (self.theme.opts.passwd_echo_indicator) {
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
