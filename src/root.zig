const std = @import("std");

pub const Prompt = @import("prompt.zig").Prompt;

test {
    std.testing.refAllDecls(@This());
}
