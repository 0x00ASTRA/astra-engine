const std = @import("std");
const sdl = @import("sdl2");
const EngineTypes = @import("engine_types.zig");
const AssetManager = @import("asset_manager.zig").AssetManager;
const Vec2 = EngineTypes.Vec2;
const Vec3 = EngineTypes.Vec3;
const Quat = EngineTypes.Quat;

pub const Drawable2D = union(enum) {
    circle: struct {
        position: Vec2,
        radius: f32,
        color: sdl.Color,
        filled: bool,

        fn plotPoints(points_array: *std.ArrayList(sdl.Point), cx: i32, cy: i32, x: i32, y: i32) !void {
            try points_array.append(.{ .x = cx + x, .y = cy + y });
            try points_array.append(.{ .x = cx + y, .y = cy + x });
            try points_array.append(.{ .x = cx - x, .y = cy + y });
            try points_array.append(.{ .x = cx - y, .y = cy + x });
            try points_array.append(.{ .x = cx + x, .y = cy - y });
            try points_array.append(.{ .x = cx + y, .y = cy - x });
            try points_array.append(.{ .x = cx - x, .y = cy - y });
            try points_array.append(.{ .x = cx - y, .y = cy - x });
        }

        pub fn genPoints(self: *const @This(), allocator: std.mem.Allocator) ![]const sdl.Point {
            var point_array = std.ArrayList(sdl.Point).init(allocator);
            defer point_array.deinit();

            const est_cap = 2 * std.math.pi * 8;
            try point_array.ensureTotalCapacity(@as(usize, @intFromFloat(est_cap)) * 2);

            var x: i32 = 0;
            var y: i32 = @intFromFloat(self.radius);
            var p: i32 = 3 - (2 * @as(i32, @intFromFloat(self.radius)));

            try plotPoints(
                &point_array,
                @as(i32, @intFromFloat(self.position.x)),
                @as(i32, @intFromFloat(self.position.y)),
                x,
                y,
            );

            while (x <= y) {
                x += 1;
                if (p < 0) {
                    p = p + (4 * x) + 6;
                } else {
                    y -= 1;
                    p = p + (4 * (x - y)) + 10;
                }
                if (x <= y) {
                    try plotPoints(&point_array, @as(i32, @intFromFloat(self.position.x)), @as(i32, @intFromFloat(self.position.y)), x, y);
                }
            }

            return point_array.toOwnedSlice();
        }

        pub fn drawFilled(self: *const @This(), renderer: sdl.Renderer) !void {
            const cx: i32 = @as(i32, @intFromFloat(self.position.x));
            const cy: i32 = @as(i32, @intFromFloat(self.position.y));
            const r: i32 = @as(i32, @intFromFloat(self.radius));

            var x: i32 = r;
            var y: i32 = 0;
            var err: i32 = 0;

            try renderer.setColor(self.color);

            while (x >= y) {
                // Draw horizontal lines for each quadrant
                try renderer.drawLine(cx - x, cy + y, cx + x, cy + y);
                try renderer.drawLine(cx - x, cy - y, cx + x, cy - y);
                try renderer.drawLine(cx - y, cy + x, cx + y, cy + x);
                try renderer.drawLine(cx - y, cy - x, cx + y, cy - x);

                y += 1;
                err += 1 + 2 * y;
                if (2 * (err - x) + 1 > 0) {
                    x -= 1;
                    err += 1 - 2 * x;
                }
            }
        }

        pub fn draw(self: *const @This(), allocator: std.mem.Allocator, renderer: sdl.Renderer) !void {
            try renderer.setColor(self.color);
            if (self.filled) {
                try self.drawFilled(renderer);
                return;
            }
            const points = try self.genPoints(allocator);
            defer allocator.free(points);
            try renderer.drawPoints(points);
        }
    },
    rect: struct {
        position: Vec2,
        width: i32,
        height: i32,
        color: sdl.Color,
        filled: bool,
        pub fn draw(self: *const @This(), renderer: sdl.Renderer) !void {
            const init_col = try renderer.getColor();
            try renderer.setColor(self.color);
            if (self.filled) {
                try renderer.fillRect(sdl.Rectangle{ .width = self.width, .height = self.height, .x = @as(i32, @intFromFloat(self.position.x)), .y = @as(i32, @intFromFloat(self.position.y)) });
                try renderer.setColor(init_col);
                return;
            }
            try renderer.drawRect(sdl.Rectangle{ .width = self.width, .height = self.height, .x = @as(i32, @intFromFloat(self.position.x)), .y = @as(i32, @intFromFloat(self.position.y)) });
            try renderer.setColor(init_col);
        }
    },
    texture: struct {
        name: [:0]const u8,
        position: Vec2,
        crop: ?sdl.Rectangle,
        tint: sdl.Color,
        // pub fn draw(self: *const @This(), renderer: sdl.Renderer) !void {
        //     // const t_info: sdl.Texture.Info = try self.asset.query();
        //     const rect = sdl.Rectangle{ .x = @as(i32, @intFromFloat(self.position.x)), .y = @as(i32, @intFromFloat(self.position.y)), .width = 1000, .height = 1000 };
        //     // std.debug.print("\x1b[94mTexture Info\x1b[0m {}\n \x1b[92mRect\x1b[0m: {}\n", .{ t_info, &rect });
        //     _ = rect;
        //     try renderer.copy(self.asset, null, null);
        // }
    },
    text: struct {
        message: [:0]const u8,
        position: Vec2,
        crop: ?sdl.Rectangle,
        color: sdl.Color,
        font_size: i32,
        font_name: [:0]const u8,
    },
    fps: struct { position: Vec2 },
};

