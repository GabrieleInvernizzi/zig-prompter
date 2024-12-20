const std = @import("std");
const Prompter = @import("prompter");

// Example of a simple string validator
fn len_three_val(str: []const u8) bool {
    return str.len == 3;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const check = gpa.deinit();
        if (check == .leak) @panic("The allocator has leaked!");
    }
    const allocator = gpa.allocator();
    const out = std.io.getStdOut().writer();

    // Initialize the Prompt struct with the default theme
    var p = Prompter.Prompt.init(allocator, Prompter.PromptTheme.default());

    // Try out the option selection prompt
    {
        try out.writeAll("[ Option Selection Prompt ]\n");
        const opts = [_][]const u8{ "Option 1", "Option 2", "Option 3" };
        const sel_opt = try p.option("Select an option", &opts, 1);
        if (sel_opt) |o| {
            try out.print("\nThe selected option was: {s} (idx: {d})\n", .{ opts[o], o });
        } else {
            try out.writeAll("\nThe selection was aborted.\n");
        }
    }

    // Try out the string prompt
    {
        try out.writeAll("\n[ String Prompt ]\n");
        const input = try p.string("Write something", "Default");
        defer allocator.free(input);
        try out.print("The input was: {s}\n", .{input});
    }

    // Try out the string prompt with validation (using the function defined above (len_three_val))
    {
        try out.writeAll("\n[ Validated String Prompt ]\n");
        const input = try p.stringValidated("Write a string with length = 3", null, len_three_val);
        defer allocator.free(input);
        try out.print("The input was: {s}\n", .{input});
    }
}
