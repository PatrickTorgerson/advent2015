// ********************************************************************************
//  https://github.com/PatrickTorgerson/advent2015
//  Copyright (c) 2023 Patrick Torgerson
//  MIT license, see LICENSE for more information
// ********************************************************************************

const std = @import("std");

// here you may write code that can be used in any solution file

pub const Result = extern struct { part1: usize = 0, part2: usize = 0 };

/// reads average ns for day from previous run
pub fn prevns(day: usize) !Result {
    const path = std.meta.globalOption("benchmark_file", []const u8) orelse "bench.dat";
    var cwd = std.fs.cwd();
    var file = try cwd.createFile(path, .{
        .read = true,
        .truncate = false,
    });
    defer file.close();

    const stride = @sizeOf(Result);

    try file.seekFromEnd(0);
    const file_size = try file.getPos();

    if (file_size < stride * 25) {
        try file.seekTo(0);
        const zero = Result{};
        for (0..25) |_|
            try file.writer().writeStruct(zero);
        try file.setEndPos(try file.getPos());
        return zero;
    }

    try file.seekTo(stride * (day + 1));
    return try file.reader().readStruct(Result);
}

/// writes average ns for day
pub fn avgns(times: Result, day: usize) !void {
    const path = std.meta.globalOption("benchmark_file", []const u8) orelse "bench.dat";
    var cwd = std.fs.cwd();
    var file = try cwd.createFile(path, .{
        .read = true,
        .truncate = false,
    });
    defer file.close();

    const stride = @sizeOf(Result);

    try file.seekFromEnd(0);
    const file_size = try file.getPos();

    if (file_size < stride * 25) {
        try file.seekTo(0);
        const zero = Result{};
        for (0..25) |_|
            try file.writer().writeStruct(zero);
        try file.setEndPos(try file.getPos());
    }

    try file.seekTo(stride * (day + 1));
    try file.writer().writeStruct(times);
}
