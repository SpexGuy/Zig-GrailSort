const std = @import("std");
const grail = @import("grailsort.zig");
const testing = std.testing;
const print = std.debug.print;
const tracy = @import("tracy.zig");

var gpa_storage = std.heap.GeneralPurposeAllocator(.{}){};
const gpa = &gpa_storage.allocator;

const verify_sorted = true;

pub fn main() void {
    tracy.InitThread();
    tracy.SetThreadName("main");

    //doIntTests(u8);
    //doIntTests(i32);
    doIntTests(u32);
    //doIntTests(usize);
}

fn doIntTests(comptime T: type) void {
    //doAllKeyCases("std.sort" , "unique", T, std.sort.sort, comptime std.sort.asc(T) , comptime doIntCast(T));
    doAllKeyCases("grailsort", "unique", T, grail.sort   , comptime std.sort.asc(T) , comptime doIntCast(T));
    //doAllKeyCases("std.sort" , "x2"    , T, std.sort.sort, comptime removeBits(T, 1), comptime doIntCast(T));
    doAllKeyCases("grailsort", "x2"    , T, grail.sort   , comptime removeBits(T, 1), comptime doIntCast(T));
    //doAllKeyCases("std.sort" , "x8"    , T, std.sort.sort, comptime removeBits(T, 3), comptime doIntCast(T));
    doAllKeyCases("grailsort", "x8"    , T, grail.sort   , comptime removeBits(T, 3), comptime doIntCast(T));
    //doAllKeyCases("std.sort" , "x32"   , T, std.sort.sort, comptime removeBits(T, 5), comptime doIntCast(T));
    doAllKeyCases("grailsort", "x32"   , T, grail.sort   , comptime removeBits(T, 5), comptime doIntCast(T));
}

fn doAllKeyCases(sort: []const u8, benchmark: []const u8, comptime T: type, comptime sortFn: anytype, comptime lessThan: fn(void, T, T) bool, comptime fromInt: fn(usize) T) void {
    const ctx = tracy.Zone(@src());
    defer ctx.End();

    ctx.Name(benchmark);

    const max_len = 10_000_000;

    const array = gpa.alloc(T, max_len) catch unreachable;
    const golden = gpa.alloc(T, max_len) catch unreachable;
    defer gpa.free(array);
    defer gpa.free(golden);

    var extern_array = gpa.alloc(T, grail.findOptimalBufferLength(max_len));

    var seed_rnd = std.rand.DefaultPrng.init(42);

    for (golden) |*v, i| v.* = fromInt(i);
    checkSorted(T, golden, lessThan);

    print(" --------------- {: >9} {} {} ---------------- \n", .{sort, @typeName(T), benchmark});
    print("    Items : ns / item |    ms avg |    ms max |    ms min\n", .{});
 
    var array_len: usize = 10000;
    while (array_len <= max_len) : (array_len *= 10) {
        const len_zone = tracy.ZoneN(@src(), "len");
        defer len_zone.End();
        len_zone.Value(array_len);

        var runs = 100_000_000 / array_len;
        if (runs > 1000) runs = 1000;
        var run_rnd = std.rand.DefaultPrng.init(seed_rnd.random.int(u64));

        tracy.PlotU("Array Size", array_len);

        var min_time: u64 = ~@as(u64, 0);
        var max_time: u64 = 0;
        var total_time: u64 = 0;
        var total_cycles: u64 = 0;

        var run_id: usize = 0;
        while (run_id < runs) : (run_id += 1) {
            const seed = run_rnd.random.int(u64);

            const part = array[0..array_len];
            setRandom(T, part, golden[0..array_len], seed);

            var time = std.time.Timer.start() catch unreachable;
            sortFn(T, part, {}, lessThan);
            const elapsed = time.read();

            checkSorted(T, part, lessThan);

            if (elapsed < min_time) min_time = elapsed;
            if (elapsed > max_time) max_time = elapsed;
            total_time += elapsed;
        }

        const avg_time = total_time / runs;
        print("{: >9} : {d: >9.3} | {d: >9.3} | {d: >9.3} | {d: >9.3}\n",
            .{ array_len, @intToFloat(f64, avg_time) / @intToFloat(f64, array_len),
                millis(avg_time), millis(max_time), millis(min_time) });
    }
}

fn millis(nanos: u64) f64 {
    return @intToFloat(f64, nanos) / 1_000_000.0;
}

fn checkSorted(comptime T: type, array: []T, comptime lessThan: fn(void, T, T) bool) void {
    if (verify_sorted) {
        for (array[1..]) |v, i| {
            testing.expect(!lessThan({}, v, array[i]));
        }
    } else {
        // clobber the memory
        asm volatile("" : : [g]"r"(array.ptr) : "memory");
    }
}

fn setRandom(comptime T: type, array: []T, golden: []const T, seed: u64) void {
    std.mem.copy(T, array, golden);
    var rnd = std.rand.DefaultPrng.init(seed);
    rnd.random.shuffle(T, array);
}

fn doIntCast(comptime T: type) fn(usize) T {
    return struct {
        fn doCast(v: usize) T {
            if (T == u8) {
                return @truncate(T, v);
            } else {
                return @intCast(T, v);
            }
        }
    }.doCast;
}

fn removeBits(comptime T: type, comptime bits: comptime_int) fn(void, T, T) bool {
    return struct {
        fn shiftLess(_: void, a: T, b: T) bool {
            return (a >> bits) < (b >> bits);
        }
    }.shiftLess;
}

/// This function converts a time in nanoseconds to
/// the equivalent value that would have been returned
/// from rdtsc to get that duration.
fn nanosToCycles(nanos: u64) u64 {
    // The RDTSC instruction does not actually count
    // processor cycles or retired instructions.  It
    // counts real time relative to an arbitrary clock.
    // The speed of this clock is hardware dependent.
    // You can find the values here:
    // https://github.com/torvalds/linux/blob/master/tools/power/x86/turbostat/turbostat.c#L5172-L5184
    // (search for 24000000 if they have moved)
    // For the purposes of this function, we will
    // assume that we're running on a skylake processor or similar,
    // which updates at 24 MHz
    return nanos * 24 / 1000;
}
