/// This file contains the source code for the Scripting Object within the engine. It provide a central source to interact with the lua scripting backend.
const std = @import("std");
const zlua = @import("zlua");
const sdl = @import("sdl2");
const Lua = zlua.Lua;
const CallArgs = zlua.Lua.ProtectedCallArgs;
const LuaState = zlua.LuaState;
const rl = @import("raylib");
const Engine = @import("engine.zig").Engine;
pub const CFn = *const fn (state: ?*LuaState) callconv(.C) c_int;
const event_system = @import("event_system.zig");
const Event = event_system.Event;

pub const FnEntry = struct {
    table: [:0]const u8,
    name: [:0]const u8,
    func: CFn,
};

// JUST FOR TESTING: these are put here just for testing for now. Will move to a separate file.
fn log(lua: *Lua) c_int {
    const msg = lua.toString(1) catch |err| {
        std.debug.print("Lua `log` error: {s}\n", .{@errorName(err)});
        return 0;
    };
    std.debug.print("\x1b[34m[Lua Log]: {s}\x1b[0m\n", .{msg});
    return 0;
}

fn getEngine(lua: *Lua) !*Engine {
    return lua.toUserdata(Engine, Lua.upvalueIndex(1));
}

const EngineTypes = @import("engine_types.zig");
const Vec2 = EngineTypes.Vec2;

// fn create_window() c_int {}

fn get_main_window_id(lua: *Lua) c_int {
    const engine = getEngine(lua) catch |err| {
        std.debug.print("\x1b[91mget_main_window_id error:\x1b[0m could not get engine pointer: {s}\n", .{@errorName(err)});
        return 0;
    };
    _ = lua.pushString(engine.main_window_id);
    std.debug.print("\x1b[96mPushed:\x1b[0m {s}\n", .{engine.main_window_id});
    return 1;
}

fn get_window_dimensions(lua: *Lua) c_int {
    const engine = getEngine(lua) catch |err| {
        std.debug.print("\x1b[91mget_window_dimensions error:\x1b[0m could not get engine pointer: {s}\n", .{@errorName(err)});
        return 0;
    };

    const num_args = lua.getTop();
    if (num_args < 1) {
        std.debug.print("\x1b[91mget_window_dimensions error:\x1b[0m 1 argument required, recieved {d}.\n", .{num_args});
        return 0;
    }

    const window_id: []const u8 = lua.toString(1) catch {
        std.debug.print("\x1b[91mget_window_dimensions error:\x1b[0m Expected string for param 'window_id'\n", .{});
        return 0;
    };

    const dims = engine.window_manager.getWindowDimensions(window_id) catch Vec2{ .x = 0, .y = 0 };
    _ = lua.pushNumber(dims.x);
    _ = lua.pushNumber(dims.y);
    return 2;
}

