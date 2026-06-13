const std = @import("std");
const print = std.debug.print;

const t = @import("../shared/types.zig");
const Cell = t.Cell;

const g = @import("../shared/globals.zig");
const symbols = &g.symbols;

const fileio = @import("../util/fileio.zig");
const render = @import("../render/render.zig");

pub fn initPlayer(io: std.Io) !void {
    var content: [64]u8 = undefined;
    const data: []const u8 = try fileio.readSavefile(io, &content);

    if (data.len > 0) {
        var it = std.mem.tokenizeAny(u8, data, " =\n");

        var i: usize = 0;
        while (it.next()) |word| {
            i += 1;
            if (i%2 == 0) {
                g.player.coins = try std.fmt.parseInt(u64, word, 10);
            }
        }
    }
}

fn addCoins(io: std.Io, amount: u64) !void {
    g.player.coins += amount;
    var buf: [64]u8 = undefined;
    const str = try std.fmt.bufPrint(&buf, "coins={}", .{g.player.coins});
    try fileio.writeSavefile(io, str);
}

pub fn spinLosingSymbols(io: std.Io) void {
    var i: u8 = 0;
    var tempSym: u8 = undefined;
    while(i < 3) {
        tempSym = generateRandomNumber(io, u8, 0, 4);
        if (!arrContains(tempSym)) {
            g.symbols_to_draw[i] = symbols[tempSym];
            i += 1;
        }
    }
}

pub fn spin(io: std.Io) !void {
    try render.spinningAnimation(io);
    const random_num: u16 = generateRandomNumber(io, u16, 1, 1000);

    playSound();

    switch(random_num) {
        1...800 => {
            spinLosingSymbols(io);
        },
        801...900 => {
            g.symbols_to_draw = @splat(symbols[4]);
            try addCoins(io, symbols[4].worth);
        },
        901...950 => {
            g.symbols_to_draw = @splat(symbols[3]);
            try addCoins(io, symbols[3].worth);
        },
        951...980 => {
            g.symbols_to_draw = @splat(symbols[2]);
            try addCoins(io, symbols[2].worth);
        },
        981...999 => {
            g.symbols_to_draw = @splat(symbols[1]);
            try addCoins(io, symbols[1].worth);
        },
        1000 => {
            g.symbols_to_draw = @splat(symbols[0]);
            try addCoins(io, symbols[0].worth);
        },
        else => print("Error", .{}),
    }

    g.current_buffer[10][g.MAX_COLUMNS/2-6] = Cell {.character = g.symbols_to_draw[0].symbol, .color = g.symbols_to_draw[0].color};
    g.current_buffer[10][g.MAX_COLUMNS/2] = Cell {.character = g.symbols_to_draw[1].symbol, .color = g.symbols_to_draw[1].color};
    g.current_buffer[10][g.MAX_COLUMNS/2+6] = Cell {.character = g.symbols_to_draw[2].symbol, .color = g.symbols_to_draw[2].color};

    try render.refreshScreenDiff();
    render.printPlayerCoins();
}

fn generateRandomNumber(io: std.Io, comptime T: type, comptime min: T, comptime max: T) T {
    const rng: std.Random.IoSource = .{ .io = io };
    const rand = rng.interface();

    const num = rand.intRangeAtMost(T, min, max);

    return num;
}

fn arrContains(char: u8) bool {
    for (g.symbols_to_draw) |sym| {
        if (sym.symbol == char) return true;
    }
    return false;
}

pub fn playSound() void {
    print("\x07", .{});
}
