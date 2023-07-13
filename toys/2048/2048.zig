const std = @import("std");
const builtin = @import("builtin");
const ArrayList = std.ArrayList;
const allotor = std.heap.page_allocator;

const GRID_LEN: u8 = 4;
const W_SIZE: u32 = GRID_LEN * GRID_LEN;
const RND_NUM: u8 = 1;

const Direction = enum(u8) {
    Up = 0,
    Down = 1,
    Left = 2,
    Right = 3,
    Null = 4,
};

const State = struct {
    victory: bool,
    cells: [W_SIZE]u32,
};

var WORLD = State{
    .victory = false,
    .cells = undefined,
};

extern fn print(i32) void;
extern fn rand(i: i32) i32;

export fn is_won() bool {
    return WORLD.victory;
}

fn calc_pos(x: u8, y: u8) u32 {
    return x + y * (GRID_LEN);
}

export fn get_pos(x: u8, y: u8) u32 {
    var index = calc_pos(x, y);
    if (index < W_SIZE)
        return WORLD.cells[index];
    return 0;
}

fn set_pos(x: u8, y: u8, v: u32) bool {
    var index = calc_pos(x, y);
    if (index >= W_SIZE)
        return false;

    WORLD.cells[index] = v;
    return true;
}

/// Set up world state, create a plus sign in the middle
export fn init() void {
    var index: u32 = 0;
    while (index < W_SIZE) : (index += 1) {
        WORLD.cells[index] = 0;
    }
    init_add_rand();
    WORLD.victory = false;
    return;
}

/// Update our world by attempting to move the player somewhere
export fn update(dir: Direction) void {
    switch (dir) {
        .Up => {
            // 反转 =》 压缩 =》 反转
            reverse();
            compress();
            reverse();
        },
        .Down => {
            // 压缩
            compress();
        },
        .Left => {
            // 转置 =》 反转 =》 压缩 =》 反转 =》 转置
            transpose();
            reverse();
            compress();
            reverse();
            transpose();
        },
        .Right => {
            // 转置 =》 压缩 =》 转置
            transpose();
            compress();
            transpose();
        },
        else => {},
    }

    update_game_status();
    return;
}

fn init_add_rand() void {
    for (0..3) |_| {
        _ = add_next_and();
    }
}

fn add_next_and() void {
    var list = ArrayList(u32).init(allotor);
    defer list.deinit();

    for (WORLD.cells, 0..) |v, i| {
        if (v == 0) {
            list.append(@as(u32, @intCast(i))) catch {};
        }
    }

    if (list.items.len < 1) {
        return;
    }
    var i: u8 = 0;
    while (i < RND_NUM and i < list.items.len) {
        var l = getRandI(@as(u32, @intCast(list.items.len)));
        const location_index = list.items[l];
        if (WORLD.cells[location_index] == 0) {
            var num = std.math.pow(u32, 2, getRandI(@as(u32, @intCast(4))) + 1);
            WORLD.cells[location_index] = num;
            i += 1;
            _ = list.swapRemove(l);
        }
    }
}

fn getRandI(max: u32) u32 {
    if (builtin.os.tag == .macos) {
        var rnd = std.crypto.random;
        var r = rnd.intRangeLessThan(u32, 0, max);
        return r;
    } else {
        return @intCast(rand(@intCast(max)));
    }
}

/// 移动
fn cover_up() bool {
    var temp: [W_SIZE]u32 = [_]u32{0} ** W_SIZE;
    var moved = false;
    for (0..GRID_LEN) |i| {
        var count: u8 = GRID_LEN - 1;
        for (0..GRID_LEN) |j| {
            if (get_pos(@intCast(i), @intCast(GRID_LEN - 1 - j)) != 0) {
                temp[calc_pos(@as(u8, @intCast(i)), count)] = get_pos(@as(u8, @intCast(i)), @as(u8, @intCast(GRID_LEN - 1 - j)));
                if (count != GRID_LEN - 1 - j) {
                    moved = true;
                }
                if (count >= 1) count -= 1;
            }
        }
    }
    WORLD.cells = temp;
    return moved;
}

/// 合并
fn merge() bool {
    var merged = false;
    for (0..GRID_LEN) |i| {
        for (0..GRID_LEN) |j| {
            if (get_pos(@as(u8, @intCast(i)), @as(u8, @intCast(j))) == get_pos(@as(u8, @intCast(i)), @as(u8, @intCast(j + 1))) and get_pos(@as(u8, @intCast(i)), @as(u8, @intCast(j))) != 0) {
                WORLD.cells[calc_pos(@as(u8, @intCast(i)), @as(u8, @intCast(j)))] = 0;
                WORLD.cells[calc_pos(@as(u8, @intCast(i)), @as(u8, @intCast(j + 1)))] = WORLD.cells[calc_pos(@as(u8, @intCast(i)), @as(u8, @intCast(j + 1)))] * 2;
                merged = true;
            }
        }
    }
    return merged;
}