pub const Drawable3D = union(enum) {
    cube: struct { position: Vec3, rotation: Quat, scale: Vec3 },
};

pub const Drawable = union(enum) {
    two_dimensional: Drawable2D,
    three_dimensional: Drawable3D,
};

pub const RenderQueueData = struct { entries: std.ArrayList(Drawable), mutex: std.Thread.Mutex };

pub const RendererManager = struct {
    const Self = @This();
    allocator: std.mem.Allocator,
    renderers: std.StringHashMap(sdl.Renderer),
    render_queues: std.StringHashMap(RenderQueueData),

    pub fn init(allocator: std.mem.Allocator) !Self {
        const renderers_map = std.StringHashMap(sdl.Renderer).init(allocator);
        const renderer_queues = std.StringHashMap(RenderQueueData).init(allocator);
        const ren = RendererManager{ .allocator = allocator, .renderers = renderers_map, .render_queues = renderer_queues };
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
        const ren_id = try std.fmt.allocPrint(self.allocator, "{}", .{try window.getID()});
        defer self.allocator.free(ren_id);
        if (self.renderers.get(ren_id)) |r| {
            _ = r;
            std.debug.print("\x1b[91mcreateRenderer error:\x1b[0m Window '{s}' is already attached to a renderer. Please use only 1 window per renderer instance.\n", .{ren_id});
            return error.WindowOccupied;
        }
        try self.renderers.put(try self.allocator.dupe(u8, ren_id), ren);
        try self.render_queues.put(try self.allocator.dupe(u8, ren_id), RenderQueueData{ .entries = std.ArrayList(Drawable).init(self.allocator), .mutex = std.Thread.Mutex{} });
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

    pub fn queue(self: *Self, renderer_id: []const u8, drawable: Drawable) !void {
        const ren_queue = self.render_queues.getPtr(renderer_id);
        if (ren_queue) |ren| {
            ren.mutex.lock();
            defer ren.mutex.unlock();
            try ren.entries.append(drawable);
        }
    }

    fn consume_queue(self: *Self, renderer_id: []const u8, asset_manager: *AssetManager) !void {
        const ren: sdl.Renderer = try self.getRenderer(renderer_id);
        if (self.render_queues.getPtr(renderer_id)) |rq| {
            var entries = std.ArrayList(Drawable).init(self.allocator);
            defer entries.deinit();

            rq.mutex.lock();
            errdefer rq.mutex.unlock();

            try entries.appendSlice(rq.entries.items);
            rq.entries.clearRetainingCapacity();
            rq.mutex.unlock();

            for (entries.items) |item| {
                switch (item) {
                    .two_dimensional => |s| {
                        switch (s) {
                            .circle => |c| {
                                try c.draw(self.allocator, ren);
                            },
                            .rect => |r| {
                                try r.draw(ren);
                            },
                            // .text => |t| {
                            //     _ = t;
                            // },
                            .texture => |t| {
                                const asset = try asset_manager.loadTexture(ren, t.name, true);
                                // const rect = sdl.Rectangle{ .x = @as(i32, @intFromFloat(self.position.x)), .y = @as(i32, @intFromFloat(self.position.y)), .width = 1000, .height = 1000 };
                                try ren.copy(asset, null, null);
                                try asset_manager.unloadTexture(t.name, false);
                            },
                            .text => |t| {
                                const asset = try asset_manager.loadFontTexture(ren, t.message, t.font_name, t.font_size, t.color);
                                const asset_info = try asset.query();
                                const rect = sdl.Rectangle{ .x = @as(i32, @intFromFloat(t.position.x)), .y = @as(i32, @intFromFloat(t.position.y)), .width = @as(i32, @intCast(asset_info.width)), .height = @as(i32, @intCast(asset_info.height)) };
                                try ren.copy(asset, rect, t.crop);
                                try asset_manager.unloadFontTexture(t.message, t.font_name, t.font_size, t.color, false);
                            },
                            .fps => |f| {
                                _ = f;
                            },
                        }
                    },
                    .three_dimensional => |s| {
                        _ = s;
                    },
                }
            }
        } else {
            return error.InvalidRendererId;
        }
    }

    pub fn present(self: *Self, renderer_id: []const u8, asset_manager: *AssetManager) !void {
        const ren: sdl.Renderer = self.renderers.get(renderer_id);
        try ren.setColor(0, 0, 0, 255);
        try ren.clear();

        try self.consume_queue(renderer_id, asset_manager);
        ren.present();
    }

    pub fn presentAll(self: *Self, asset_manager: *AssetManager) !void {
        var iter = self.renderers.iterator();
        while (iter.next()) |r| {
            try r.value_ptr.setColor(.{ .r = 0, .g = 0, .b = 0, .a = 255 });
            try r.value_ptr.clear();
            try self.consume_queue(r.key_ptr.*, asset_manager);
            r.value_ptr.present();
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
