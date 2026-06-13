// Winsize Error
pub const WinsizeError = error {
    Failed,
};

// Draw Error
pub const DrawError = error {
    InvalidCoordinate,
};

// Cell struct
pub const Cell = struct {
    character: u8,
    color: u8,
};

// Symbol struct
pub const Symbol = struct {
    symbol: u8,
    color: u8,
    worth: u64,
};

// Player struct
pub const Player = struct {
    coins: u64,
};
