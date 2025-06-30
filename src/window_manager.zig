const std = @import("std");
const sdl = @import("sdl2");
const toml = @import("toml");
const Vec2 = @import("engine_types.zig").Vec2;

pub const WindowConfig = struct { title: []const u8, x: sdl.WindowPosition, y: sdl.WindowPosition, width: usize, height: usize, flags: sdl.WindowFlags };

pub const WindowManager = struct {
    const Self = @This();
    allocator: std.mem.Allocator,
    windows: std.StringHashMap(sdl.Window),

    pub fn init(allocator: std.mem.Allocator) !Self {
        const window_map = std.StringHashMap(sdl.Window).init(allocator);

        return Self{ .allocator = allocator, .windows = window_map };
    }

    pub fn deinit(self: *Self) void {
        var iter = self.windows.valueIterator();
        while (iter.next()) |win| {
            win.destroy();
        }
        self.windows.deinit();
    }

    pub fn processWindowEvent(self: *Self, event: sdl.WindowEvent) !void {
        switch (event.type) {
            .close => {
                try self.destroyWindow(try std.fmt.allocPrint(self.allocator, "{}", .{event.window_id}));
            },
            else => {},
        }
    }

    pub fn spawnWindow(self: *Self, window_cfg: WindowConfig) ![]const u8 {
        const title: [:0]const u8 = try self.allocator.dupeZ(u8, window_cfg.title);
        const window: sdl.Window = try sdl.createWindow(title, window_cfg.x, window_cfg.y, window_cfg.width, window_cfg.height, window_cfg.flags);
        const win_id: []const u8 = try std.fmt.allocPrint(self.allocator, "{}", .{try window.getID()});
        try self.windows.put(win_id, window);
        return win_id;
    }

    pub fn getWindow(self: *Self, window_id: []const u8) !sdl.Window {
        const win = self.windows.get(window_id);
        if (win) |w| {
            return w;
        } else {
            return error.InvalidWindowId;
        }
    }

    pub fn getWindowDimensions(self: *Self, window_id: []const u8) !Vec2 {
        const win: sdl.Window = try self.getWindow(window_id);
        const size = win.getSize();
        return Vec2{ .x = @floatFromInt(size.width), .y = @floatFromInt(size.height) };
    }

    pub fn destroyWindow(self: *Self, window_id: []const u8) !void {
        const win: sdl.Window = try self.getWindow(window_id);
        win.destroy();
    }
};
