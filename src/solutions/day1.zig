// ********************************************************************************
//  https://github.com/PatrickTorgerson/advent2015
//  Copyright (c) 2023 Patrick Torgerson
//  MIT license, see LICENSE for more information
// ********************************************************************************

//
// https://adventofcode.com/2015/day/1
// https://adventofcode.com/2015/day/1/input
//

const std = @import("std");
const common = @import("../common.zig");
const benchmark = @import("../benchmark.zig").benchmark;
const Writer = @import("../Writer.zig");

const input = @embedFile("../input/day1.txt");

/// run and benchmark day 1 solutions
pub fn solve(allocator: std.mem.Allocator, writer: *Writer) anyerror!void {
    writer.print("Part 1: ", .{});
    try benchmark(allocator, writer, part1);
    writer.flush();
    writer.print("Part 2: ", .{});
    try benchmark(allocator, writer, part2);
}

/// Santa is trying to deliver presents in a large apartment building, but he can't find the right
/// floor - the directions he got are a little confusing. He starts on the ground floor (floor 0)
/// and then follows the instructions one character at a time.
///
/// An opening parenthesis, (, means he should go up one floor, and a closing parenthesis, ),
/// means he should go down one floor.
///
/// The apartment building is very tall, and the basement is very deep; he will never find the
/// top or bottom floors.
///
/// For example:
///
///   - (()) and ()() both result in floor 0.
///   - ((( and (()(()( both result in floor 3.
///   - ))((((( also results in floor 3.
///   - ()) and ))( both result in floor -1 (the first basement level).
///   - ))) and )())()) both result in floor -3.
///
/// To what floor do the instructions take Santa?
fn part1(_: std.mem.Allocator) !i64 {
    var floor: i64 = 0;
    for (input) |dir| {
        floor += switch (dir) {
            '(' => 1,
            ')' => -1,
            else => 0,
        };
    }
    return floor;
}

/// Now, given the same instructions, find the position of the first character that causes him to
/// enter the basement (floor -1). The first character in the instructions has position 1, the
/// second character has position 2, and so on.
///
/// For example:
///
///   - ) causes him to enter the basement at character position 1.
///   - ()()) causes him to enter the basement at character position 5.
///
/// What is the position of the character that causes Santa to first enter the basement?
fn part2(_: std.mem.Allocator) !usize {
    var floor: i64 = 0;
    for (input, 0..) |dir, i| {
        floor += switch (dir) {
            '(' => 1,
            ')' => -1,
            else => 0,
        };
        if (floor < 0) return i + 1;
    }
    return 0;
}
