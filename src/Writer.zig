// ********************************************************************************
//  https://github.com/PatrickTorgerson/advent2015
//  Copyright (c) 2023 Patrick Torgerson
//  MIT license, see LICENSE for more information
// ********************************************************************************

const std = @import("std");

const StdWriter = @TypeOf(std.io.getStdOut().writer());
const StdBufferedWriterBuffer = std.io.BufferedWriter(4096, StdWriter);
const StdBufferedWriter = StdBufferedWriterBuffer.Writer;

buffer: StdBufferedWriterBuffer,
stdout: StdBufferedWriter,

pub fn init(self: *@This()) void {
    self.buffer = std.io.bufferedWriter(std.io.getStdOut().writer());
    self.stdout = self.buffer.writer();
}

pub fn flush(self: *@This()) void {
    self.buffer.flush() catch {};
}

pub fn print(self: *@This(), comptime fmt: []const u8, args: anytype) void {
    self.stdout.print(fmt, args) catch {};
}
