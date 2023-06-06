const std = @import("std");

// extern functions refer to the exterior JS namespace
// when importing wasm code, the `print` func must be provided
extern fn print(i32) void;

// change these three for your game grid
const WIDTH: u32 = 32;
const HEIGHT: u32 = 32;
const NUM_CELLS: u32 = HEIGHT * WIDTH;

// Create a Cell-type value
// force it to a one-type value for performance
const Cell = enum(u8) {
    Dead,
    Alive,
};

// Create a struct which has a constant world size
const World = struct {
    cells: [NUM_CELLS]Cell = undefined,
};

// this  is our invisible data structure for manipulation
var WORLD = World{
    .cells = undefined,
};

// Get neighbors in an area
export fn get_neighbors(index: u32) u8 {
    var num_neighbors: u8 = 0;
    var x: u32 = index % WIDTH;
    var y: u32 = index / WIDTH;
    var i: i32 = @intCast(i32, x) - 1;
    while (i <= x + 1) : (i += 1) {
        var j: i32 = @intCast(i32, y) - 1;
        while (j <= y + 1) : (j += 1) {
            if (i != x or j != y) { // not counting ourself.
                // print(i + j * @intCast(i32, WIDTH));
                if (get_cell(i, j) == .Alive) {
                    // print(1);
                    num_neighbors += 1;
                }
            }
        }
    }
    return num_neighbors;
}

fn get_cell(x: i32, y: i32) Cell {
    var index: i32 = x + y * WIDTH;
    if ((index < 0) or (index >= NUM_CELLS)) return .Dead;
    return WORLD.cells[@intCast(u32, index)];
}

// Advance the world by strong mutation
export fn advance() u32 {
    var cell_buf: [NUM_CELLS]Cell = undefined;
    var num_neighbors: u8 = 0;
    var i: u32 = 0;
    var num_changed: u32 = 0;
    while (i < NUM_CELLS) : (i += 1) {
        num_neighbors = get_neighbors(i);
        switch (WORLD.cells[i]) {
            .Dead => {
                if (num_neighbors == 3) {
                    cell_buf[i] = Cell.Alive;
                    num_changed += 1;
                }
            },
            .Alive => {
                if ((num_neighbors < 2) or (num_neighbors > 3)) {
                    cell_buf[i] = Cell.Dead;
                    num_changed += 1;
                }
            },
        }
    }
    WORLD.cells = cell_buf;
    return num_changed;
}

export fn set_cell(index: u32) void {
    if (index > NUM_CELLS) return;
    WORLD.cells[index] = .Alive;
}

export fn get_char(index: u32) u32 {
    if (index > NUM_CELLS) return '◻';
    return switch (WORLD.cells[index]) {
        .Dead => {
            return '◻';
        },
        .Alive => {
            return '◼';
        },
    };
}

test "why the hell get_neighbors(65+) breaks" {
    set_cell(0);
    var some_val = get_neighbors(65);
    try std.testing.expect(some_val == 0);
}

test "why the hell can't we advance" {
    set_cell(0);
    var how_many = advance();
    try std.testing.expect(how_many == 0);
}

test "why the hell can't i get a char" {
    set_cell(0);
    var some_v = get_char(0);
    try std.testing.expect(some_v == '◻');

    some_v = get_char(3);
    try std.testing.expect(some_v == '◻');

    some_v = get_char(1024);
    try std.testing.expect(some_v == '◻');
}
