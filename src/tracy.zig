const std = @import("std");
const options = @import("build_options");

const Src = std.builtin.SourceLocation;

pub const enabled = options.tracy_enabled;

usingnamespace if (enabled) tracy_full else tracy_stub;

const tracy_stub = struct {
    pub const c = @cImport({
        @cInclude("TracyC.h");
    });

    pub const ZoneCtx = struct {
        pub inline fn Text(self: ZoneCtx, text: []const u8) void {}
        pub inline fn Name(self: ZoneCtx, name: []const u8) void {}
        pub inline fn Value(self: ZoneCtx, value: u64) void {}
        pub inline fn End(self: ZoneCtx) void {}
    };

    pub fn InitThread() void { }

    pub inline fn Zone(comptime src: Src) ZoneCtx { return .{}; }
    pub inline fn ZoneN(comptime src: Src, name: [*:0]const u8) ZoneCtx { return .{}; }
    pub inline fn ZoneC(comptime src: Src, color: u32) ZoneCtx { return .{}; }
    pub inline fn ZoneNC(comptime src: Src, name: [*:0]const u8, color: u32) ZoneCtx { return .{}; }
    pub inline fn ZoneS(comptime src: Src, depth: i32) ZoneCtx { return .{}; }
    pub inline fn ZoneNS(comptime src: Src, name: [*:0]const u8, depth: i32) ZoneCtx { return .{}; }
    pub inline fn ZoneCS(comptime src: Src, color: u32, depth: i32) ZoneCtx { return .{}; }
    pub inline fn ZoneNCS(comptime src: Src, name: [*:0]const u8, color: u32, depth: i32) ZoneCtx { return .{}; }

    pub inline fn Alloc(ptr: ?*const c_void, size: usize) void { }
    pub inline fn Free(ptr: ?*const c_void) void { }
    pub inline fn SecureAlloc(ptr: ?*const c_void, size: usize) void { }
    pub inline fn SecureFree(ptr: ?*const c_void) void { }
    pub inline fn AllocS(ptr: ?*const c_void, size: usize, depth: c_int) void { }
    pub inline fn FreeS(ptr: ?*const c_void, depth: c_int) void { }
    pub inline fn SecureAllocS(ptr: ?*const c_void, size: usize, depth: c_int) void { }
    pub inline fn SecureFreeS(ptr: ?*const c_void, depth: c_int) void { }

    pub inline fn AllocN(ptr: ?*const c_void, size: usize, name: [*:0]const u8) void { }
    pub inline fn FreeN(ptr: ?*const c_void, name: [*:0]const u8) void { }
    pub inline fn SecureAllocN(ptr: ?*const c_void, size: usize, name: [*:0]const u8) void { }
    pub inline fn SecureFreeN(ptr: ?*const c_void, name: [*:0]const u8) void { }
    pub inline fn AllocNS(ptr: ?*const c_void, size: usize, depth: c_int, name: [*:0]const u8) void { }
    pub inline fn FreeNS(ptr: ?*const c_void, depth: c_int, name: [*:0]const u8) void { }
    pub inline fn SecureAllocNS(ptr: ?*const c_void, size: usize, depth: c_int, name: [*:0]const u8) void { }
    pub inline fn SecureFreeNS(ptr: ?*const c_void, depth: c_int, name: [*:0]const u8) void { }

    pub inline fn Message(text: []const u8) void { }
    pub inline fn MessageL(text: [*:0]const u8) void { }
    pub inline fn MessageC(text: []const u8, color: u32) void { }
    pub inline fn MessageLC(text: [*:0]const u8, color: u32) void { }
    pub inline fn MessageS(text: []const u8, depth: c_int) void { }
    pub inline fn MessageLS(text: [*:0]const u8, depth: c_int) void { }
    pub inline fn MessageCS(text: []const u8, color: u32, depth: c_int) void { }
    pub inline fn MessageLCS(text: [*:0]const u8, color: u32, depth: c_int) void { }

    pub inline fn FrameMark() void { }
    pub inline fn FrameMarkNamed(name: [*:0]const u8) void { }
    pub inline fn FrameMarkStart(name: [*:0]const u8) void { }
    pub inline fn FrameMarkEnd(name: [*:0]const u8) void { }
    pub inline fn FrameImage(image: ?*const c_void, width: u16, height: u16, offset: u8, flip: c_int) void { }

    pub inline fn Plot(name: [*:0]const u8, val: f64) void { }
    pub inline fn AppInfo(text: []const u8) void { }
};

