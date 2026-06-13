const std = @import("std");
const print = std.debug.print;
const posix = std.posix;

// Winsize Error
const WinsizeError = error {
    Failed,
};

// Draw Error
const DrawError = error {
    InvalidCoordinate,
};

// Cell struct
const Cell = struct {
    character: u8,
    color: u8,
};

// Symbol struct
const Symbol = struct {
    symbol: u8,
    worth: u64,
};

// Player struct
const Player = struct {
    coins: u64,
};

// Slot symbols
const symbols = [5]Symbol{
    Symbol{.symbol = '7', .worth = 1000},
    Symbol{.symbol = '@', .worth = 500},
    Symbol{.symbol = 'X', .worth = 250},
    Symbol{.symbol = 'Y', .worth = 100},
    Symbol{.symbol = '0', .worth = 50},
};

var symbolsToDraw: [3]Symbol = undefined;

// Terminal size
var ws: std.posix.winsize = undefined;
var MAX_ROWS: u16 = undefined;
var MAX_COLUMNS: u16 = undefined;

// Cooked terminal attributes
var orig: posix.termios = undefined;

// Current and previous window buffer
var previous_buffer: [500][500]Cell = @splat(@splat(EMPTY));
var current_buffer: [500][500]Cell = @splat(@splat(EMPTY));

// Empty cell
const EMPTY: Cell = Cell {.character = ' ', .color = 37};

// Player state
var player: Player = Player{.coins = 0};

// --------------- INIT ----------------

// Sets the terminal size values
fn setTerminalSize() WinsizeError!void {
    const rc = std.os.linux.ioctl(std.posix.STDOUT_FILENO, std.os.linux.T.IOCGWINSZ, @intFromPtr(&ws));

    if (rc >= 0) {
        // Populate size
        MAX_ROWS = ws.row;
        MAX_COLUMNS = ws.col;
    } else {
        return WinsizeError.Failed;
    }
}

fn setTerminalRawMode() !void {
    // Get cooked terminal attributes
    orig = try posix.tcgetattr(posix.STDIN_FILENO);

    var raw = orig;
    raw.lflag.ICANON = false;
    raw.lflag.ECHO = false;
    raw.cc[@intFromEnum(posix.V.MIN)] = 0;
    raw.cc[@intFromEnum(posix.V.TIME)] = 0;
    try posix.tcsetattr(posix.STDIN_FILENO, .FLUSH, raw);
}


// -------------- DRAWING ----------------

// Draw initial slot machine
fn drawSlotMachine() !void {
    clearScreen();

    // Hide cursor
    print("\x1b[?25l", .{});

    // Draw initial slot machine
    current_buffer[10][MAX_COLUMNS/2-8] = Cell {.character = '[', .color = 34 };
    current_buffer[10][MAX_COLUMNS/2-7] = Cell {.character = ' ', .color = 34 };
    current_buffer[10][MAX_COLUMNS/2-6] = Cell {.character = '7', .color = 32 };
    current_buffer[10][MAX_COLUMNS/2-5] = Cell {.character = ' ', .color = 34 };
    current_buffer[10][MAX_COLUMNS/2-4] = Cell {.character = ']', .color = 34 };
    current_buffer[10][MAX_COLUMNS/2-3] = Cell {.character = ' ', .color = 34 };
    current_buffer[10][MAX_COLUMNS/2-2] = Cell {.character = '[', .color = 34 };
    current_buffer[10][MAX_COLUMNS/2-1] = Cell {.character = ' ', .color = 34 };
    current_buffer[10][MAX_COLUMNS/2]   = Cell {.character = '7', .color = 32 };
    current_buffer[10][MAX_COLUMNS/2+1] = Cell {.character = ' ', .color = 34 };
    current_buffer[10][MAX_COLUMNS/2+2] = Cell {.character = ']', .color = 34 };
    current_buffer[10][MAX_COLUMNS/2+3] = Cell {.character = ' ', .color = 34 };
    current_buffer[10][MAX_COLUMNS/2+4] = Cell {.character = '[', .color = 34 };
    current_buffer[10][MAX_COLUMNS/2+5] = Cell {.character = ' ', .color = 34 };
    current_buffer[10][MAX_COLUMNS/2+6] = Cell {.character = '7', .color = 32 };
    current_buffer[10][MAX_COLUMNS/2+7] = Cell {.character = ' ', .color = 34 };
    current_buffer[10][MAX_COLUMNS/2+8] = Cell {.character = ']', .color = 34 };

    try refreshScreenDiff();
}

