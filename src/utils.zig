const std = @import("std");

fn strToLower(str: []u8) []u8 {
    var i: usize = 0;
    while (i < str.len) : (i += 1) {
        str[i] = std.ascii.toLower(str[i]);
    }
    return str;
}

pub fn parse_confirmation(str: []const u8) error{NotConfStr}!bool {
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

pub fn is_string_empty(str: []const u8) bool {
    for (str) |c| {
        if (!std.ascii.isWhitespace(c)) return false;
    }

    return true;
}

const testing = std.testing;

test "is_string_empty" {
    try testing.expect(is_string_empty("    \t\t \n  ") == true);
    try testing.expect(is_string_empty("") == true);
    try testing.expect(is_string_empty("  this shouldn't be empty  ") == false);
}
