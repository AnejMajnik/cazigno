const std = @import("std");
const print = std.debug.print;

const g = @import("../shared/globals.zig");
const symbols_to_draw = &g.symbols_to_draw;

const t = @import("../shared/types.zig");
const Cell = t.Cell;

const engine = @import("../engine/engine.zig");

// Draw initial slot machine
pub fn drawSlotMachine() !void {
    clearScreen();

    // Hide cursor
    print("\x1b[?25l", .{});

    // Draw initial slot machine
    g.current_buffer[5][g.MAX_COLUMNS/2-8] = Cell {.character = '[', .color = 34 };
    g.current_buffer[5][g.MAX_COLUMNS/2-7] = Cell {.character = ' ', .color = 34 };
    g.current_buffer[5][g.MAX_COLUMNS/2-6] = Cell {.character = '7', .color = 31 };
    g.current_buffer[5][g.MAX_COLUMNS/2-5] = Cell {.character = ' ', .color = 34 };
    g.current_buffer[5][g.MAX_COLUMNS/2-4] = Cell {.character = ']', .color = 34 };
    g.current_buffer[5][g.MAX_COLUMNS/2-3] = Cell {.character = ' ', .color = 34 };
    g.current_buffer[5][g.MAX_COLUMNS/2-2] = Cell {.character = '[', .color = 34 };
    g.current_buffer[5][g.MAX_COLUMNS/2-1] = Cell {.character = ' ', .color = 34 };
    g.current_buffer[5][g.MAX_COLUMNS/2]   = Cell {.character = '7', .color = 31 };
    g.current_buffer[5][g.MAX_COLUMNS/2+1] = Cell {.character = ' ', .color = 34 };
    g.current_buffer[5][g.MAX_COLUMNS/2+2] = Cell {.character = ']', .color = 34 };
    g.current_buffer[5][g.MAX_COLUMNS/2+3] = Cell {.character = ' ', .color = 34 };
    g.current_buffer[5][g.MAX_COLUMNS/2+4] = Cell {.character = '[', .color = 34 };
    g.current_buffer[5][g.MAX_COLUMNS/2+5] = Cell {.character = ' ', .color = 34 };
    g.current_buffer[5][g.MAX_COLUMNS/2+6] = Cell {.character = '7', .color = 31 };
    g.current_buffer[5][g.MAX_COLUMNS/2+7] = Cell {.character = ' ', .color = 34 };
    g.current_buffer[5][g.MAX_COLUMNS/2+8] = Cell {.character = ']', .color = 34 };

    try refreshScreenDiff();
    printPlayerCoins();
}

pub fn refreshScreenDiff() !void {
    for (g.current_buffer, 0..) |row, i| {
        for(row, 0..) |cell, j| {
            if (cell.character != g.previous_buffer[i][j].character or cell.color != g.previous_buffer[i][j].color) {
                try drawCharAt(@as(u16, @intCast(j))+1, @as(u16, @intCast(i))+1, cell);
            }
        }
    }

    g.previous_buffer = g.current_buffer;
}

fn drawCharAt(x: u16, y: u16, cell: Cell) t.DrawError!void {
    if (x > 0 and y > 0) {
        print("\x1b[{};{}H\x1b[{}m{c}\x1b[0m", .{y, x, cell.color, cell.character});
    }
}

pub fn spinningAnimation(io: std.Io) !void {
    const min_ms: i64 = 50;
    const max_ms: i64 = 450;
    const interval_ms: i64 = 50;
    var current_ms: i64 = min_ms;

    while(current_ms <= max_ms) : (current_ms += interval_ms) {
        engine.playSound();

        engine.spinLosingSymbols(io);

        g.current_buffer[5][g.MAX_COLUMNS/2-6] = Cell {.character = symbols_to_draw[0].symbol, .color = symbols_to_draw[0].color};
        g.current_buffer[5][g.MAX_COLUMNS/2] = Cell {.character = symbols_to_draw[1].symbol, .color = symbols_to_draw[1].color};
        g.current_buffer[5][g.MAX_COLUMNS/2+6] = Cell {.character = symbols_to_draw[2].symbol, .color = symbols_to_draw[2].color};

        try refreshScreenDiff();
        try io.sleep(std.Io.Duration.fromMilliseconds(current_ms), .awake);
    }
}

pub fn printPlayerCoins() void {
    resetCursorPos();
    print("Player coins: {}\n", .{g.player.coins});
}

pub fn clearScreen() void {
    print("\x1b[2J", .{});
}

pub fn resetCursorPos() void {
    print("\x1b[H", .{});
}
