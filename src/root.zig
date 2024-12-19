const std = @import("std");

pub const Prompt = @import("prompt.zig").Prompt;
pub const PromptTheme = @import("prompt.zig").PromptTheme;

test {
    std.testing.refAllDecls(@This());
}
