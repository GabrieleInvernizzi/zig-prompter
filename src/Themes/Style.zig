pub const Color = struct { r: u8, g: u8, b: u8 };

fg_color: ?Color = null,
bg_color: ?Color = null,
bold: bool = false,
underline: bool = false,
strikethrough: bool = false