const tracy_full = struct {
    pub const c = @cImport({
        @cDefine("TRACY_ENABLE", "");
        @cInclude("TracyC.h");
    });

    const has_callstack_support = @hasDecl(c, "TRACY_HAS_CALLSTACK") and @hasDecl(c, "TRACY_CALLSTACK");
    const callstack_enabled: c_int = if (has_callstack_support) c.TRACY_CALLSTACK else 0;

    pub const ZoneCtx = struct {
        _zone: c.___tracy_c_zone_context,

        pub inline fn Text(self: ZoneCtx, text: []const u8) void {
            c.___tracy_emit_zone_text(self._zone, text.ptr, text.len);
        }
        pub inline fn Name(self: ZoneCtx, name: []const u8) void {
            c.___tracy_emit_zone_name(self._zone, name.ptr, name.len);
        }
        pub inline fn Value(self: ZoneCtx, val: f64) void {
            c.___tracy_emit_zone_value(self._zone, val);
        }
        pub inline fn End(self: ZoneCtx) void {
            c.___tracy_emit_zone_end(self._zone);
        }
    };

    pub fn InitThread() void {
        c.___tracy_init_thread();
    }

    pub inline fn Zone(comptime src: Src) ZoneCtx {
        const loc = c.___tracy_source_location_data{
            .name = null,
            .function = src.fn_name.ptr,
            .file = src.file.ptr,
            .line = src.line,
            .color = 0,
        };
        if (has_callstack_support) {
            return ZoneCtx{ ._zone = c.___tracy_emit_zone_begin_callstack(&loc, callstack_enabled, 1) };
        } else {
            return ZoneCtx{ ._zone = c.___tracy_emit_zone_begin(&loc, 1) };
        }
    }
    pub inline fn ZoneN(comptime src: Src, name: [*:0]const u8) ZoneCtx {
        const loc = c.___tracy_source_location_data{
            .name = name,
            .function = src.fn_name.ptr,
            .file = src.file.ptr,
            .line = src.line,
            .color = 0,
        };
        if (has_callstack_support) {
            return ZoneCtx{ ._zone = c.___tracy_emit_zone_begin_callstack(&loc, callstack_enabled, 1) };
        } else {
            return ZoneCtx{ ._zone = c.___tracy_emit_zone_begin(&loc, 1) };
        }
    }
    pub inline fn ZoneC(comptime src: Src, color: u32) ZoneCtx {
        const loc = c.___tracy_source_location_data{
            .name = null,
            .function = src.fn_name.ptr,
            .file = src.file.ptr,
            .line = src.line,
            .color = color,
        };
        if (has_callstack_support) {
            return ZoneCtx{ ._zone = c.___tracy_emit_zone_begin_callstack(&loc, callstack_enabled, 1) };
        } else {
            return ZoneCtx{ ._zone = c.___tracy_emit_zone_begin(&loc, 1) };
        }
    }
    pub inline fn ZoneNC(comptime src: Src, name: [*:0]const u8, color: u32) ZoneCtx {
        const loc = c.___tracy_source_location_data{
            .name = name,
            .function = src.fn_name.ptr,
            .file = src.file.ptr,
            .line = src.line,
            .color = color,
        };
        if (has_callstack_support) {
            return ZoneCtx{ ._zone = c.___tracy_emit_zone_begin_callstack(&loc, callstack_enabled, 1) };
        } else {
            return ZoneCtx{ ._zone = c.___tracy_emit_zone_begin(&loc, 1) };
        }
    }
    pub inline fn ZoneS(comptime src: Src, depth: i32) ZoneCtx {
        const loc = c.___tracy_source_location_data{
            .name = null,
            .function = src.fn_name.ptr,
            .file = src.file.ptr,
            .line = src.line,
            .color = 0,
        };
        if (has_callstack_support) {
            return ZoneCtx{ ._zone = c.___tracy_emit_zone_begin_callstack(&loc, depth, 1) };
        } else {
            return ZoneCtx{ ._zone = c.___tracy_emit_zone_begin(&loc, 1) };
        }
    }
    pub inline fn ZoneNS(comptime src: Src, name: [*:0]const u8, depth: i32) ZoneCtx {
        const loc = c.___tracy_source_location_data{
            .name = name,
            .function = src.fn_name.ptr,
            .file = src.file.ptr,
            .line = src.line,
            .color = color,
        };
        if (has_callstack_support) {
            return ZoneCtx{ ._zone = c.___tracy_emit_zone_begin_callstack(&loc, depth, 1) };
        } else {
            return ZoneCtx{ ._zone = c.___tracy_emit_zone_begin(&loc, 1) };
        }
    }
    pub inline fn ZoneCS(comptime src: Src, color: u32, depth: i32) ZoneCtx {
        const loc = c.___tracy_source_location_data{
            .name = name,
            .function = src.fn_name.ptr,
            .file = src.file.ptr,
            .line = src.line,
            .color = color,
        };
        if (has_callstack_support) {
            return ZoneCtx{ ._zone = c.___tracy_emit_zone_begin_callstack(&loc, depth, 1) };
        } else {
            return ZoneCtx{ ._zone = c.___tracy_emit_zone_begin(&loc, 1) };
        }
    }
    pub inline fn ZoneNCS(comptime src: Src, name: [*:0]const u8, color: u32, depth: i32) ZoneCtx {
        const loc = c.___tracy_source_location_data{
            .name = name,
            .function = src.fn_name.ptr,
            .file = src.file.ptr,
            .line = src.line,
            .color = color,
        };
        if (has_callstack_support) {
            return ZoneCtx{ ._zone = c.___tracy_emit_zone_begin_callstack(&loc, depth, 1) };
        } else {
            return ZoneCtx{ ._zone = c.___tracy_emit_zone_begin(&loc, 1) };
        }
    }

    pub inline fn Alloc(ptr: ?*const c_void, size: usize) void {
        if (has_callstack_support) {
            c.___tracy_emit_memory_alloc_callstack(ptr, size, callstack_enabled, 0);
        } else {
            c.___tracy_emit_memory_alloc(ptr, size, 0);
        }
    }
    pub inline fn Free(ptr: ?*const c_void) void {
        if (has_callstack_support) {
            c.___tracy_emit_memory_free_callstack(ptr, callstack_enabled, 0);
        } else {
            c.___tracy_emit_memory_free(ptr, size, 0);
        }
    }
    pub inline fn SecureAlloc(ptr: ?*const c_void, size: usize) void {
        if (has_callstack_support) {
            c.___tracy_emit_memory_alloc_callstack(ptr, size, callstack_enabled, 1);
        } else {
            c.___tracy_emit_memory_alloc(ptr, size, 1);
        }
    }
    pub inline fn SecureFree(ptr: ?*const c_void) void {
        if (has_callstack_support) {
            c.___tracy_emit_memory_free_callstack(ptr, callstack_enabled, 1);
        } else {
            c.___tracy_emit_memory_free(ptr, size, 1);
        }
    }
    pub inline fn AllocS(ptr: ?*const c_void, size: usize, depth: c_int) void {
        if (has_callstack_support) {
            c.___tracy_emit_memory_alloc_callstack(ptr, size, depth, 0);
        } else {
            c.___tracy_emit_memory_alloc(ptr, size, 0);
        }
    }
    pub inline fn FreeS(ptr: ?*const c_void, depth: c_int) void {
        if (has_callstack_support) {
            c.___tracy_emit_memory_free_callstack(ptr, depth, 0);
        } else {
            c.___tracy_emit_memory_free(ptr, 0);
        }
    }
    pub inline fn SecureAllocS(ptr: ?*const c_void, size: usize, depth: c_int) void {
        if (has_callstack_support) {
            c.___tracy_emit_memory_alloc_callstack(ptr, size, depth, 1);
        } else {
            c.___tracy_emit_memory_alloc(ptr, size, 1);
        }
    }
    pub inline fn SecureFreeS(ptr: ?*const c_void, depth: c_int) void {
        if (has_callstack_support) {
            c.___tracy_emit_memory_free_callstack(ptr, depth, 1);
        } else {
            c.___tracy_emit_memory_free(ptr, 1);
        }
    }

    pub inline fn AllocN(ptr: ?*const c_void, size: usize, name: [*:0]const u8) void {
        if (has_callstack_support) {
            c.___tracy_emit_memory_alloc_callstack_named(ptr, size, callstack_enabled, 0, name);
        } else {
            c.___tracy_emit_memory_alloc_named(ptr, size, 0, name);
        }
    }
    pub inline fn FreeN(ptr: ?*const c_void, name: [*:0]const u8) void {
        if (has_callstack_support) {
            c.___tracy_emit_memory_free_callstack_named(ptr, callstack_enabled, 0, name);
        } else {
            c.___tracy_emit_memory_free_named(ptr, 0, name);
        }
    }
    pub inline fn SecureAllocN(ptr: ?*const c_void, size: usize, name: [*:0]const u8) void {
        if (has_callstack_support) {
            c.___tracy_emit_memory_alloc_callstack_named(ptr, size, callstack_enabled, 1, name);
        } else {
            c.___tracy_emit_memory_alloc_named(ptr, size, 1, name);
        }
    }
    pub inline fn SecureFreeN(ptr: ?*const c_void, name: [*:0]const u8) void {
        if (has_callstack_support) {
            c.___tracy_emit_memory_free_callstack_named(ptr, callstack_enabled, 1, name);
        } else {
            c.___tracy_emit_memory_free_named(ptr, 1, name);
        }
    }
    pub inline fn AllocNS(ptr: ?*const c_void, size: usize, depth: c_int, name: [*:0]const u8) void {
        if (has_callstack_support) {
            c.___tracy_emit_memory_alloc_callstack_named(ptr, size, depth, 0, name);
        } else {
            c.___tracy_emit_memory_alloc_named(ptr, size, 0, name);
        }
    }
    pub inline fn FreeNS(ptr: ?*const c_void, depth: c_int, name: [*:0]const u8) void {
        if (has_callstack_support) {
            c.___tracy_emit_memory_free_callstack_named(ptr, depth, 0, name);
        } else {
            c.___tracy_emit_memory_free_named(ptr, 0, name);
        }
    }
    pub inline fn SecureAllocNS(ptr: ?*const c_void, size: usize, depth: c_int, name: [*:0]const u8) void {
        if (has_callstack_support) {
            c.___tracy_emit_memory_alloc_callstack_named(ptr, size, depth, 1, name);
        } else {
            c.___tracy_emit_memory_alloc_named(ptr, size, 1, name);
        }
    }
    pub inline fn SecureFreeNS(ptr: ?*const c_void, depth: c_int, name: [*:0]const u8) void {
        if (has_callstack_support) {
            c.___tracy_emit_memory_free_callstack_named(ptr, depth, 1, name);
        } else {
            c.___tracy_emit_memory_free_named(ptr, 1, name);
        }
    }

    pub inline fn Message(text: []const u8) void {
        c.___tracy_emit_message(text.ptr, text.len, callstack_enabled);
    }
    pub inline fn MessageL(text: [*:0]const u8) void {
        c.___tracy_emit_messageL(text, color, callstack_enabled);
    }
    pub inline fn MessageC(text: []const u8, color: u32) void {
        c.___tracy_emit_messageC(text.ptr, text.len, color, callstack_enabled);
    }
    pub inline fn MessageLC(text: [*:0]const u8, color: u32) void {
        c.___tracy_emit_messageLC(text, color, callstack_enabled);
    }
    pub inline fn MessageS(text: []const u8, depth: c_int) void {
        const inner_depth: c_int = if (has_callstack_support) depth else 0;
        c.___tracy_emit_message(text.ptr, text.len, inner_depth);
    }
    pub inline fn MessageLS(text: [*:0]const u8, depth: c_int) void {
        const inner_depth: c_int = if (has_callstack_support) depth else 0;
        c.___tracy_emit_messageL(text, inner_depth);
    }
    pub inline fn MessageCS(text: []const u8, color: u32, depth: c_int) void {
        const inner_depth: c_int = if (has_callstack_support) depth else 0;
        c.___tracy_emit_messageC(text.ptr, text.len, color, inner_depth);
    }
    pub inline fn MessageLCS(text: [*:0]const u8, color: u32, depth: c_int) void {
        const inner_depth: c_int = if (has_callstack_support) depth else 0;
        c.___tracy_emit_messageLC(text, color, inner_depth);
    }

    pub inline fn FrameMark() void {
        c.___tracy_emit_frame_mark(null);
    }
    pub inline fn FrameMarkNamed(name: [*:0]const u8) void {
        c.___tracy_emit_frame_mark(name);
    }
    pub inline fn FrameMarkStart(name: [*:0]const u8) void {
        c.___tracy_emit_frame_mark_start(name);
    }
    pub inline fn FrameMarkEnd(name: [*:0]const u8) void {
        c.___tracy_emit_frame_mark_end(name);
    }
    pub inline fn FrameImage(image: ?*const c_void, width: u16, height: u16, offset: u8, flip: c_int) void {
        c.___tracy_emit_frame_image(image, width, height, offset, flip);
    }

    pub inline fn Plot(name: [*:0]const u8, val: f64) void {
        c.___tracy_emit_plot(name, val);
    }
    pub inline fn AppInfo(text: []const u8) void {
        c.___tracy_emit_message_appinfo(text.ptr, text.len);
    }
};