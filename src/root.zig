const std = @import("std");

pub const Prompt = @import("prompt.zig").Prompt;
pub const PromptTheme = @import("promptTheme.zig").PromptTheme;

test {
    std.testing.refAllDecls(@This());
}
