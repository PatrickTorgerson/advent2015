// ********************************************************************************
//  https://github.com/PatrickTorgerson/advent2015
//  Copyright (c) 2023 Patrick Torgerson
//  MIT license, see LICENSE for more information
// ********************************************************************************

//
// https://adventofcode.com/2015/day/4
// https://adventofcode.com/2015/day/4/input
//

const std = @import("std");
const common = @import("../common.zig");
const bench = @import("../benchmark.zig");
const benchmark = bench.benchmark;
const Writer = @import("../Writer.zig");

const input = @embedFile("../input/day4.txt");

/// run and benchmark day 4 solutions
pub fn solve(allocator: std.mem.Allocator, writer: *Writer) anyerror!void {
    const prevns = try bench.prevns(4);
    writer.print("Part 1: ", .{});
    const p1 = try benchmark(allocator, writer, part1, prevns.part1);
    writer.flush();
    writer.print("Part 2: ", .{});
    const p2 = try benchmark(allocator, writer, part2, prevns.part2);
    try bench.avgns(.{ .part1 = p1, .part2 = p2 }, 4);
}

/// Santa needs help mining some AdventCoins (very similar to bitcoins) to use as gifts for all the
/// economically forward-thinking little girls and boys.
///
/// To do this, he needs to find MD5 hashes which, in hexadecimal, start with at least five zeroes.
/// The input to the MD5 hash is some secret key (your puzzle input, given below) followed by a
/// number in decimal. To mine AdventCoins, you must find Santa the lowest positive number
/// (no leading zeroes: 1, 2, 3, ...) that produces such a hash.
///
/// For example:
///
///   - If your secret key is abcdef, the answer is 609043, because the MD5 hash of abcdef609043
///     starts with five zeroes (000001dbbfa...), and it is the lowest such number to do so.
///   - If your secret key is pqrstuv, the lowest number it combines with to make an MD5 hash
///     starting with five zeroes is 1048970; that is, the MD5 hash of pqrstuv1048970 looks like 000006136ef....
///
fn part1(allocator: std.mem.Allocator) !u64 {
    var buffer = try std.ArrayList(u8).initCapacity(allocator, input.len + 32);
    defer buffer.deinit();
    try buffer.appendSlice(input[0..8]);
    const num_start = buffer.items.len;
    var num: u64 = 1;
    while (num < std.math.maxInt(u64) - 1) {
        buffer.items.len = num_start;
        try buffer.writer().print("{}", .{num});
        const digest = md5(buffer.items);
        if (digest[0] == 0 and digest[1] == 0 and digest[2] <= 15) {
            return num;
        }
        num += 1;
    }
    return std.math.maxInt(u64);
}

/// Now find one that starts with six zeroes.
fn part2(allocator: std.mem.Allocator) !u64 {
    var buffer = try std.ArrayList(u8).initCapacity(allocator, input.len + 32);
    try buffer.appendSlice(input[0..8]);
    defer buffer.deinit();
    const num_start = buffer.items.len;
    var num: u64 = 1;
    while (num < std.math.maxInt(u64) - 1) {
        buffer.items.len = num_start;
        try buffer.writer().print("{}", .{num});
        const digest = md5(buffer.items);
        if (digest[0] == 0 and digest[1] == 0 and digest[2] == 0) {
            return num;
        }
        num += 1;
    }
    return std.math.maxInt(u64);
}

/// mdf hashing algorithm https://en.wikipedia.org/wiki/MD5
fn md5(str: []const u8) [16]u8 {
    const s: [64]u32 = .{
        7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
        5, 9,  14, 20, 5, 9,  14, 20, 5, 9,  14, 20, 5, 9,  14, 20,
        4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
        6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21,
    };
    const k: [64]u32 = .{
        0xd76aa478, 0xe8c7b756, 0x242070db, 0xc1bdceee,
        0xf57c0faf, 0x4787c62a, 0xa8304613, 0xfd469501,
        0x698098d8, 0x8b44f7af, 0xffff5bb1, 0x895cd7be,
        0x6b901122, 0xfd987193, 0xa679438e, 0x49b40821,
        0xf61e2562, 0xc040b340, 0x265e5a51, 0xe9b6c7aa,
        0xd62f105d, 0x02441453, 0xd8a1e681, 0xe7d3fbc8,
        0x21e1cde6, 0xc33707d6, 0xf4d50d87, 0x455a14ed,
        0xa9e3e905, 0xfcefa3f8, 0x676f02d9, 0x8d2a4c8a,
        0xfffa3942, 0x8771f681, 0x6d9d6122, 0xfde5380c,
        0xa4beea44, 0x4bdecfa9, 0xf6bb4b60, 0xbebfbc70,
        0x289b7ec6, 0xeaa127fa, 0xd4ef3085, 0x04881d05,
        0xd9d4d039, 0xe6db99e5, 0x1fa27cf8, 0xc4ac5665,
        0xf4292244, 0x432aff97, 0xab9423a7, 0xfc93a039,
        0x655b59c3, 0x8f0ccc92, 0xffeff47d, 0x85845dd1,
        0x6fa87e4f, 0xfe2ce6e0, 0xa3014314, 0x4e0811a1,
        0xf7537e82, 0xbd3af235, 0x2ad7d2bb, 0xeb86d391,
    };
    var state: [4]u32 = .{ 0x67452301, 0xefcdab89, 0x98badcfe, 0x10325476 };
    var chunk: [64]u8 = undefined;

    var offset: usize = 0;
    var loop = true;
    var write0x80 = true;
    while (loop) : (offset += 64) {
        var l: usize = if (offset < str.len) blk: {
            const l = @min(64, str.len - offset);
            @memcpy(&chunk, str[offset..][0..l]);
            break :blk l;
        } else 0;

        if (l < 64) {
            if (write0x80) {
                chunk[l] = 0x80;
                l += 1;
                write0x80 = false;
            }
            @memset(chunk[l..], 0);
            if (64 - l >= 8) {
                const x = @as(u64, @truncate(@as(u128, @intCast(str.len)) * 8));
                std.mem.writeIntLittle(u64, chunk[56..][0..8], x);
                loop = false;
            }
        }

        var A: u32 = state[0];
        var B: u32 = state[1];
        var C: u32 = state[2];
        var D: u32 = state[3];

        for (0..64) |i| {
            var F: u32 = 0;
            var g: u32 = 0;

            if (0 <= i and i <= 15) {
                F = (B & C) | ((~B) & D);
                g = @intCast(i);
            } else if (16 <= i and i <= 31) {
                F = (D & B) | ((~D) & C);
                g = @intCast((5 * i + 1) % 16);
            } else if (32 <= i and i <= 47) {
                F = B ^ C ^ D;
                g = @intCast((3 * i + 5) % 16);
            } else if (48 <= i and i <= 63) {
                F = C ^ (B | (~D));
                g = @intCast((7 * i) % 16);
            }

            F = F + A + k[i] + std.mem.bytesToValue(u32, chunk[g * 4 ..][0..4]);
            A = D;
            D = C;
            C = B;
            B = B + std.math.rotl(u32, F, s[i]);
        }

        state[0] += A;
        state[1] += B;
        state[2] += C;
        state[3] += D;
    }

    var digest: [16]u8 = undefined;
    std.mem.writeIntLittle(u32, digest[12..16], state[3]);
    std.mem.writeIntLittle(u32, digest[8..12], state[2]);
    std.mem.writeIntLittle(u32, digest[4..8], state[1]);
    std.mem.writeIntLittle(u32, digest[0..4], state[0]);
    return digest;
}
