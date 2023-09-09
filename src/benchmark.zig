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

    var sum: usize = 0;
    var time = std.time.Timer.start() catch unreachable;

    for (0..iterations) |i| {
        time.reset();
        r = try func(allocator);
        sum += time.read();
        if (i < iterations - 1) {
            deinitResult(r);
            counting_allocator.current = 0;
        }
    }

    writeResult(writer, r);
    writer.print("\nran {} times\navg time: {}ns\nmemory: {} bytes\n\n", .{
        iterations,
        sum / iterations,
        counting_allocator.max,
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
    current: usize,
    max: usize,

    pub fn init(inner: std.mem.Allocator) @This() {
        return .{
            .inner = inner,
            .max = 0,
            .current = 0,
        };
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
        return self.inner.vtable.alloc(self.inner.ptr, len, ptr_align, ret_addr);
    }

    fn resize(_: *anyopaque, _: []u8, _: u8, _: usize, _: usize) bool {
        return false;
    }

    fn free(ctx: *anyopaque, buf: []u8, buf_align: u8, ret_addr: usize) void {
        var self: *@This() = @alignCast(@ptrCast(ctx));
        self.current -= buf.len;
        self.inner.vtable.free(self.inner.ptr, buf, buf_align, ret_addr);
    }

    pub const vtable = std.mem.Allocator.VTable{
        .alloc = alloc,
        .resize = resize,
        .free = free,
    };
};
