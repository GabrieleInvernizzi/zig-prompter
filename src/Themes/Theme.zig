const std = @import("std");
const Writer = std.fs.File.Writer;

const Theme = @This();

ptr: *const anyopaque,
opts: Options,
vtable: VTable,

pub const Options = struct {
    option_aborted_msg: []const u8,
    confirm_invalid_msg: []const u8,
    passwd_echo_indicator: bool,
    passwd_indicator: u8,
};

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
