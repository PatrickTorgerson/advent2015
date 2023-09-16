// ********************************************************************************
//  https://github.com/PatrickTorgerson/advent2015
//  Copyright (c) 2023 Patrick Torgerson
//  MIT license, see LICENSE for more information
// ********************************************************************************

//
// https://adventofcode.com/2015/day/5
// https://adventofcode.com/2015/day/5/input
//

const std = @import("std");
const common = @import("../common.zig");
const bench = @import("../benchmark.zig");
const benchmark = bench.benchmark;
const Writer = @import("../Writer.zig");

const input = @embedFile("../input/day5.txt");

/// run and benchmark day 5 solutions
pub fn solve(allocator: std.mem.Allocator, writer: *Writer) anyerror!void {
    const prevns = try bench.prevns(5);
    writer.print("Part 1: ", .{});
    const p1 = try benchmark(allocator, writer, part1, prevns.part1);
    writer.flush();
    writer.print("Part 2: ", .{});
    const p2 = try benchmark(allocator, writer, part2, prevns.part2);
    try bench.avgns(.{ .part1 = p1, .part2 = p2 }, 5);
}

/// Santa needs help figuring out which strings in his text file are naughty or nice.
///
/// A nice string is one with all of the following properties:
///
///   - It contains at least three vowels (aeiou only), like aei, xazegov, or aeiouaeiouaeiou.
///   - It contains at least one letter that appears twice in a row, like xx, abcdde (dd), or
///     aabbccdd (aa, bb, cc, or dd).
///   - It does not contain the strings ab, cd, pq, or xy, even if they are part of one of the other
///     requirements.
///
/// For example:
///
///   - `ugknbfddgicrmopn` is nice because it has at least three vowels (u...i...o...), a double
///     letter (...dd...), and none of the disallowed substrings.
///   - `aaa` is nice because it has at least three vowels and a double letter, even though the
///     letters used by different rules overlap.
///   - `jchzalrnumimnmhp` is naughty because it has no double letter.
///   - `haegwjzuvuyypxyu` is naughty because it contains the string xy.
///   - `dvszwmarrgswjxmb` is naughty because it contains only one vowel.
///
/// How many strings are nice?
fn part1(_: std.mem.Allocator) !i32 {
    var lines = std.mem.splitScalar(u8, input, '\n');
    var nice_count: i32 = 0;
    while (lines.next()) |line| {
        nice_count += if (isNiceP1(line)) 1 else 0;
    }
    return nice_count;
}

/// Realizing the error of his ways, Santa has switched to a better model of determining whether a
/// string is naughty or nice. None of the old rules apply, as they are all clearly ridiculous.
///
/// Now, a nice string is one with all of the following properties:
///
///   - It contains a pair of any two letters that appears at least twice in the string without
///     overlapping, like xyxy (xy) or aabcdefgaa (aa), but not like aaa (aa, but it overlaps).
///   - It contains at least one letter which repeats with exactly one letter between them, like xyx,
///     abcdefeghi (efe), or even aaa.
///
/// For example:
///
///   - `qjhvhtzxzqqjkmpb` is nice because is has a pair that appears twice (qj) and a letter that
///     repeats with exactly one letter between them (zxz).
///   - `xxyxx` is nice because it has a pair that appears twice and a letter that repeats with one
///     between, even though the letters used by each rule overlap.
///   - `uurcxstgmygtbstg` is naughty because it has a pair (tg) but no repeat with a single letter
///     between them.
///   - `ieodomkazucvgmuy` is naughty because it has a repeating letter with one between (odo), but
///     no pair that appears twice.
///
/// How many strings are nice under these new rules?
fn part2(_: std.mem.Allocator) !i32 {
    var lines = std.mem.splitScalar(u8, input, '\n');
    var nice_count: i32 = 0;
    while (lines.next()) |line| {
        nice_count += if (isNiceP2(line)) 1 else 0;
    }
    return nice_count;
}

/// determines if a string is nice based on part 1 rules:
///
///   - It contains at least three vowels (aeiou only), like aei, xazegov, or aeiouaeiouaeiou.
///   - It contains at least one letter that appears twice in a row, like xx, abcdde (dd), or
///     aabbccdd (aa, bb, cc, or dd).
///   - It does not contain the strings ab, cd, pq, or xy, even if they are part of one of the other
///     requirements.
fn isNiceP1(str: []const u8) bool {
    if (str.len == 0) return false;
    var vowels: i32 = 0;
    var doubles: i32 = 0;
    var i: usize = 0;
    while (i < str.len) : (i += 1) {
        if (std.mem.indexOfScalar(u8, "aeiou", str[i])) |_|
            vowels += 1;
        if (i + 1 < str.len) {
            if (str[i] == str[i + 1]) doubles += 1;
            if (std.mem.indexOfScalar(u8, "acpx", str[i])) |_| {
                if (str[i + 1] == str[i] + 1) {
                    return false;
                }
            }
        }
    }
    return vowels > 2 and doubles > 0;
}

/// determines if a string is nice based on part 2 rules:
///
///   - It contains a pair of any two letters that appears at least twice in the string without
///     overlapping, like xyxy (xy) or aabcdefgaa (aa), but not like aaa (aa, but it overlaps).
///   - It contains at least one letter which repeats with exactly one letter between them, like xyx,
///     abcdefeghi (efe), or even aaa.
fn isNiceP2(str: []const u8) bool {
    if (str.len == 0) return false;
    var has_repeat: bool = false;
    var has_pair: bool = false;
    var i: usize = 1;
    while (i < str.len - 1) : (i += 1) {
        if (!has_pair) {
            if (std.mem.indexOf(u8, str[i + 1 ..], str[i - 1 .. i + 1])) |_| {
                has_pair = true;
                if (has_repeat) return true;
            }
        }
        if (!has_repeat and i + 1 < str.len and str[i - 1] == str[i + 1]) {
            has_repeat = true;
            if (has_pair) return true;
        }
    }
    return has_pair and has_repeat;
}
