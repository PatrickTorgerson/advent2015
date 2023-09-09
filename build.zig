// ********************************************************************************
//  https://github.com/PatrickTorgerson
//  Copyright (c) 2023 Patrick Torgerson
//  MIT license, see LICENSE for more information
// ********************************************************************************

const std = @import("std");

var year_opt: ?i32 = null;
var repo_opt: []const u8 = "use -Drepo=[string] to populate this line";
var copyright_opt: []const u8 = "use -Dcopyright=[string] to populate this line";

pub fn build(b: *std.Build) void {
    year_opt = b.option(i32, "year", "generate: advent of Code event year");
    repo_opt = b.option([]const u8, "repo", "generate: repo link to include in banner comments") orelse repo_opt;
    copyright_opt = b.option([]const u8, "copyright", "generate: copyright to include in banner comments") orelse copyright_opt;

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // -- directory init, see fn generate()
    const init_step = b.step("generate", "Generate initial solution files, use -Dyear=[int]");
    init_step.makeFn = generate;

    // -- executable
    const exe = b.addExecutable(.{
        .name = "advent2015",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

/// Create initial solution files
fn generate(_: *std.Build.Step, _: *std.Progress.Node) !void {
    if (year_opt) |year| {
        var cwd = std.fs.cwd();
        try cwd.makePath("src/solutions");
        try cwd.makePath("src/input");

        generateFile(cwd, ".gitignore", gitignore_fmt, .{}) catch {};
        generateFile(cwd, "LICENSE", license_fmt, .{
            .copyright = copyright_opt,
        }) catch {};
        generateFile(cwd, "README.md", readme_fmt, .{
            .year = year,
        }) catch {};
        generateFile(cwd, "src/Writer.zig", writer_fmt, .{
            .repo = repo_opt,
            .copyright = copyright_opt,
        }) catch {};
        generateFile(cwd, "src/benchmark.zig", benchmark_fmt, .{
            .repo = repo_opt,
            .copyright = copyright_opt,
        }) catch {};
        generateFile(cwd, "src/common.zig", common_fmt, .{
            .repo = repo_opt,
            .copyright = copyright_opt,
        }) catch {};
        generateFile(cwd, "src/main.zig", main_fmt, .{
            .repo = repo_opt,
            .copyright = copyright_opt,
            .year = year,
        }) catch {};

        var buffer: [80]u8 = undefined;
        for (1..26) |day| {
            const solutionpath = getSolutionFileName(&buffer, day) catch "";
            const inputpath = getInputFileName(buffer[solutionpath.len..], day) catch "";
            generateFile(cwd, inputpath, "", .{}) catch {};
            generateFile(cwd, solutionpath, solution_fmt, .{
                .repo = repo_opt,
                .copyright = copyright_opt,
                .year = year,
                .day = day,
            }) catch {};
        }
    } else {
        std.debug.print("Must specify year with option '-Dyear=[int]'", .{});
    }
}

fn generateFile(cwd: std.fs.Dir, filename: []const u8, comptime fmt: []const u8, args: anytype) !void {
    var file = cwd.createFile(filename, .{ .exclusive = true }) catch |err| {
        std.debug.print("({s}): could not generate file '{s}'\n", .{ @errorName(err), filename });
        return err;
    };
    defer file.close();
    file.writer().print(fmt, args) catch |err| {
        std.debug.print("({s}): could not generate file '{s}'\n", .{ @errorName(err), filename });
        return err;
    };
}

fn getSolutionFileName(buffer: []u8, day: usize) ![]const u8 {
    var stream = std.io.fixedBufferStream(buffer);
    var writer = stream.writer();
    writer.print("src/solutions/day{}.zig", .{day}) catch |err| {
        std.debug.print("({s}): could not generate file 'src/solutions/day{}.zig'\n", .{ @errorName(err), day });
        return err;
    };
    return buffer[0..stream.pos];
}

fn getInputFileName(buffer: []u8, day: usize) ![]const u8 {
    var stream = std.io.fixedBufferStream(buffer);
    var writer = stream.writer();
    writer.print("src/input/day{}.txt", .{day}) catch |err| {
        std.debug.print("({s}): could not generate file 'src/input/day{}.txt'\n", .{ @errorName(err), day });
        return err;
    };
    return buffer[0..stream.pos];
}

const gitignore_fmt =
    \\zig-cache
    \\zig-out
    \\.vscode
    \\
;

const license_fmt =
    \\MIT License
    \\
    \\{[copyright]s}
    \\
    \\Permission is hereby granted, free of charge, to any person obtaining a copy
    \\of this software and associated documentation files (the "Software"), to deal
    \\in the Software without restriction, including without limitation the rights
    \\to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    \\copies of the Software, and to permit persons to whom the Software is
    \\furnished to do so, subject to the following conditions:
    \\
    \\The above copyright notice and this permission notice shall be included in all
    \\copies or substantial portions of the Software.
    \\
    \\THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    \\IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    \\FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    \\AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    \\LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    \\OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    \\SOFTWARE.
    \\
;

const readme_fmt =
    \\# advent{[year]}
    \\
    \\Advent of code {[year]} solutions
    \\ * build with `zig build`
    \\ * run with `zig build run -- ARGS`
    \\
    \\to run a specific solution run `advent{[year]} DAY`, where `DAY` is an
    \\integer between 1 and 25 inclusive.
    \\
    \\## project generation
    \\
    \\re-generate missing files, or generate files for another Advent of Code event with
    \\`zig build generate -Dyear=YEAR -Drepo=LINK -Dcopyright=CPYRT`, all you need is the `build.zig` file.
    \\ * where `YEAR` is the event year
    \\ * where `LINK` is a repo link to include in banner comments
    \\ * where `CPYRT` is a copyright notice to include in banner comments
    \\
    \\note, input files are not automatically populated
    \\
;

const writer_fmt =
    \\// ********************************************************************************
    \\//  {[repo]s}
    \\//  {[copyright]s}
    \\//  MIT license, see LICENSE for more information
    \\// ********************************************************************************
    \\
    \\const std = @import("std");
    \\
    \\const StdWriter = @TypeOf(std.io.getStdOut().writer());
    \\const StdBufferedWriterBuffer = std.io.BufferedWriter(4096, StdWriter);
    \\const StdBufferedWriter = StdBufferedWriterBuffer.Writer;
    \\
    \\buffer: StdBufferedWriterBuffer,
    \\stdout: StdBufferedWriter,
    \\
    \\pub fn init(self: *@This()) void {{
    \\    self.buffer = std.io.bufferedWriter(std.io.getStdOut().writer());
    \\    self.stdout = self.buffer.writer();
    \\}}
    \\
    \\pub fn flush(self: *@This()) void {{
    \\    self.buffer.flush() catch {{}};
    \\}}
    \\
    \\pub fn print(self: *@This(), comptime fmt: []const u8, args: anytype) void {{
    \\    self.stdout.print(fmt, args) catch {{}};
    \\}}
    \\
;

const benchmark_fmt =
    \\// ********************************************************************************
    \\//  {[repo]s}
    \\//  {[copyright]s}
    \\//  MIT license, see LICENSE for more information
    \\// ********************************************************************************
    \\
    \\const std = @import("std");
    \\const Writer = @import("Writer.zig");
    \\
    \\const iterations = std.meta.globalOption("benchmark_iterations", usize) orelse 1;
    \\
    \\pub fn benchmark(inner_allocator: std.mem.Allocator, writer: *Writer, comptime func: anytype) !void {{
    \\    var counting_allocator = CountingAllocator.init(inner_allocator);
    \\    var allocator = counting_allocator.allocator();
    \\
    \\    const R = ReturnType(func);
    \\    var r: R = undefined;
    \\
    \\    var sum: usize = 0;
    \\    var time = std.time.Timer.start() catch unreachable;
    \\
    \\    for (0..iterations) |i| {{
    \\        time.reset();
    \\        r = try func(allocator);
    \\        sum += time.read();
    \\        if (i < iterations - 1) {{
    \\            deinitResult(r);
    \\            counting_allocator.current = 0;
    \\        }}
    \\    }}
    \\
    \\    writeResult(writer, r);
    \\    writer.print("\nran {{}} times\navg time: {{}}ns\nmemory: {{}} bytes\n\n", .{{
    \\        iterations,
    \\        sum / iterations,
    \\        counting_allocator.max,
    \\    }});
    \\    deinitResult(r);
    \\}}
    \\
    \\fn deinitResult(r: anytype) void {{
    \\    const R = @TypeOf(r);
    \\    if (comptime hasDeinit(R)) {{
    \\        r.deinit();
    \\    }} else if (comptime std.meta.trait.is(.Optional)(R) and hasDeinit(std.meta.Child(R))) {{
    \\        if (r) |v| {{
    \\            v.deinit();
    \\        }}
    \\    }}
    \\}}
    \\
    \\fn writeResult(writer: *Writer, r: anytype) void {{
    \\    switch (@typeInfo(@TypeOf(r))) {{
    \\        .Pointer => |p| {{
    \\            if (p.size == .Slice and p.child == u8)
    \\                writer.print("{{s}}", .{{r}})
    \\            else if (p.size == .Slice) {{
    \\                for (r, 0..) |e, i| {{
    \\                    if (i != 0) writer.print(", ", .{{}});
    \\                    writeResult(writer, e);
    \\                }}
    \\            }} else if (p.size == .One) {{
    \\                writeResult(writer, r.*);
    \\            }} else writer.print("addr {{*}}", .{{r}});
    \\        }},
    \\        .Array => {{
    \\            for (r, 0..) |e, i| {{
    \\                if (i != 0) writer.print(", ", .{{}});
    \\                writeResult(writer, e);
    \\            }}
    \\        }},
    \\        .Optional => {{
    \\            if (r) |val| writeResult(writer, val) else writer.print("null", .{{}});
    \\        }},
    \\        .Struct => {{
    \\            if (comptime isArrayList(@TypeOf(r))) {{
    \\                for (r.items, 0..) |e, i| {{
    \\                    if (i != 0) writer.print(", ", .{{}});
    \\                    writeResult(writer, e);
    \\                }}
    \\            }} else if (comptime std.meta.trait.isTuple(@TypeOf(r))) {{
    \\                inline for (0..std.meta.fields(@TypeOf(r)).len) |i| {{
    \\                    if (i != 0) writer.print(", ", .{{}});
    \\                    writeResult(writer, r[i]);
    \\                }}
    \\            }} else {{
    \\                inline for (std.meta.fields(@TypeOf(r)), 0..) |field, i| {{
    \\                    if (i != 0) writer.print(", ", .{{}});
    \\                    writer.print(".{{s}}=", .{{field.name}});
    \\                    writeResult(writer, @field(r, field.name));
    \\                }}
    \\            }}
    \\        }},
    \\        else => writer.print("{{}}", .{{r}}),
    \\    }}
    \\}}
    \\
    \\fn ReturnType(comptime func: anytype) type {{
    \\    const R = @typeInfo(@TypeOf(func)).Fn.return_type.?;
    \\    return @typeInfo(R).ErrorUnion.payload;
    \\}}
    \\
    \\fn isArrayList(comptime T: type) bool {{
    \\    return std.meta.trait.is(.Struct)(T) and
    \\        std.meta.trait.hasFields(T, .{{ "items", "capacity", "allocator" }}) and
    \\        std.meta.trait.hasFunctions(T, .{{ "init", "deinit", "append" }});
    \\}}
    \\
    \\fn hasDeinit(comptime T: type) bool {{
    \\    return std.meta.trait.is(.Struct)(T) and
    \\        std.meta.trait.hasFunctions(T, .{{"deinit"}});
    \\}}
    \\
    \\const CountingAllocator = struct {{
    \\    inner: std.mem.Allocator,
    \\    current: usize,
    \\    max: usize,
    \\
    \\    pub fn init(inner: std.mem.Allocator) @This() {{
    \\        return .{{
    \\            .inner = inner,
    \\            .max = 0,
    \\            .current = 0,
    \\        }};
    \\    }}
    \\
    \\    pub fn allocator(self: *@This()) std.mem.Allocator {{
    \\        return .{{
    \\            .ptr = @ptrCast(self),
    \\            .vtable = &vtable,
    \\        }};
    \\    }}
    \\
    \\    fn alloc(ctx: *anyopaque, len: usize, ptr_align: u8, ret_addr: usize) ?[*]u8 {{
    \\        var self: *@This() = @alignCast(@ptrCast(ctx));
    \\        self.current += len;
    \\        self.max = @max(self.max, self.current);
    \\        return self.inner.vtable.alloc(self.inner.ptr, len, ptr_align, ret_addr);
    \\    }}
    \\
    \\    fn resize(_: *anyopaque, _: []u8, _: u8, _: usize, _: usize) bool {{
    \\        return false;
    \\    }}
    \\
    \\    fn free(ctx: *anyopaque, buf: []u8, buf_align: u8, ret_addr: usize) void {{
    \\        var self: *@This() = @alignCast(@ptrCast(ctx));
    \\        self.current -= buf.len;
    \\        self.inner.vtable.free(self.inner.ptr, buf, buf_align, ret_addr);
    \\    }}
    \\
    \\    pub const vtable = std.mem.Allocator.VTable{{
    \\        .alloc = alloc,
    \\        .resize = resize,
    \\        .free = free,
    \\    }};
    \\}};
;

const common_fmt =
    \\// ********************************************************************************
    \\//  {[repo]s}
    \\//  {[copyright]s}
    \\//  MIT license, see LICENSE for more information
    \\// ********************************************************************************
    \\
    \\const std = @import("std");
    \\
    \\// here you may write code that can be used in any solution file
    \\
;

const main_fmt =
    \\// ********************************************************************************
    \\//  {[repo]s}
    \\//  {[copyright]s}
    \\//  MIT license, see LICENSE for more information
    \\// ********************************************************************************
    \\
    \\const std = @import("std");
    \\const Writer = @import("Writer.zig");
    \\
    \\const help =
    \\    \\
    \\    \\ Run a solution to an Advent of Code {[year]} puzzle
    \\    \\
    \\    \\ USEAGE:
    \\    \\   advent{[year]} `day`
    \\    \\   where `day` is an integer between 1 and {{}} inclusive
    \\    \\
    \\    \\
    \\;
    \\
    \\pub const benchmark_iterations = 10;
    \\
    \\const SlnFn = *const fn (std.mem.Allocator, *Writer) anyerror!void;
    \\const solutions = [_]SlnFn{{
    \\    @import("solutions/day1.zig").solve,
    \\    @import("solutions/day2.zig").solve,
    \\    @import("solutions/day3.zig").solve,
    \\    @import("solutions/day4.zig").solve,
    \\    @import("solutions/day5.zig").solve,
    \\    @import("solutions/day6.zig").solve,
    \\    @import("solutions/day7.zig").solve,
    \\    @import("solutions/day8.zig").solve,
    \\    @import("solutions/day9.zig").solve,
    \\    @import("solutions/day10.zig").solve,
    \\    @import("solutions/day11.zig").solve,
    \\    @import("solutions/day12.zig").solve,
    \\    @import("solutions/day13.zig").solve,
    \\    @import("solutions/day14.zig").solve,
    \\    @import("solutions/day15.zig").solve,
    \\    @import("solutions/day16.zig").solve,
    \\    @import("solutions/day17.zig").solve,
    \\    @import("solutions/day18.zig").solve,
    \\    @import("solutions/day19.zig").solve,
    \\    @import("solutions/day20.zig").solve,
    \\    @import("solutions/day21.zig").solve,
    \\    @import("solutions/day22.zig").solve,
    \\    @import("solutions/day23.zig").solve,
    \\    @import("solutions/day24.zig").solve,
    \\    @import("solutions/day25.zig").solve,
    \\}};
    \\
    \\pub fn main() !void {{
    \\    var gpa = std.heap.GeneralPurposeAllocator(.{{}}){{}};
    \\    defer _ = gpa.deinit();
    \\    var allocator = gpa.allocator();
    \\
    \\    var writer: Writer = undefined;
    \\    writer.init();
    \\    defer writer.flush();
    \\
    \\    const day = getDay(allocator) orelse {{
    \\        writer.print(help, .{{solutions.len}});
    \\        return;
    \\    }};
    \\
    \\    writer.print("\n==== Running day {{}} ====\n\n", .{{day + 1}});
    \\    try solutions[day](allocator, &writer);
    \\}}
    \\
    \\fn getDay(allocator: std.mem.Allocator) ?usize {{
    \\    var args = std.process.argsWithAllocator(allocator) catch return null;
    \\    defer args.deinit();
    \\    _ = args.next(); // ignore executable path
    \\    if (args.next()) |day_str| {{
    \\        const day = std.fmt.parseInt(i32, day_str, 10) catch return null;
    \\        if (day < 1 or day > solutions.len)
    \\            return null;
    \\        return @intCast(day - 1);
    \\    }} else return null;
    \\}}
    \\
;

const solution_fmt =
    \\// ********************************************************************************
    \\//  {[repo]s}
    \\//  {[copyright]s}
    \\//  MIT license, see LICENSE for more information
    \\// ********************************************************************************
    \\
    \\//
    \\// https://adventofcode.com/{[year]}/day/{[day]}
    \\// https://adventofcode.com/{[year]}/day/{[day]}/input
    \\//
    \\
    \\const std = @import("std");
    \\const common = @import("../common.zig");
    \\const benchmark = @import("../benchmark.zig").benchmark;
    \\const Writer = @import("../Writer.zig");
    \\
    \\const input = @embedFile("../input/day{[day]}.txt");
    \\
    \\pub fn solve(allocator: std.mem.Allocator, writer: *Writer) anyerror!void {{
    \\    writer.print("Part 1: ", .{{}});
    \\    try benchmark(allocator, writer, part1);
    \\    writer.flush();
    \\    writer.print("Part 2: ", .{{}});
    \\    try benchmark(allocator, writer, part2);
    \\}}
    \\
    \\/// PART 1 DESCRIPTION
    \\fn part1(allocator: std.mem.Allocator) ![]const u8 {{
    \\    _ = allocator;
    \\    return "not implemented";
    \\}}
    \\
    \\/// PART 2 DESCRIPTION
    \\fn part2(allocator: std.mem.Allocator) ![]const u8 {{
    \\    _ = allocator;
    \\    return "not implemented";
    \\}}
    \\
;
