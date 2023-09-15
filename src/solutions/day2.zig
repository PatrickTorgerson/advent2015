// ********************************************************************************
//  https://github.com/PatrickTorgerson/advent2015
//  Copyright (c) 2023 Patrick Torgerson
//  MIT license, see LICENSE for more information
// ********************************************************************************

//
// https://adventofcode.com/2015/day/2
// https://adventofcode.com/2015/day/2/input
//

const std = @import("std");
const common = @import("../common.zig");
const bench = @import("../benchmark.zig");
const benchmark = bench.benchmark;
const Writer = @import("../Writer.zig");

const input = @embedFile("../input/day2.txt");

/// run and benchmark day 2 solutions
pub fn solve(allocator: std.mem.Allocator, writer: *Writer) anyerror!void {
    const prevns = try bench.prevns(2);
    writer.print("Part 1: ", .{});
    const p1 = try benchmark(allocator, writer, part1, prevns.part1);
    writer.flush();
    writer.print("Part 2: ", .{});
    const p2 = try benchmark(allocator, writer, part2, prevns.part2);
    try bench.avgns(.{ .part1 = p1, .part2 = p2 }, 2);
}

/// The elves are running low on wrapping paper, and so they need to submit an order for more.
/// They have a list of the dimensions (length l, width w, and height h) of each present, and only
/// want to order exactly as much as they need.
///
/// Fortunately, every present is a box (a perfect right rectangular prism), which makes calculating
/// the required wrapping paper for each gift a little easier: find the surface area of the box,
/// which is 2*l*w + 2*w*h + 2*h*l. The elves also need a little extra paper for each present: the
/// area of the smallest side.
///
/// For example:
///
///   - A present with dimensions 2x3x4 requires 2*6 + 2*12 + 2*8 = 52 square feet of wrapping paper
///     plus 6 square feet of slack, for a total of 58 square feet.
///   - A present with dimensions 1x1x10 requires 2*1 + 2*10 + 2*10 = 42 square feet of wrapping paper
///     plus 1 square foot of slack, for a total of 43 square feet.
///
/// All numbers in the elves' list are in feet. How many total square feet of wrapping paper
/// should they order?
fn part1(_: std.mem.Allocator) !i64 {
    var total: i64 = 0;
    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const present = try parsePresent(line);
        total += 2 * present.l * present.w +
            2 * present.w * present.h +
            2 * present.h * present.l;
        const max = @max(present.l, present.w, present.h);
        const min = @min(present.l, present.w, present.h);
        const med = present.l + present.w + present.h - min - max;
        total += min * med;
    }
    return total;
}

/// The elves are also running low on ribbon. Ribbon is all the same width, so they only have to
/// worry about the length they need to order, which they would again like to be exact.
///
/// The ribbon required to wrap a present is the shortest distance around its sides, or the smallest
/// perimeter of any one face. Each present also requires a bow made out of ribbon as well; the feet
/// of ribbon required for the perfect bow is equal to the cubic feet of volume of the present.
/// Don't ask how they tie the bow, though; they'll never tell.
///
/// For example:
///
///   - A present with dimensions 2x3x4 requires 2+2+3+3 = 10 feet of ribbon to wrap the present
///     plus 2*3*4 = 24 feet of ribbon for the bow, for a total of 34 feet.
///   - A present with dimensions 1x1x10 requires 1+1+1+1 = 4 feet of ribbon to wrap the present
///     plus 1*1*10 = 10 feet of ribbon for the bow, for a total of 14 feet.
///
/// How many total feet of ribbon should they order?
fn part2(_: std.mem.Allocator) !i64 {
    var length: i64 = 0;
    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const present = try parsePresent(line);
        const max = @max(present.l, present.w, present.h);
        const min = @min(present.l, present.w, present.h);
        const med = present.l + present.w + present.h - min - max;
        length += min + min + med + med;
        length += min * med * max;
    }
    return length;
}

/// parse an input line into
/// length, width, and height
fn parsePresent(
    str: []const u8,
) !struct { l: i64, w: i64, h: i64 } {
    var nums = std.mem.splitScalar(u8, str, 'x');
    return .{
        .l = try std.fmt.parseInt(i64, nums.next() orelse "", 10),
        .w = try std.fmt.parseInt(i64, nums.next() orelse "", 10),
        .h = try std.fmt.parseInt(i64, nums.next() orelse "", 10),
    };
}
