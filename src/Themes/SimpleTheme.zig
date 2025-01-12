const std = @import("std");

const StyledWriter = @import("Style/StyledWriter.zig");
const Style = @import("Style/Style.zig");
const Theme = @import("Theme.zig");
const Options = Theme.Options;
const VTable = Theme.VTable;

const SimpleTheme = @This();

// zig fmt: off
const opts: Options = .{ 
    .confirm_invalid_msg = "The only valid values are: y/yes and n/no, case insensitive", 
    .option_aborted_msg = "Selection aborted", 
    .passwd_echo_indicator = true, 
    .passwd_indicator = '*',
    .confirm_yes_strings = &[_][]const u8{"y", "yes"},
    .confirm_no_strings = &[_][]const u8{"n", "no"},
};

const vtable: VTable = .{ 
    .format_string_prompt_fn = format_string_prompt, 
    .format_option_prompt_fn = format_option_prompt, 
    .format_option_opt_fn = format_option_opt ,
    .format_passwd_prompt_fn = format_passwd_prompt
};
// zig fmt: on

/// String that will be printed between the prompt and the input area.
infix: []const u8 = ">",

fn format_string_prompt(ptr: *const anyopaque, wrt: StyledWriter, prompt: []const u8, default: ?[]const u8, max_len: ?usize) anyerror!void {
    _ = max_len;
    const self: *const SimpleTheme = @ptrCast(@alignCast(ptr));

    if (default) |def| {
        try wrt.print("{s} ({s}) {s} ", .{ prompt, def, self.infix });
    } else {
        try wrt.print("{s} {s} ", .{ prompt, self.infix });
    }
}

fn format_option_prompt(ptr: *const anyopaque, wrt: StyledWriter, prompt: []const u8) anyerror!void {
    try format_string_prompt(ptr, wrt, prompt, null, null);
}

fn format_option_opt(_: *const anyopaque, wrt: StyledWriter, opt: []const u8, is_selected: bool) anyerror!void {
    const c: u8 = if (is_selected) 'X' else ' ';
    try wrt.print("\r[{c}] {s}\n", .{ c, opt });
}

fn format_passwd_prompt(ptr: *const anyopaque, wrt: StyledWriter, prompt: []const u8, max_len: ?usize) anyerror!void {
    const self: *const SimpleTheme = @ptrCast(@alignCast(ptr));

    if (max_len) |l| {
        try wrt.print("{s} (max length: {d}) {s} ", .{ prompt, l, self.infix });
    } else {
        try wrt.print("{s} {s} ", .{ prompt, self.infix });
    }
}

pub fn theme(self: *const SimpleTheme) Theme {
    return .{ .ptr = self, .opts = opts, .vtable = vtable };
}
