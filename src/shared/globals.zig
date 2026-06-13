const t = @import("types.zig");
const std = @import("std");

// Slot symbols
pub const symbols = [5]t.Symbol{
    t.Symbol{.symbol = '7', .color = 31, .worth = 2500},
    t.Symbol{.symbol = '@', .color = 32, .worth = 500},
    t.Symbol{.symbol = 'X', .color = 33, .worth = 250},
    t.Symbol{.symbol = 'Y', .color = 35, .worth = 100},
    t.Symbol{.symbol = '0', .color = 36, .worth = 50},
};

pub var symbols_to_draw: [3]t.Symbol = undefined;

// Terminal size
pub var ws: std.posix.winsize = undefined;
pub var MAX_ROWS: usize = undefined;
pub var MAX_COLUMNS: usize = undefined;

// Cooked terminal attributes
pub var orig: std.posix.termios = undefined;

// Current and previous window buffer
pub var previous_buffer: [500][500]t.Cell = @splat(@splat(EMPTY));
pub var current_buffer: [500][500]t.Cell = @splat(@splat(EMPTY));

// Empty cell
pub const EMPTY: t.Cell = t.Cell {.character = ' ', .color = 37};

// Player state
pub var player: t.Player = t.Player{.coins = 0};

// Cost of spins
pub const spin_cost: u64 = 10;
