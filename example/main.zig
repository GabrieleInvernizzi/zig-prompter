const std = @import("std");
const Prompt = @import("prompter");

pub fn main() !void {
    var buf: [1024]u8 = undefined;
    const input = try Prompt.string("Write something: ", &buf, "Default");

    const stdout = std.io.getStdOut();

    try stdout.writeAll(input);
}