/// 压缩 ==》 移动 =》 合并 =》 移动
fn compress() void {
    _ = cover_up();
    var moved = merge();
    _ = cover_up();
    if (!moved) {
        add_next_and();
    }
}

/// 更新状态
fn update_game_status() void {
    var can_move = false;
    outer: for (0..GRID_LEN) |i| {
        for (0..GRID_LEN) |j| {
            var col_index = i + (GRID_LEN) * j;
            if (col_index + 1 >= W_SIZE) {
                continue;
            }
            if (WORLD.cells[col_index] == 0 or WORLD.cells[col_index] == WORLD.cells[col_index + 1]) {
                can_move = true;
                break :outer;
            }

            var row_index = i * (GRID_LEN) + j;
            if (row_index + 1 >= W_SIZE) {
                continue;
            }
            if (WORLD.cells[row_index] == 0 or WORLD.cells[row_index] == WORLD.cells[row_index + 1]) {
                can_move = true;
                break :outer;
            }
        }
    }

    WORLD.victory = !can_move;
}

/// 转置变形
fn transpose() void {
    var temp = [_]u32{0} ** W_SIZE;
    for (0..GRID_LEN) |i| {
        for (0..GRID_LEN) |j| {
            temp[calc_pos(@as(u8, @intCast(i)), @as(u8, @intCast(j)))] = WORLD.cells[calc_pos(@as(u8, @intCast(j)), @as(u8, @intCast(i)))];
        }
    }
    WORLD.cells = temp;
}

/// 反转
fn reverse() void {
    var temp = [_]u32{0} ** W_SIZE;
    for (0..GRID_LEN) |i| {
        for (0..GRID_LEN) |j| {
            temp[calc_pos(@as(u8, @intCast(i)), @as(u8, @intCast(j)))] = WORLD.cells[calc_pos(@as(u8, @intCast(i)), @as(u8, @intCast(GRID_LEN - j - 1)))];
        }
    }
    WORLD.cells = temp;
}

fn print_world() void {
    std.debug.print("\n", .{});
    for (0..W_SIZE) |i| {
        std.debug.print("{any:4} ", .{WORLD.cells[i]});
        if ((i + 1) % GRID_LEN == 0) {
            std.debug.print("\n", .{});
        }
    }
}

fn test_init() void {
    init();
    for (0..4) |i| {
        WORLD.cells[calc_pos(@as(u8, @intCast(i)), 1)] = 1;
        WORLD.cells[calc_pos(3, @as(u8, @intCast(i)))] = 1;
    }
}

test "cover_up" {
    test_init();
    print_world();
    _ = cover_up();
    print_world();
}

test "transpose" {
    test_init();
    print_world();
    transpose();
    print_world();
}

test "merge" {
    test_init();
    print_world();
    _ = merge();
    print_world();
}

test "down" {
    test_init();
    print_world();
    update(.Down);
    print_world();
}

test "up" {
    test_init();
    print_world();
    update(.Up);
    print_world();
}

test "left" {
    test_init();
    print_world();
    update(.Left);
    print_world();
}

test "right" {
    WORLD.cells[0] = 16;
    WORLD.cells[1] = 64;
    WORLD.cells[2] = 16;
    WORLD.cells[3] = 256;
    WORLD.cells[4] = 0;
    WORLD.cells[5] = 64;
    WORLD.cells[6] = 8;
    WORLD.cells[7] = 128;
    WORLD.cells[8] = 16;
    WORLD.cells[9] = 16;
    WORLD.cells[10] = 128;
    WORLD.cells[11] = 256;
    WORLD.cells[12] = 16;
    WORLD.cells[13] = 256;
    WORLD.cells[14] = 32;
    WORLD.cells[15] = 64;

    print_world();
    update(.Right);
    print_world();
}

test "add_next_and" {
    WORLD.cells[0] = 16;
    WORLD.cells[1] = 64;
    WORLD.cells[2] = 16;
    WORLD.cells[3] = 256;
    WORLD.cells[4] = 0;
    WORLD.cells[5] = 64;
    WORLD.cells[6] = 8;
    WORLD.cells[7] = 128;
    WORLD.cells[8] = 16;
    WORLD.cells[9] = 16;
    WORLD.cells[10] = 128;
    WORLD.cells[11] = 256;
    WORLD.cells[12] = 16;
    WORLD.cells[13] = 256;
    WORLD.cells[14] = 32;
    WORLD.cells[15] = 64;
    print_world();
    _ = add_next_and();
    // add_rnd(items[0..]) catch {};
    print_world();
}
