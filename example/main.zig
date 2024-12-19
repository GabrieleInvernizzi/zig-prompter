const std = @import("std");
const Prompter = @import("prompter");

fn three_len_val(str: []const u8) bool {
    return str.len == 3;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    const stdout_w = std.io.getStdOut().writer();

    var p = Prompter.Prompt.init(allocator, Prompter.PromptTheme.default());

    const opts = [_][]const u8{ "Option 1", "Option 2", "Option 3" };
    const sel_opt = try p.option("Select an option", &opts, 1);
    if (sel_opt) |o| {
        try stdout_w.print("\nThe selected option was: {s} (idx: {d})\n", .{ opts[o], o });
    } else {
        try stdout_w.writeAll("\nThe selection was aborted.\n");
    }

    const input_1 = try p.string("Write something", "Default");
    defer allocator.free(input_1);
    try stdout_w.print("{s}\n", .{input_1});

    const input_2 = try p.stringValidated("Write a string with length = 3", null, three_len_val);
    defer allocator.free(input_2);
    try stdout_w.print("{s}\n", .{input_2});
}