fn refreshScreenDiff() !void {
    for (current_buffer, 0..) |row, i| {
        for(row, 0..) |cell, j| {
            if (cell.character != previous_buffer[i][j].character or cell.color != previous_buffer[i][j].color) {
                try drawCharAt(@as(u16, @intCast(j))+1, @as(u16, @intCast(i))+1, cell);
            }
        }
    }

    previous_buffer = current_buffer;
}

fn drawCharAt(x: u16, y: u16, cell: Cell) DrawError!void {
    if (x > 0 and y > 0) {
        print("\x1b[{};{}H\x1b[{}m{c}\x1b[0m", .{y, x, cell.color, cell.character});
    }
}

fn spinningAnimation(io: std.Io) !void {
    const min_ms: i64 = 50;
    const max_ms: i64 = 500;
    const interval_ms: i64 = 50;
    var current_ms: i64 = min_ms;

    while(current_ms <= max_ms) : (current_ms += interval_ms) {
        playSound();

        spinLosingSymbols(io);

        current_buffer[10][MAX_COLUMNS/2-6] = Cell {.character = symbolsToDraw[0].symbol, .color = 32};
        current_buffer[10][MAX_COLUMNS/2] = Cell {.character = symbolsToDraw[1].symbol, .color = 32};
        current_buffer[10][MAX_COLUMNS/2+6] = Cell {.character = symbolsToDraw[2].symbol, .color = 32};

        try refreshScreenDiff();
        try io.sleep(std.Io.Duration.fromMilliseconds(current_ms), .awake);
    }
}


// ------------ HELPERS ---------------

fn clearScreen() void {
    print("\x1b[2J", .{});
}

fn resetCursorPos() void {
    print("\x1b[H", .{});
}

fn arrContains(char: u8) bool {
    for (symbolsToDraw) |sym| {
        if (sym.symbol == char) return true;
    }
    return false;
}

fn playSound() void {
    print("\x07", .{});
}

// ----------- FILES ------------
fn writeSavefile(io: std.Io, content: []const u8) !void {
    // Get cwd
    const cwd: std.Io.Dir = std.Io.Dir.cwd();

    // Try to make a new directory - if it exists, do nothing
    cwd.createDir(io, "savefiles", .default_dir) catch |e| switch (e) {
        error.PathAlreadyExists => {},
        else => return e,
    };

    // Open directory
    var output_dir: std.Io.Dir = try cwd.openDir(io, "savefiles", .{});
    defer output_dir.close(io);

    // Open/create file
    const file: std.Io.File = try output_dir.createFile(io, "savefile.txt", .{});
    defer file.close(io);

    // Write to file
    var file_writer = file.writer(io, &.{});
    const writer = &file_writer.interface;

    _ = try writer.write(content);
}

fn readSavefile(io: std.Io, content: []u8) ![]u8 {
    // Get cwd
    const cwd = std.Io.Dir.cwd();

    // Open directory
    var output_dir = try cwd.openDir(io, "savefiles", .{});
    defer output_dir.close(io);

    // Open file
    const file = try output_dir.openFile(io, "savefile.txt", .{});
    defer file.close(io);

    // Read
    var file_reader = file.reader(io, &.{});
    const reader = &file_reader.interface;

    const bytes_read = try std.Io.Reader.readSliceShort(reader, content);

    return content[0..bytes_read];
}

