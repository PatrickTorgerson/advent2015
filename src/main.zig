// ********************************************************************************
//  https://github.com/PatrickTorgerson/advent2015
//  Copyright (c) 2023 Patrick Torgerson
//  MIT license, see LICENSE for more information
// ********************************************************************************

// https://adventofcode.com/2015

const std = @import("std");
const Writer = @import("Writer.zig");
const bench = @import("benchmark.zig");

const help =
    \\
    \\ Run a solution to an Advent of Code 2015 puzzle
    \\
    \\ USEAGE:
    \\   advent2015 `day`
    \\       where `day` is an integer between 1 and {} inclusive
    \\   advent2015 times
    \\       display cached times for all solutions
    \\
    \\
;

pub const benchmark_iterations = 100;
pub const benchmark_file = "benchmark.dat";
const run_times = 666;

const SlnFn = *const fn (std.mem.Allocator, *Writer) anyerror!void;
const solutions = [_]SlnFn{
    @import("solutions/day1.zig").solve,
    @import("solutions/day2.zig").solve,
    @import("solutions/day3.zig").solve,
    @import("solutions/day4.zig").solve,
    @import("solutions/day5.zig").solve,
    @import("solutions/day6.zig").solve,
    @import("solutions/day7.zig").solve,
    @import("solutions/day8.zig").solve,
    @import("solutions/day9.zig").solve,
    @import("solutions/day10.zig").solve,
    @import("solutions/day11.zig").solve,
    @import("solutions/day12.zig").solve,
    @import("solutions/day13.zig").solve,
    @import("solutions/day14.zig").solve,
    @import("solutions/day15.zig").solve,
    @import("solutions/day16.zig").solve,
    @import("solutions/day17.zig").solve,
    @import("solutions/day18.zig").solve,
    @import("solutions/day19.zig").solve,
    @import("solutions/day20.zig").solve,
    @import("solutions/day21.zig").solve,
    @import("solutions/day22.zig").solve,
    @import("solutions/day23.zig").solve,
    @import("solutions/day24.zig").solve,
    @import("solutions/day25.zig").solve,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var allocator = gpa.allocator();

    var writer: Writer = undefined;
    writer.init();
    defer writer.flush();

    const day = getDay(allocator) orelse {
        writer.print(help, .{solutions.len});
        return;
    };

    if (day == run_times) {
        const times = try bench.readall();
        writer.print("\n              part 1       part 2\n", .{});
        writer.print("-------------------------------------\n", .{});
        for (&times, 0..) |t, d| {
            if (t.part1 == 0 and t.part2 == 0) continue;
            const ms1 = @as(f64, @floatFromInt(t.part1)) / @as(f64, @floatFromInt(std.time.ns_per_ms));
            const ms2 = @as(f64, @floatFromInt(t.part1)) / @as(f64, @floatFromInt(std.time.ns_per_ms));
            writer.print(" Day {: >2}: {d: >10.4}ms {d: >10.4}ms\n", .{ d + 1, ms1, ms2 });
        }
        writer.print("\n", .{});
    } else {
        writer.print("\n==== Running day {} ====\n\n", .{day + 1});
        try solutions[day](allocator, &writer);
    }
}

fn getDay(allocator: std.mem.Allocator) ?usize {
    var args = std.process.argsWithAllocator(allocator) catch return null;
    defer args.deinit();
    _ = args.next(); // ignore executable path
    if (args.next()) |day_str| {
        if (std.mem.eql(u8, day_str, "times"))
            return run_times;
        const day = std.fmt.parseInt(i32, day_str, 10) catch return null;
        if (day < 1 or day > solutions.len)
            return null;
        return @intCast(day - 1);
    } else return null;
}
