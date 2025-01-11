const std = @import("std");

const StyledWriter = @import("Themes/StyledWriter.zig");

fn str_eql_case_insensitive(a: []const u8, b: []const u8) bool {
    const toLower = std.ascii.toLower;

    if (a.len != b.len) return false;
    if (a.len == 0 or a.ptr == b.ptr) return true;

    for (a, b) |a_elem, b_elem| {
        if (toLower(a_elem) != toLower(b_elem)) return false;
    }
    return true;
}

pub fn parse_confirmation(str: []const u8, yes_strings: []const []const u8, no_strings: []const []const u8) error{NotConfStr}!bool {
    for (yes_strings) |s| {
        if (str_eql_case_insensitive(str, s)) {
            return true;
        }
    }

    for (no_strings) |s| {
        if (str_eql_case_insensitive(str, s)) {
            return false;
        }
    }

    return error.NotConfStr;
}

pub fn is_string_empty(str: []const u8) bool {
    for (str) |c| {
        if (!std.ascii.isWhitespace(c)) return false;
    }

    return true;
}

pub fn styledWriter(wrt: StyledWriter.Writer) StyledWriter {
    return .{
        .writer = wrt,
    };
}

const testing = std.testing;

test "is_string_empty" {
    try testing.expect(is_string_empty("    \t\t \n  ") == true);
    try testing.expect(is_string_empty("") == true);
    try testing.expect(is_string_empty("  this shouldn't be empty  ") == false);
}

test "parse_confirmation" {
    const yes_strings = [_][]const u8{ "y", "yes" };
    const no_strings = [_][]const u8{ "n", "no" };

    const corr_yes_inputs = [_][]const u8{ "yes", "Yes", "y" };
    const corr_no_inputs = [_][]const u8{ "no", "No", "n" };
    const wrong_inputs = [_][]const u8{ "yep", "nop" };

    for (corr_yes_inputs) |i| {
        try testing.expectEqual(true, parse_confirmation(i, &yes_strings, &no_strings));
    }

    for (corr_no_inputs) |i| {
        try testing.expectEqual(false, parse_confirmation(i, &yes_strings, &no_strings));
    }

    for (wrong_inputs) |i| {
        try testing.expectError(error.NotConfStr, parse_confirmation(i, &yes_strings, &no_strings));
    }
}