fn draw_circle(lua: *Lua) c_int {
    const engine = getEngine(lua) catch |err| {
        std.debug.print("\x1b[91mdraw_circle error:\x1b[0m could not get engine pointer: {s}\n", .{@errorName(err)});
        return 0;
    };

    const num_args = lua.getTop();
    if (num_args < 9) {
        std.debug.print("\x1b[91mdraw_circle error:\x1b[0m 9 arguments required, recieved {d}.\n", .{num_args});
        return 0;
    }

    var window_id: []const u8 = lua.toString(1) catch {
        std.debug.print("\x1b[91mdraw_circle error:\x1b[0m Expected string for param 'window_id'\n", .{});
        return 0;
    };

    _ = engine.window_manager.getWindow(window_id) catch {
        std.debug.print("\x1b[91mdraw_circle error:\x1b[0m Failed to find window with id: {s}\n", .{window_id});
        std.debug.print("\x1b[93mdraw_circle warning:\x1b[0m Defaulting to main window with id: '{s}'\n", .{engine.main_window_id});
        window_id = engine.main_window_id;
    };

    const x: f32 = @as(f32, @floatCast(lua.toNumber(2) catch 0));
    const y: f32 = @as(f32, @floatCast(lua.toNumber(3) catch 0));
    const rad: f32 = @as(f32, @floatCast(lua.toNumber(4) catch 0));
    const r: u8 = @as(u8, @intFromFloat(lua.toNumber(5) catch 255));
    const g: u8 = @as(u8, @intFromFloat(lua.toNumber(6) catch 255));
    const b: u8 = @as(u8, @intFromFloat(lua.toNumber(7) catch 255));
    const a: u8 = @as(u8, @intFromFloat(lua.toNumber(8) catch 255));
    const filled: bool = lua.toBoolean(9);

    _ = engine.renderer_manager.getRenderer(window_id) catch {
        std.debug.print("\x1b[91mdraw_circle error:\x1b[0m Failed to get renderer with id: '{s}'. Unable to draw circle.\n", .{window_id});
        return 0;
    };

    const pos: Vec2 = Vec2{ .x = x, .y = y };
    const col: sdl.Color = sdl.Color{ .r = r, .g = g, .b = b, .a = a };
    engine.renderer_manager.queue(window_id, .{ .two_dimensional = .{ .circle = .{ .position = pos, .radius = rad, .color = col, .filled = filled } } }) catch {
        std.debug.print("\x1b[91mdraw_circle error:\x1b[0m Failed to queue drawable in renderer with id: {s}", .{window_id});
        return 0;
    };
    return 0;
}

fn draw_rect(lua: *Lua) c_int {
    const engine = getEngine(lua) catch |err| {
        std.debug.print("\x1b[91mdraw_rect error:\x1b[0m could not get engine pointer: {s}\n", .{@errorName(err)});
        return 0;
    };

    const num_args = lua.getTop();
    if (num_args < 10) {
        std.debug.print("\x1b[91mdraw_rect error:\x1b[0m 10 arguments required, recieved {d}.\n", .{num_args});
        return 0;
    }

    var window_id: []const u8 = lua.toString(1) catch {
        std.debug.print("\x1b[91mdraw_rect error:\x1b[0m Expected string for param 'window_id'\n", .{});
        return 0;
    };

    _ = engine.window_manager.getWindow(window_id) catch {
        std.debug.print("\x1b[91mdraw_rect error:\x1b[0m Failed to find window with id: {s}\n", .{window_id});
        std.debug.print("\x1b[93mdraw_rect warning:\x1b[0m Defaulting to main window with id: '{s}'\n", .{engine.main_window_id});
        window_id = engine.main_window_id;
    };

    const x: f32 = @as(f32, @floatCast(lua.toNumber(2) catch 0));
    const y: f32 = @as(f32, @floatCast(lua.toNumber(3) catch 0));
    const width: i32 = @as(i32, @intFromFloat(lua.toNumber(4) catch 0));
    const height: i32 = @as(i32, @intFromFloat(lua.toNumber(5) catch 0));
    const r: u8 = @as(u8, @intFromFloat(lua.toNumber(6) catch 255));
    const g: u8 = @as(u8, @intFromFloat(lua.toNumber(7) catch 255));
    const b: u8 = @as(u8, @intFromFloat(lua.toNumber(8) catch 255));
    const a: u8 = @as(u8, @intFromFloat(lua.toNumber(9) catch 255));
    const filled: bool = lua.toBoolean(10);

    _ = engine.renderer_manager.getRenderer(window_id) catch {
        std.debug.print("\x1b[91mdraw_rect error:\x1b[0m Failed to get renderer with id: '{s}'. Unable to draw circle.\n", .{window_id});
        return 0;
    };

    const pos: Vec2 = Vec2{ .x = x, .y = y };
    const col: sdl.Color = sdl.Color{ .r = r, .g = g, .b = b, .a = a };
    engine.renderer_manager.queue(window_id, .{ .two_dimensional = .{ .rect = .{ .position = pos, .height = height, .width = width, .color = col, .filled = filled } } }) catch {
        std.debug.print("\x1b[91mdraw_rect error:\x1b[0m Failed to queue drawable in renderer with id: {s}", .{window_id});
        return 0;
    };
    return 0;
}

