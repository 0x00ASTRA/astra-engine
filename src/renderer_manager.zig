const std = @import("std");
const sdl = @import("sdl2");

pub const RendererManager = struct {
    const Self = @This();
    allocator: std.mem.Allocator,
    renderers: std.StringHashMap(sdl.Renderer),

    pub fn init(allocator: std.mem.Allocator) !Self {
        const renderers_map = std.StringHashMap(sdl.Renderer).init(allocator);
        const ren = RendererManager{ .allocator = allocator, .renderers = renderers_map };
        return ren;
    }

    pub fn deinit(self: *Self) void {
        var iter = self.renderers.valueIterator();
        while (iter.next()) |ren| {
            ren.destroy();
        }
        self.renderers.deinit();
        self.allocator.destroy(self);
    }

    pub fn createRenderer(self: *Self, window: sdl.Window, index: ?u31, flags: sdl.RendererFlags) ![]const u8 {
        const ren = try sdl.createRenderer(window, index, flags);
        const ren_id = try self.allocator.alloc(u8, 16);
        defer self.allocator.free(ren_id);
        const r = std.crypto.random;
        r.bytes(ren_id);
        try self.renderers.put(try self.allocator.dupe(u8, ren_id), ren);
        return try self.allocator.dupe(u8, ren_id);
    }

    pub fn getRenderer(self: *Self, id: []const u8) !sdl.Renderer {
        const ren = self.renderers.get(id);

        if (ren) |r| {
            return r;
        } else {
            return error.InvalidRendererId;
        }
    }

    pub fn clear(self: *Self, renderer_id: []const u8) !void {
        const ren: sdl.Renderer = try self.renderers.get(renderer_id);
        ren.clear();
    }

    pub fn present(self: *Self, renderer_id: []const u8) !void {
        const ren: sdl.Renderer = try self.renderers.get(renderer_id);
        ren.present();
    }

    pub fn presentAll(self: *Self) void {
        var iter = self.renderers.valueIterator();
        while (iter.next()) |r| {
            r.present();
        }
    }

    pub fn setColorRGB(self: *Self, renderer_id: []const u8, r: u8, g: u8, b: u8) !void {
        const ren: sdl.Renderer = try self.renderers.get(renderer_id);
        ren.setColorRGB(r, g, b);
    }

    pub fn setColorRGBA(self: *Self, renderer_id: []const u8, r: u8, g: u8, b: u8, a: u8) !void {
        const ren: sdl.Renderer = try self.renderers.get(renderer_id);
        ren.setColorRGBA(r, g, b, a);
    }
};
