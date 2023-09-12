// ********************************************************************************
//  https://github.com/PatrickTorgerson/advent2015
//  Copyright (c) 2023 Patrick Torgerson
//  MIT license, see LICENSE for more information
// ********************************************************************************

const std = @import("std");
const Writer = @import("Writer.zig");

const iterations = std.meta.globalOption("benchmark_iterations", usize) orelse 1;

pub fn benchmark(inner_allocator: std.mem.Allocator, writer: *Writer, comptime func: anytype) !void {
    var counting_allocator = CountingAllocator.init(inner_allocator);
    var allocator = counting_allocator.allocator();

    const R = ReturnType(func);
    var r: R = undefined;

    var min: u64 = std.math.maxInt(u64);
    var max: u64 = 0;
    var sum: usize = 0;
    var time = std.time.Timer.start() catch unreachable;

    for (0..iterations) |i| {
        time.reset();
        r = try func(allocator);
        const t = time.read();
        sum += t;
        min = @min(min, t);
        max = @max(max, t);
        if (i < iterations - 1) {
            deinitResult(r);
            counting_allocator.reset();
        }
    }

    writeResult(writer, r);
    writer.print(
        \\
        \\
        \\  - ran {} times
        \\  - total time: {d:.4}ms
        \\  - avg time: {d:.4}ms
        \\  - min time: {d:.4}ms
        \\  - max time: {d:.4}ms
        \\  - heap mem: {} bytes
        \\  - heap allocs: {}
        \\  - heap frees: {}
        \\
        \\
    , .{
        iterations,
        @as(f64, @floatFromInt(sum)) / @as(f64, @floatFromInt(std.time.ns_per_ms)),
        @as(f64, @floatFromInt(sum)) / @as(f64, @floatFromInt(iterations)) / @as(f64, @floatFromInt(std.time.ns_per_ms)),
        @as(f64, @floatFromInt(min)) / @as(f64, @floatFromInt(std.time.ns_per_ms)),
        @as(f64, @floatFromInt(max)) / @as(f64, @floatFromInt(std.time.ns_per_ms)),
        counting_allocator.max,
        counting_allocator.allocs,
        counting_allocator.frees,
    });
    deinitResult(r);
}

fn deinitResult(r: anytype) void {
    const R = @TypeOf(r);
    if (comptime hasDeinit(R)) {
        r.deinit();
    } else if (comptime std.meta.trait.is(.Optional)(R) and hasDeinit(std.meta.Child(R))) {
        if (r) |v| {
            v.deinit();
        }
    }
}

fn writeResult(writer: *Writer, r: anytype) void {
    switch (@typeInfo(@TypeOf(r))) {
        .Pointer => |p| {
            if (p.size == .Slice and p.child == u8)
                writer.print("{s}", .{r})
            else if (p.size == .Slice) {
                for (r, 0..) |e, i| {
                    if (i != 0) writer.print(", ", .{});
                    writeResult(writer, e);
                }
            } else if (p.size == .One) {
                writeResult(writer, r.*);
            } else writer.print("addr {*}", .{r});
        },
        .Array => {
            for (r, 0..) |e, i| {
                if (i != 0) writer.print(", ", .{});
                writeResult(writer, e);
            }
        },
        .Optional => {
            if (r) |val| writeResult(writer, val) else writer.print("null", .{});
        },
        .Struct => {
            if (comptime isArrayList(@TypeOf(r))) {
                for (r.items, 0..) |e, i| {
                    if (i != 0) writer.print(", ", .{});
                    writeResult(writer, e);
                }
            } else if (comptime std.meta.trait.isTuple(@TypeOf(r))) {
                inline for (0..std.meta.fields(@TypeOf(r)).len) |i| {
                    if (i != 0) writer.print(", ", .{});
                    writeResult(writer, r[i]);
                }
            } else {
                inline for (std.meta.fields(@TypeOf(r)), 0..) |field, i| {
                    if (i != 0) writer.print(", ", .{});
                    writer.print(".{s}=", .{field.name});
                    writeResult(writer, @field(r, field.name));
                }
            }
        },
        else => writer.print("{}", .{r}),
    }
}

fn ReturnType(comptime func: anytype) type {
    const R = @typeInfo(@TypeOf(func)).Fn.return_type.?;
    return @typeInfo(R).ErrorUnion.payload;
}

fn isArrayList(comptime T: type) bool {
    return std.meta.trait.is(.Struct)(T) and
        std.meta.trait.hasFields(T, .{ "items", "capacity", "allocator" }) and
        std.meta.trait.hasFunctions(T, .{ "init", "deinit", "append" });
}

fn hasDeinit(comptime T: type) bool {
    return std.meta.trait.is(.Struct)(T) and
        std.meta.trait.hasFunctions(T, .{"deinit"});
}

const CountingAllocator = struct {
    inner: std.mem.Allocator,
    current: usize = 0,
    max: usize = 0,
    allocs: usize = 0,
    frees: usize = 0,

    pub fn init(inner: std.mem.Allocator) @This() {
        return .{
            .inner = inner,
        };
    }

    pub fn reset(self: *@This()) void {
        self.current = 0;
        self.max = 0;
        self.allocs = 0;
        self.frees = 0;
    }

    pub fn allocator(self: *@This()) std.mem.Allocator {
        return .{
            .ptr = @ptrCast(self),
            .vtable = &vtable,
        };
    }

    fn alloc(ctx: *anyopaque, len: usize, ptr_align: u8, ret_addr: usize) ?[*]u8 {
        var self: *@This() = @alignCast(@ptrCast(ctx));
        self.current += len;
        self.max = @max(self.max, self.current);
        self.allocs += 1;
        return self.inner.vtable.alloc(self.inner.ptr, len, ptr_align, ret_addr);
    }

    fn resize(_: *anyopaque, _: []u8, _: u8, _: usize, _: usize) bool {
        return false;
    }

    fn free(ctx: *anyopaque, buf: []u8, buf_align: u8, ret_addr: usize) void {
        var self: *@This() = @alignCast(@ptrCast(ctx));
        self.current -= buf.len;
        self.frees += 1;
        self.inner.vtable.free(self.inner.ptr, buf, buf_align, ret_addr);
    }

    pub const vtable = std.mem.Allocator.VTable{
        .alloc = alloc,
        .resize = resize,
        .free = free,
    };
};
