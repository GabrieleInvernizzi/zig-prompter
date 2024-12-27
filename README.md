# zig-prompter

**zig-prompter** is a lightweight and flexible library for building and managing interactive text-based prompts in the [Zig programming language](https://ziglang.org/). Whether you're creating command-line tools, text-based games, or utilities requiring user input, `zig-prompter` simplifies the process with intuitive APIs and a robust feature set.

## Installation

First, add zig-prompter to your `build.zig.zon` file:
```bash
zig fetch --save git+https://github.com/GabrieleInvernizzi/zig-prompter/
```

Update your `build.zig` file to include the dependency:
```zig
const prompter_dep = b.dependency("prompter", .{
        .target = target,
        .optimize = optimize,
    });

exe.root_module.addImport("prompter", prompter_dep.module("prompter"));
```

Here’s an example of using **zig-prompter** to create a simple selection prompt:
```zig
const std = @import("std");
const Prompter = @import("prompter");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const stdout = std.io.getStdOut();

    const theme = Prompter.Themes.SimpleTheme{};
    var p = Prompter.Prompt.init(allocator, theme.theme());

    const opts = [_][]const u8{ "Option 1", "Option 2", "Option 3" };
    const sel_opt = try p.option("Select an option", &opts, 1);
    if (sel_opt) |o| {
        try stdout.writer().print("\nThe selected option was: {s} (idx: {d})\n", .{ opts[o], o });
    } else {
        try stdout.writer().writeAll("\nThe selection was aborted.\n");
    }
}
```

For a more exhaustive example, take a look at the [example](https://github.com/GabrieleInvernizzi/zig-prompter/tree/main/example) directory.

## Features
- [x] String prompt
- [x] Interactive option selection prompt
- [x] Confirmation prompt
- [x] Password prompt
- [x] Input validation
- [x] Advanced support for themes and personalization
- [ ] Include more themes
- [ ] Windows support

## Contributions
For now the project is in its early stages, still contributions are always welcome and greatly appreciated! Whether it's fixing bugs, adding features, improving documentation, or enhancing examples, your input helps make **zig-prompter** even better. Feel free to open issues to discuss potential improvements or submit pull requests directly.

Thank you for your support!

## Acknowledgments  
This library was inspired by the fantastic **Rust** library [Dialoguer](https://github.com/mitsuhiko/dialoguer).
