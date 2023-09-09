// ********************************************************************************
//  https://github.com/PatrickTorgerson/advent2015
//  Copyright (c) 2023 Patrick Torgerson
//  MIT license, see LICENSE for more information
// ********************************************************************************

//
// https://adventofcode.com/2015/day/19
// https://adventofcode.com/2015/day/19/input
//

const std = @import("std");
const common = @import("../common.zig");
const benchmark = @import("../benchmark.zig").benchmark;
const Writer = @import("../Writer.zig");

const input = @embedFile("../input/day19.txt");

pub fn solve(allocator: std.mem.Allocator, writer: *Writer) anyerror!void {
    writer.print("Part 1: ", .{});
    try benchmark(allocator, writer, part1);
    writer.flush();
    writer.print("Part 2: ", .{});
    try benchmark(allocator, writer, part2);
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
