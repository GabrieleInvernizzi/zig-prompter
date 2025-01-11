const std = @import("std");

const mibu = @import("mibu");

const Style = @import("Style.zig");

pub const Writer = std.fs.File.Writer;

writer: Writer,
style: ?Style = null,

const Self = @This();

inline fn writeStyle(writer: Writer, style: Style) !void {
    if (style.fg_color) |c| {
        try mibu.color.fgRGB(writer, c.r, c.g, c.b);
    }
    if (style.bg_color) |c| {
        try mibu.color.bgRGB(writer, c.r, c.g, c.b);
    }
    if (style.bold) {
        try mibu.style.bold(writer);
    }
    if (style.strikethrough) {
        try mibu.style.strikethrough(writer);
    }
    if (style.underline) {
        try mibu.style.underline(writer);
    }
}

pub fn writeAll(self: Self, bytes: []const u8) !void {
    if (self.style) |s| {
        try writeStyle(self.writer, s);
    }
    try self.writer.writeAll(bytes);
    if (self.style) |_| {
        try mibu.color.resetAll(self.writer);
    }
}

pub fn print(self: Self, comptime format: []const u8, args: anytype) !void {
    if (self.style) |s| {
        try writeStyle(self.writer, s);
    }
    try self.writer.print(format, args);
    if (self.style) |_| {
        try mibu.color.resetAll(self.writer);
    }
}
