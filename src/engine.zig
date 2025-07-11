const std = @import("std");
const zlua = @import("zlua");
const toml = @import("toml");
const sdl = @import("sdl2");
const Lua = zlua.Lua;
const CallArgs = zlua.Lua.ProtectedCallArgs;
const scripting = @import("scripting.zig");
const asset_manager = @import("asset_manager.zig");
const window_manager = @import("window_manager.zig");
const renderer_manager = @import("renderer_manager.zig");

const SDL_DEFAULT_INIT_FLAGS: sdl.InitFlags = .{
    .audio = true,
    .events = true,
    .video = true,
    .game_controller = true,
};

const DEFAULT_WINDOW_CFG: window_manager.WindowConfig = .{ .title = "Main Window", .x = .{ .centered = {} }, .y = .{ .centered = {} }, .width = 1000, .height = 1000, .flags = .{ .borderless = true } };

pub const Engine = struct {
    allocator: std.mem.Allocator,
    scripting: *scripting.Scripting,
    window_manager: *window_manager.WindowManager,
    renderer_manager: *renderer_manager.RendererManager,
    asset_manager: *asset_manager.AssetManager,
    main_window_id: []const u8,
    main_renderer_id: []const u8,

    lua_logic_thread: std.Thread,
    should_quit_lua_thread: std.atomic.Value(bool),

    pub fn init(allocator: std.mem.Allocator) !*Engine {
        var engine = try allocator.create(Engine);
        engine.allocator = allocator;

        try sdl.init(SDL_DEFAULT_INIT_FLAGS);

        const wm = try allocator.create(window_manager.WindowManager);
        wm.* = try window_manager.WindowManager.init(allocator);
        engine.window_manager = wm;

        const rm = try allocator.create(renderer_manager.RendererManager);
        rm.* = try renderer_manager.RendererManager.init(allocator);
        engine.renderer_manager = rm;

        const main_win_id = try engine.window_manager.spawnWindow(DEFAULT_WINDOW_CFG);
        engine.main_window_id = try allocator.dupe(u8, main_win_id);
        const main_win = try engine.window_manager.getWindow(main_win_id);
        const main_ren_id = try engine.renderer_manager.createRenderer(main_win, null, .{ .accelerated = true });
        engine.main_renderer_id = try allocator.dupe(u8, main_ren_id);

        const am = try allocator.create(asset_manager.AssetManager);
        am.* = try asset_manager.AssetManager.init(allocator);
        engine.asset_manager = am;

        const s = try allocator.create(scripting.Scripting);
        s.* = try scripting.Scripting.init(allocator);
        engine.scripting = s;

        try engine.scripting.setupBindings(engine);

        try engine.scripting.doFile("scripts/engine/init.lua");
        try engine.scripting.doFile("scripts/game/main.lua");

        engine.should_quit_lua_thread = std.atomic.Value(bool).init(false);

        engine.lua_logic_thread = try std.Thread.spawn(.{}, luaLogicThreadFn, .{engine});

        return engine;
    }

    pub fn deinit(self: *Engine) void {
        self.should_quit_lua_thread.store(true, .seq_cst);
        self.lua_logic_thread.join();

        self.scripting.deinit();
        self.allocator.free(self.main_renderer_id);
        self.allocator.free(self.main_window_id);
        self.allocator.destroy(self.scripting);

        self.asset_manager.deinit();
        self.allocator.destroy(self.asset_manager);

        self.renderer_manager.deinit();
        self.allocator.destroy(self.renderer_manager);

        self.window_manager.deinit();
        self.allocator.destroy(self.window_manager);

        sdl.quit();

        self.allocator.destroy(self);
    }

    pub fn shouldClose(self: *Engine) bool {
        _ = self;
        return false;
    }

    fn luaLogicThreadFn(engine: *Engine) !void {
        const init_get_result = engine.scripting.lua.getGlobal("_init");
        if (init_get_result) |init_value| {
            if (init_value == .function) {
                std.debug.print("\x1b[32mLua Logic Thread: _init function found.\x1b[0m\n", .{});
                try engine.scripting.call(CallArgs{ .args = 0, .results = 0 });
            } else {
                engine.scripting.lua.pop(1);
                std.debug.print("Lua Logic Thread Warning: _init() global found but is not a function (type: {}). Skipping call.\n", .{init_value});
            }
        } else |err| {
            std.debug.print("Lua Logic Thread Warning: Failed to retrieve Lua global '_init': {s}. Skipping call.\n", .{@errorName(err)});
        }

        while (!engine.should_quit_lua_thread.load(.seq_cst)) {
            const update_get_result = engine.scripting.lua.getGlobal("_update");
            if (update_get_result) |update_value| {
                if (update_value == .function) {
                    _ = try engine.scripting.call(CallArgs{ .args = 0, .results = 0 });
                } else {
                    engine.scripting.lua.pop(1);
                    std.debug.print("Lua Logic Thread Warning: _update() global found but is not a function (type: {}). Game logic might not be updated.\n", .{update_value});
                }
            } else |err| {
                std.debug.print("Lua Logic Thread Warning: Failed to retrieve Lua global '_update': {s}. Game logic might not be updated.\n", .{@errorName(err)});
            }

            const draw_get_result = engine.scripting.lua.getGlobal("_draw");
            if (draw_get_result) |draw_value| {
                if (draw_value == .function) {
                    _ = try engine.scripting.call(CallArgs{ .args = 0, .results = 0 });
                } else {
                    engine.scripting.lua.pop(1);
                    std.debug.print("Lua Logic Thread Warning: _draw() global found but is not a function (type: {}). Nothing will be queued for drawing.\n", .{draw_value});
                }
            } else |err| {
                std.debug.print("Lua Logic Thread Warning: Failed to retrieve Lua global '_draw': {s}. Nothing will be queued for drawing.\n", .{@errorName(err)});
            }

            std.Thread.sleep(1_000_000 / 120); // Sleep for 1/120th of a second
        }
        std.debug.print("Lua Logic Thread: Exiting.\n", .{});
    }

    pub fn run(self: *Engine) !void {
        main_loop: while (true) {
            while (sdl.pollEvent()) |ev| {
                switch (ev) {
                    .quit => {
                        self.should_quit_lua_thread.store(true, .seq_cst);
                        break :main_loop;
                    },
                    .window => |w| {
                        try self.window_manager.processWindowEvent(w);
                    },
                    else => {},
                }
            }

            try self.renderer_manager.presentAll();
        }
        std.debug.print("Main Thread: Exiting main loop.\n", .{});
    }
};