const FN_ENTRIES = [_]FnEntry{
    .{ .table = "Engine", .name = "log", .func = zlua.wrap(log) }, // MUST USE WRAP ON Fn's
    .{ .table = "Engine", .name = "get_main_window_id", .func = zlua.wrap(get_main_window_id) },
    .{ .table = "Engine", .name = "get_window_dimensions", .func = zlua.wrap(get_window_dimensions) },
    .{ .table = "Render", .name = "draw_circle", .func = zlua.wrap(draw_circle) },
    .{ .table = "Render", .name = "draw_rect", .func = zlua.wrap(draw_rect) },
};
// END JUST FOR TESTING

pub const Scripting = struct {
    lua: *Lua,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !Scripting {
        var lua_state = try Lua.init(allocator);
        _ = lua_state.openLibs();
        return Scripting{
            .lua = lua_state,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Scripting) void {
        self.lua.deinit();
    }

    pub fn addFnToTable(self: *Scripting, l: *Lua, engine_ptr: *Engine, table_name: [:0]const u8, func_name: [:0]const u8, func: CFn) void {
        _ = self;
        const table: zlua.LuaType = l.getGlobal(table_name) catch .nil;
        if (table == .nil) {
            l.pop(1);
            l.newTable();
            l.pushValue(-1);
            l.setGlobal(table_name);
        }
        l.pushLightUserdata(engine_ptr);
        l.pushClosure(func, 1);
        l.setField(-2, func_name);
        l.pop(1);
    }

    // Add a function to the Engine Table
    pub fn addEngineFunc(self: *Scripting, l: *Lua, ptr: *Engine, name: [:0]const u8, func: CFn) void {
        _ = self;
        const table: zlua.LuaType = l.getGlobal("Engine") catch .nil;
        if (table == .nil) {
            l.pop(1);
            l.newTable();
            l.pushValue(-1);
            l.setGlobal("Engine");
        }
        l.pushLightUserdata(ptr);
        l.pushClosure(func, 1);
        l.setField(-2, name);
        l.pop(1);
    }

    pub fn setupBindings(self: *Scripting, engine_ptr: *Engine) !void {
        // self.addEngineFunc(self.lua, engine_ptr, "log", zlua.wrap(log));
        // self.addFnToTable(self.lua, engine_ptr, "Engine", "log", zlua.wrap(log));
        for (FN_ENTRIES) |fe| {
            self.addFnToTable(self.lua, engine_ptr, fe.table, fe.name, fe.func);
        }
    }

    pub fn doString(self: *Scripting, code: []const u8) !void {
        self.lua.doString(code) catch |err| {
            self.lua.traceback(self.lua, null, 0);
            const stack_info: [:0]const u8 = self.lua.toNumber(1) catch "";
            std.debug.print("\n\n\x1b[33mScripting.doString error:\x1b[0m \x1b[34m{}\x1b[0m\n{s}\n\n\n", .{ err, stack_info });
            return err;
        };
    }

    pub fn doFile(self: *Scripting, path: [:0]const u8) !void {
        self.lua.loadFile(path, .binary_text) catch |err| {
            self.lua.traceback(self.lua, null, 0);
            const stack_info: [:0]const u8 = self.lua.toString(1) catch "";
            std.debug.print("\n\n\x1b[33mScripting.doFile error:[Failed to load file]:\x1b[0m \x1b[34m{}\x1b[0m\n{s}\n\n\n", .{
                err,
                stack_info,
            });
            return err;
        };

        self.lua.protectedCall(.{ .results = zlua.mult_return }) catch |err| {
            std.debug.print("Scripting.doFile error:[Failed to call file]: {}", .{err});
            return err;
        };
    }

    pub fn call(self: *Scripting, args: CallArgs) !void {
        self.lua.protectedCall(args) catch |err| {
            std.debug.print("Scripting.call error: {}", .{err});
            return err;
        };
    }
};
