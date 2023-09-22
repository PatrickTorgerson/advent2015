// ********************************************************************************
//  https://github.com/PatrickTorgerson/advent2015
//  Copyright (c) 2023 Patrick Torgerson
//  MIT license, see LICENSE for more information
// ********************************************************************************

//
// https://adventofcode.com/2015/day/6
// https://adventofcode.com/2015/day/6/input
//

const std = @import("std");
const common = @import("../common.zig");
const bench = @import("../benchmark.zig");
const benchmark = bench.benchmark;
const Writer = @import("../Writer.zig");

const input = @embedFile("../input/day6.txt");

/// run and benchmark day 6 solutions
pub fn solve(allocator: std.mem.Allocator, writer: *Writer) anyerror!void {
    const prevns = try bench.prevns(6);
    writer.print("Part 1: ", .{});
    const p1 = try benchmark(allocator, writer, part1, prevns.part1);
    writer.flush();
    writer.print("Part 2: ", .{});
    const p2 = try benchmark(allocator, writer, part2, prevns.part2);
    try bench.avgns(.{ .part1 = p1, .part2 = p2 }, 6);
}

/// Because your neighbors keep defeating you in the holiday house decorating contest year after
/// year, you've decided to deploy one million lights in a 1000x1000 grid.
///
/// Furthermore, because you've been especially nice this year, Santa has mailed you instructions
/// on how to display the ideal lighting configuration.
///
/// Lights in your grid are numbered from 0 to 999 in each direction; the lights at each corner are
/// at 0,0, 0,999, 999,999, and 999,0. The instructions include whether to turn on, turn off, or
/// toggle various inclusive ranges given as coordinate pairs. Each coordinate pair represents
/// opposite corners of a rectangle, inclusive; a coordinate pair like 0,0 through 2,2 therefore
/// refers to 9 lights in a 3x3 square. The lights all start turned off.
///
/// To defeat your neighbors this year, all you have to do is set up your lights by doing the
/// instructions Santa sent you in order.
///
/// For example:
///
///   - turn on 0,0 through 999,999 would turn on (or leave on) every light.
///   - toggle 0,0 through 999,0 would toggle the first line of 1000 lights, turning off the ones
///     that were on, and turning on the ones that were off.
///   - turn off 499,499 through 500,500 would turn off (or leave off) the middle four lights.
///
/// After following the instructions, how many lights are lit?
fn part1(_: std.mem.Allocator) !usize {
    var rows = [_]std.bit_set.StaticBitSet(1000){std.bit_set.StaticBitSet(1000).initEmpty()} ** 1000;
    var lines = std.mem.splitScalar(u8, input, '\n');
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const ins = try parseIns(line);
        var rr = rows[ins.p1[1] .. ins.p2[1] + 1];
        switch (ins.op) {
            .toggle => {
                var mask = std.bit_set.StaticBitSet(1000).initEmpty();
                mask.setRangeValue(.{ .start = ins.p1[0], .end = ins.p2[0] + 1 }, true);
                for (rr) |*r|
                    r.toggleSet(mask);
            },
            .turn_on => {
                for (rr) |*r|
                    r.setRangeValue(.{ .start = ins.p1[0], .end = ins.p2[0] + 1 }, true);
            },
            .turn_off => {
                for (rr) |*r|
                    r.setRangeValue(.{ .start = ins.p1[0], .end = ins.p2[0] + 1 }, false);
            },
        }
    }
    var total: usize = 0;
    for (rows) |r|
        total += r.count();
    return total;
}

/// You just finish implementing your winning light pattern when you realize you mistranslated
/// Santa's message from Ancient Nordic Elvish.
///
/// The light grid you bought actually has individual brightness controls; each light can have a
/// brightness of zero or more. The lights all start at zero.
///
/// The phrase turn on actually means that you should increase the brightness of those lights by 1.
///
/// The phrase turn off actually means that you should decrease the brightness of those lights by 1,
/// to a minimum of zero.
///
/// The phrase toggle actually means that you should increase the brightness of those lights by 2.
///
/// What is the total brightness of all lights combined after following Santa's instructions?
///
/// For example:
///
///   - turn on 0,0 through 0,0 would increase the total brightness by 1.
///   - toggle 0,0 through 999,999 would increase the total brightness by 2000000.
///
fn part2(_: std.mem.Allocator) !usize {
    var total: usize = 0;
    var lines = std.mem.splitScalar(u8, input, '\n');
    var rows = [_]@Vector(1000, u16){@splat(0)} ** 1000;
    while (lines.next()) |line| {
        if (line.len == 0) continue;
        const ins = try parseIns(line);
        var rr = rows[ins.p1[1] .. ins.p2[1] + 1];
        const area = (ins.p2[0] + 1 - ins.p1[0]) *
            (ins.p2[1] + 1 - ins.p1[1]);
        var mask: @Vector(1000, u16) = @splat(0);
        for (ins.p1[0]..ins.p2[0] + 1) |i|
            mask[i] = 1;
        switch (ins.op) {
            .toggle => {
                total += area * 2;
                for (rr) |*r|
                    r.* += mask * @as(@Vector(1000, u16), @splat(2));
            },
            .turn_on => {
                total += area;
                for (rr) |*r|
                    r.* += mask;
            },
            .turn_off => {
                for (rr) |*r| {
                    const before = @reduce(.Add, r.*);
                    r.* -|= mask;
                    total -= before - @reduce(.Add, r.*);
                }
            },
        }
    }
    return total;
}

fn parseIns(str: []const u8) !struct {
    op: Op,
    p1: [2]u32,
    p2: [2]u32,
} {
    var words = std.mem.splitAny(u8, str, " ,");
    var op: Op = if (words.next()) |word| blk_op: {
        if (std.mem.eql(u8, word, "toggle"))
            break :blk_op .toggle;
        if (std.mem.eql(u8, word, "turn")) {
            switch (words.next().?[1]) {
                'n' => break :blk_op .turn_on,
                'f' => break :blk_op .turn_off,
                else => unreachable,
            }
        }
        unreachable;
    } else unreachable;
    const x1 = try std.fmt.parseInt(u32, words.next().?, 10);
    const y1 = try std.fmt.parseInt(u32, words.next().?, 10);
    _ = words.next(); // through
    const x2 = try std.fmt.parseInt(u32, words.next().?, 10);
    const y2 = try std.fmt.parseInt(u32, words.next().?, 10);
    return .{
        .op = op,
        .p1 = [_]u32{ x1, y1 },
        .p2 = [_]u32{ x2, y2 },
    };
}

const Op = enum { toggle, turn_on, turn_off };
