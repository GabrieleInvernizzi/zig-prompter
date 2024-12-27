//! The interface used by the `Prompt` struct for theming.

const std = @import("std");
const Writer = std.fs.File.Writer;

const Theme = @This();

/// Pointer to the concrete theme struct
ptr: *const anyopaque,
/// Options used for customization, for more details refer to the `Options` struct.
opts: Options,
/// VTable that contains all the format functions.
vtable: VTable,

/// Stores all the options for customization used in the `Theme` struct.
pub const Options = struct {
    /// Printed when option selection is aborted.
    option_aborted_msg: []const u8,
    /// Printed when the input is not a valid confirmartion string.
    confirm_invalid_msg: []const u8,
    /// If `true` as the user types a password the `passwd_indicator` is printed,
    /// otherwise no echo will be performed.
    passwd_echo_indicator: bool,
    /// The indicator char that will used in the password prompt.
    passwd_indicator: u8,
};

/// Stores all the format functions used in the `Theme` struct.
pub const VTable = struct {
    format_string_prompt_fn: *const fn (ptr: *const anyopaque, wrt: Writer, prompt: []const u8, default: ?[]const u8, max_len: ?usize) anyerror!void,
    format_option_prompt_fn: *const fn (ptr: *const anyopaque, wrt: Writer, prompt: []const u8) anyerror!void,
    format_option_opt_fn: *const fn (_: *const anyopaque, wrt: Writer, opt: []const u8, is_selected: bool) anyerror!void,
    format_passwd_prompt_fn: *const fn (ptr: *const anyopaque, wrt: Writer, prompt: []const u8, max_len: ?usize) anyerror!void,
};

pub fn format_string_prompt(self: Theme, wrt: Writer, prompt: []const u8, default: ?[]const u8, max_len: ?usize) anyerror!void {
    return self.vtable.format_string_prompt_fn(self.ptr, wrt, prompt, default, max_len);
}

pub fn format_option_prompt(self: Theme, wrt: Writer, prompt: []const u8) anyerror!void {
    return self.vtable.format_option_prompt_fn(self.ptr, wrt, prompt);
}

pub fn format_option_opt(self: Theme, wrt: Writer, opt: []const u8, is_selected: bool) anyerror!void {
    return self.vtable.format_option_opt_fn(self.ptr, wrt, opt, is_selected);
}

pub fn format_passwd_prompt(self: Theme, wrt: Writer, prompt: []const u8, max_len: ?usize) anyerror!void {
    return self.vtable.format_passwd_prompt_fn(self.ptr, wrt, prompt, max_len);
}
