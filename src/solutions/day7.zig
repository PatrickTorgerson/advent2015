// ********************************************************************************
//  https://github.com/PatrickTorgerson/advent2015
//  Copyright (c) 2023 Patrick Torgerson
//  MIT license, see LICENSE for more information
// ********************************************************************************

//
// https://adventofcode.com/2015/day/7
// https://adventofcode.com/2015/day/7/input
//

const std = @import("std");
const common = @import("../common.zig");
const bench = @import("../benchmark.zig");
const benchmark = bench.benchmark;
const Writer = @import("../Writer.zig");

const input = @embedFile("../input/day7.txt");

/// run and benchmark day 7 solutions
pub fn solve(allocator: std.mem.Allocator, writer: *Writer) anyerror!void {
    const prevns = try bench.prevns(7);
    writer.print("Part 1: ", .{});
    const p1 = try benchmark(allocator, writer, part1, prevns.part1);
    writer.flush();
    writer.print("Part 2: ", .{});
    const p2 = try benchmark(allocator, writer, part2, prevns.part2);
    try bench.avgns(.{ .part1 = p1, .part2 = p2 }, 7);
}

/// PART 1 DESCRIPTION
fn part1(allocator: std.mem.Allocator) ![]const u8 {
    _ = allocator;
    return "not implemented";
}

/// PART 2 DESCRIPTION
fn part2(allocator: std.mem.Allocator) ![]const u8 {
    _ = allocator;
    return "not implemented";
}
