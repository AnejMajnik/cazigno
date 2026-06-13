const std = @import("std");
const print = std.debug.print;
const posix = std.posix;

const g = @import("shared/globals.zig");
const t = @import("shared/types.zig");
const engine = @import("engine/engine.zig");
const render = @import("render/render.zig");

// --------------- INIT ----------------
// Sets the terminal size values
fn setTerminalSize() t.WinsizeError!void {
    const rc = std.os.linux.ioctl(std.posix.STDOUT_FILENO, std.os.linux.T.IOCGWINSZ, @intFromPtr(&g.ws));

    if (rc >= 0) {
        // Populate size
        g.MAX_ROWS = g.ws.row;
        g.MAX_COLUMNS = g.ws.col;
    } else {
        return t.WinsizeError.Failed;
    }
}

fn setTerminalRawMode() !void {
    // Get cooked terminal attributes
    g.orig = try posix.tcgetattr(posix.STDIN_FILENO);

    var raw = g.orig;
    raw.lflag.ICANON = false;
    raw.lflag.ECHO = false;
    raw.cc[@intFromEnum(posix.V.MIN)] = 0;
    raw.cc[@intFromEnum(posix.V.TIME)] = 0;
    try posix.tcsetattr(posix.STDIN_FILENO, .FLUSH, raw);
}

pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var running = true;

    try engine.initPlayer(io);

    // Get terminal size in rows and columns
    try setTerminalSize();

    // Set terminal into raw mode to enable listening for keystrokes
    try setTerminalRawMode();

    // Reset terminal to cooked mode on exit
    defer _ = posix.tcsetattr(posix.STDIN_FILENO, .FLUSH, g.orig) catch {};

    // Show cursor on exit
    defer print("\x1b[?25h", .{});

    // Draw initial slot machine
    try render.drawSlotMachine();

    // Listen for keystrokes
    while (running) {
        var buf: [1]u8 = undefined;
        const read_char = posix.read(posix.STDIN_FILENO, &buf) catch 0;

        // 0 or below is Error
        if (read_char > 0) {
            switch (buf[0]) {
                ' ' => {
                    if (g.player.coins >= g.spin_cost) {
                        try engine.spin(io);
                    }
                },
                'q' => { 
                    render.clearScreen();
                    render.resetCursorPos();
                    running = false; 
                },
                else => {},
            }
        }
    }
    
}
