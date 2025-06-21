/// This file contains the source code for the Scripting Object within the engine. It provide a central source to interact with the lua scripting backend.
const std = @import("std");
const zlua = @import("zlua");
const Lua = zlua.Lua;
const CallArgs = zlua.Lua.ProtectedCallArgs;
const LuaState = zlua.LuaState;
const rl = @import("raylib");
const Engine = @import("engine.zig").Engine;
const Drawable = @import("renderer.zig").Drawable;
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
const FN_ENTRIES = [_]FnEntry{
    .{ .table = "Engine", .name = "log", .func = zlua.wrap(log) }, // MUST USE WRAP ON Fn's
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