// ----------- GAME LOGIC ------------

fn initPlayer(io: std.Io) !void {
    var content: [64]u8 = undefined;
    const data: []const u8 = try readSavefile(io, &content);

    if (data.len > 0) {
        var it = std.mem.tokenizeAny(u8, data, " =\n");

        var i: usize = 0;
        while (it.next()) |word| {
            i += 1;
            if (i%2 == 0) {
                player.coins = try std.fmt.parseInt(u64, word, 10);
            }
        }
    }
}

fn addCoins(io: std.Io, amount: u64) !void {
    player.coins += amount;
    var buf: [64]u8 = undefined;
    const str = try std.fmt.bufPrint(&buf, "coins={}", .{player.coins});
    try writeSavefile(io, str);
}

fn generateRandomNumber(io: std.Io, comptime T: type, comptime min: T, comptime max: T) T {
    const rng: std.Random.IoSource = .{ .io = io };
    const rand = rng.interface();

    const num = rand.intRangeAtMost(T, min, max);

    return num;
}

fn spinLosingSymbols(io: std.Io) void {
    var i: u8 = 0;
    var tempSym: u8 = undefined;
    while(i < 3) {
        tempSym = generateRandomNumber(io, u8, 0, 4);
        if (!arrContains(tempSym)) {
            symbolsToDraw[i] = symbols[tempSym];
            i += 1;
        }
    }
}

fn spin(io: std.Io) !void {
    try spinningAnimation(io);
    const random_num: u16 = generateRandomNumber(io, u16, 1, 1000);

    playSound();

    switch(random_num) {
        1...800 => {
            spinLosingSymbols(io);
        },
        801...900 => {
            symbolsToDraw = @splat(symbols[4]);
            try addCoins(io, symbols[4].worth);
        },
        901...950 => {
            symbolsToDraw = @splat(symbols[3]);
            try addCoins(io, symbols[3].worth);
        },
        951...980 => {
            symbolsToDraw = @splat(symbols[2]);
            try addCoins(io, symbols[2].worth);
        },
        981...999 => {
            symbolsToDraw = @splat(symbols[1]);
            try addCoins(io, symbols[1].worth);
        },
        1000 => {
            symbolsToDraw = @splat(symbols[0]);
            try addCoins(io, symbols[0].worth);
        },
        else => print("Error", .{}),
    }

    current_buffer[10][MAX_COLUMNS/2-6] = Cell {.character = symbolsToDraw[0].symbol, .color = 32};
    current_buffer[10][MAX_COLUMNS/2] = Cell {.character = symbolsToDraw[1].symbol, .color = 32};
    current_buffer[10][MAX_COLUMNS/2+6] = Cell {.character = symbolsToDraw[2].symbol, .color = 32};

    try refreshScreenDiff();
    print("\n\nPlayer coins: {}", .{player.coins});
}


pub fn main(init: std.process.Init) !void {
    const io = init.io;
    var running = true;

    try initPlayer(io);

    print("Player coins: {}\n", .{player.coins});

    // Get terminal size in rows and columns
    try setTerminalSize();

    // Set terminal into raw mode to enable listening for keystrokes
    try setTerminalRawMode();

    // Reset terminal to cooked mode on exit
    defer _ = posix.tcsetattr(posix.STDIN_FILENO, .FLUSH, orig) catch {};

    // Show cursor on exit
    defer print("\x1b[?25h", .{});

    // Draw initial slot machine
    try drawSlotMachine();

    // Listen for keystrokes
    while (running) {
        var buf: [1]u8 = undefined;
        const read_char = posix.read(posix.STDIN_FILENO, &buf) catch 0;

        // 0 or below is Error
        if (read_char > 0) {
            switch (buf[0]) {
                ' ' => {
                    try spin(io);
                },
                'q' => { 
                    clearScreen();
                    resetCursorPos();
                    running = false; 
                },
                else => {},
            }
        }
    }
    
}
