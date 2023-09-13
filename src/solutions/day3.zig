// ********************************************************************************
//  https://github.com/PatrickTorgerson/advent2015
//  Copyright (c) 2023 Patrick Torgerson
//  MIT license, see LICENSE for more information
// ********************************************************************************

//
// https://adventofcode.com/2015/day/3
// https://adventofcode.com/2015/day/3/input
//

const std = @import("std");
const common = @import("../common.zig");
const benchmark = @import("../benchmark.zig").benchmark;
const Writer = @import("../Writer.zig");

const input = @embedFile("../input/day3.txt");

/// run and benchmark day 3 solutions
pub fn solve(allocator: std.mem.Allocator, writer: *Writer) anyerror!void {
    const prevns = try common.prevns(3);
    writer.print("Part 1: ", .{});
    const p1 = try benchmark(allocator, writer, part1, prevns.part1);
    writer.flush();
    writer.print("Part 2: ", .{});
    const p2 = try benchmark(allocator, writer, part2, prevns.part2);
    try common.avgns(.{ .part1 = p1, .part2 = p2 }, 3);
}

/// Santa is delivering presents to an infinite two-dimensional grid of houses.
///
/// He begins by delivering a present to the house at his starting location, and then an elf at the
/// North Pole calls him via radio and tells him where to move next. Moves are always exactly one
/// house to the north (^), south (v), east (>), or west (<). After each move, he delivers another
/// present to the house at his new location.
///
/// However, the elf back at the north pole has had a little too much eggnog, and so his directions
/// are a little off, and Santa ends up visiting some houses more than once. How many houses receive
/// at least one present?
///
/// For example:
///
///   - > delivers presents to 2 houses: one at the starting location, and one to the east.
///   - ^>v< delivers presents to 4 houses in a square, including twice to the house at his starting/ending location.
///   - ^v^v^v^v^v delivers a bunch of presents to some very lucky children at only 2 houses.
///
fn part1(allocator: std.mem.Allocator) !usize {
    var location: struct { i32, i32 } = .{ 0, 0 };
    var visited = std.AutoHashMap(@TypeOf(location), void).init(allocator);
    defer visited.deinit();
    try visited.ensureTotalCapacity(2000);
    try visited.put(location, {});
    for (input) |move| {
        switch (move) {
            '^' => location[1] -= 1,
            '>' => location[0] += 1,
            '<' => location[0] -= 1,
            'v' => location[1] += 1,
            else => {},
        }
        try visited.put(location, {});
    }
    return visited.count();
}

/// The next year, to speed up the process, Santa creates a robot version of himself, Robo-Santa,
/// to deliver presents with him.
///
/// Santa and Robo-Santa start at the same location (delivering two presents to the same starting
/// house), then take turns moving based on instructions from the elf, who is eggnoggedly reading
/// from the same script as the previous year.
///
/// This year, how many houses receive at least one present?
///
/// For example:
///
///   - ^v delivers presents to 3 houses, because Santa goes north, and then Robo-Santa goes south.
///   - ^>v< now delivers presents to 3 houses, and Santa and Robo-Santa end up back where they started.
///   - ^v^v^v^v^v now delivers presents to 11 houses, with Santa going one direction and Robo-Santa going the other.
///
fn part2(allocator: std.mem.Allocator) !usize {
    var locations: [2]struct { i32, i32 } = .{ .{ 0, 0 }, .{ 0, 0 } };
    var visited = std.AutoHashMap(@TypeOf(locations[0]), void).init(allocator);
    defer visited.deinit();
    try visited.ensureTotalCapacity(2000);
    try visited.put(locations[0], {});
    for (input, 0..) |move, i| {
        const l = i % 2;
        switch (move) {
            '^' => locations[l][1] -= 1,
            '>' => locations[l][0] += 1,
            '<' => locations[l][0] -= 1,
            'v' => locations[l][1] += 1,
            else => {},
        }
        try visited.put(locations[l], {});
    }
    return visited.count();
}
