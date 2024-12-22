pub const PromptTheme = struct {
    prefix: []const u8 = "",
    infix: []const u8 = ">",
    option_aborted_msg: []const u8 = "Selection aborted",
    max_input_size: usize = 1024,
    confirm_invalid_msg: []const u8 = "The only valid values are: y/yes and n/no, case insensitive",
    passwd_print_indicator: bool = true,
    passwd_indicator: u8 = '*',
};
