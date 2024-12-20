pub const PromptTheme = struct {
    prefix: []const u8,
    infix: []const u8,
    option_aborted_msg: []const u8,
    max_input_size: usize,
    confirm_invalid_msg: []const u8,

    pub fn default() PromptTheme {
        return PromptTheme{ .prefix = "", .infix = ">", .option_aborted_msg = "Selection aborted", .max_input_size = 1024, .confirm_invalid_msg = "The only valid values are: y/yes and n/no, case insensitive." };
    }
};
