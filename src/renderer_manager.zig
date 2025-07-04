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
        size: Vec2,
        tint: sdl.Color,

        pub fn draw(self: *const @This(), renderer: sdl.Renderer, asset_manager: *AssetManager) !void {
            const asset = try asset_manager.loadTexture(renderer, self.name);
            defer asset_manager.unloadTexture(self.name, false) catch {};

            try asset.setColorMod(sdl.Color.rgba(self.tint.r, self.tint.g, self.tint.b, self.tint.a));

            var rect: ?sdl.Rectangle = undefined;
            if (self.size.x > -1 and self.size.y > -1) {
                rect = sdl.Rectangle{
                    .x = @as(i32, @intFromFloat(self.position.x)),
                    .y = @as(i32, @intFromFloat(self.position.y)),
                    .width = @as(i32, @intFromFloat(self.size.x)),
                    .height = @as(i32, @intFromFloat(self.size.y)),
                };
            } else {
                rect = null;
            }

            try renderer.copy(asset, rect, self.crop);
        }
    },
    text: struct {
        message: [:0]const u8,
        position: Vec2,
        crop: ?sdl.Rectangle,
        color: sdl.Color,
        font_size: i32,
        font_name: [:0]const u8,
        scale: ?f32,
        tint: sdl.Color,

        pub fn draw(self: *const @This(), renderer: sdl.Renderer, asset_manager: *AssetManager) !void {
            const asset = try asset_manager.loadFontTexture(renderer, self.message, self.font_name, self.font_size, self.color);
            defer asset_manager.unloadFontTexture(self.message, self.font_name, self.font_size, self.color, false) catch {};

            const asset_info = try asset.query();
            try asset.setColorMod(sdl.Color.rgba(self.tint.r, self.tint.g, self.tint.b, self.tint.a));

            var dest_rect: ?sdl.Rectangle = undefined;
            if (self.scale) |s| {
                if (s < 0) {
                    dest_rect = null;
                } else {
                    dest_rect = .{
                        .x = @as(i32, @intFromFloat(self.position.x)),
                        .y = @as(i32, @intFromFloat(self.position.y)),
                        .width = @as(i32, @intFromFloat(@as(f32, @floatFromInt(asset_info.width)) * s)),
                        .height = @as(i32, @intFromFloat(@as(f32, @floatFromInt(asset_info.height)) * s)),
                    };
                }
            } else {
                dest_rect = .{
                    .x = @as(i32, @intFromFloat(self.position.x)),
                    .y = @as(i32, @intFromFloat(self.position.y)),
                    .width = @as(i32, @intCast(asset_info.width)),
                    .height = @as(i32, @intCast(asset_info.height)),
                };
            }
            try renderer.copy(asset, dest_rect, null);
        }
    },
    fps: struct {
        position: Vec2,
        font_name: [:0]const u8,
        font_size: i32,
        color: sdl.Color,
    },
};

pub const Drawable3D = union(enum) {
    cube: struct { position: Vec3, rotation: Quat, scale: Vec3 },
};

pub const Drawable = union(enum) {
    two_dimensional: Drawable2D,
    three_dimensional: Drawable3D,
};

/// Manages the render queues and buffers for each renderer instance.
pub const RenderQueueData = struct {
    front_buffer: std.ArrayList(Drawable),
    back_buffer: std.ArrayList(Drawable),
    mutex: std.Thread.Mutex,
};

/// Manages all rendering operations, including queueing, buffering, and presentation.
pub const RendererManager = struct {
    const Self = @This();
    allocator: std.mem.Allocator,
    renderers: std.StringHashMap(sdl.Renderer),
    render_queues: std.StringHashMap(RenderQueueData),

    last_frame_time: u64,
    frame_count: u32,
    fps: u32,
    max_fps: u32,

    /// Initializes the RendererManager.
    pub fn init(allocator: std.mem.Allocator) !Self {
        return RendererManager{
            .allocator = allocator,
            .renderers = std.StringHashMap(sdl.Renderer).init(allocator),
            .render_queues = std.StringHashMap(RenderQueueData).init(allocator),
            .last_frame_time = sdl.getTicks64(),
            .frame_count = 0,
            .fps = 0,
            .max_fps = 120,
        };
    }

    /// Deinitializes the RendererManager and all its resources.
    pub fn deinit(self: *Self) void {
        var renderer_iter = self.renderers.valueIterator();
        while (renderer_iter.next()) |ren| {
            ren.destroy();
        }
        self.renderers.deinit();

        var queue_iter = self.render_queues.valueIterator();
        while (queue_iter.next()) |q| {
            q.front_buffer.deinit();
            q.back_buffer.deinit();
        }
        self.render_queues.deinit();
    }

    /// Creates a new SDL Renderer for a given window and sets up its render queues.
    pub fn createRenderer(self: *Self, window: sdl.Window, index: ?u31, flags: sdl.RendererFlags) ![]const u8 {
        const ren = try sdl.createRenderer(window, index, flags);
        const ren_id = try std.fmt.allocPrint(self.allocator, "{}", .{try window.getID()});
        defer self.allocator.free(ren_id);

        if (self.renderers.contains(ren_id)) {
            std.debug.print("\x1b[91mcreateRenderer error:\x1b[0m Window '{s}' is already attached to a renderer.\n", .{ren_id});
            return error.WindowOccupied;
        }

        const dupe_id = try self.allocator.dupe(u8, ren_id);
        const queue_data = RenderQueueData{
            .front_buffer = std.ArrayList(Drawable).init(self.allocator),
            .back_buffer = std.ArrayList(Drawable).init(self.allocator),
            .mutex = std.Thread.Mutex{},
        };

        try self.renderers.put(dupe_id, ren);
        try self.render_queues.put(dupe_id, queue_data);

        return dupe_id;
    }

    /// Retrieves a renderer by its ID.
    pub fn getRenderer(self: *Self, id: []const u8) !sdl.Renderer {
        return self.renderers.get(id) orelse error.InvalidRendererId;
    }

    /// Clears the front buffer of a specific renderer's queue.
    pub fn clear(self: *Self, renderer_id: []const u8) !void {
        if (self.render_queues.getPtr(renderer_id)) |ren_queue| {
            ren_queue.mutex.lock();
            defer ren_queue.mutex.unlock();
            ren_queue.front_buffer.clearRetainingCapacity();
        }
    }

    /// Adds a drawable item to the rendering queue for the current frame.
    pub fn queue(self: *Self, renderer_id: []const u8, drawable: Drawable) !void {
        if (self.render_queues.getPtr(renderer_id)) |ren_queue| {
            ren_queue.mutex.lock();
            defer ren_queue.mutex.unlock();
            try ren_queue.front_buffer.append(drawable);
        }
    }

    fn renderDrawables(self: *Self, ren: sdl.Renderer, asset_manager: *AssetManager, items: []const Drawable) !void {
        for (items) |item| {
            switch (item) {
                .two_dimensional => |s| switch (s) {
                    .circle => |c| try c.draw(self.allocator, ren),
                    .rect => |r| try r.draw(ren),
                    .texture => |t| try t.draw(ren, asset_manager),
                    .text => |t| try t.draw(ren, asset_manager),
                    .fps => |f| {
                        const fps_text = try std.fmt.allocPrintZ(self.allocator, "FPS: {d}", .{self.getFPS()});
                        defer self.allocator.free(fps_text);
                        const text_drawable = Drawable2D{
                            .text = .{
                                .message = fps_text,
                                .position = f.position,
                                .crop = null,
                                .color = f.color,
                                .font_size = f.font_size,
                                .font_name = f.font_name,
                                .scale = null,
                                .tint = f.color,
                            },
                        };
                        try text_drawable.text.draw(ren, asset_manager);
                    },
                },
                .three_dimensional => |s| {
                    _ = s;
                },
            }
        }
    }

    /// Returns the current frames per second.
    pub fn getFPS(self: *Self) u32 {
        return self.fps;
    }

    /// Sets the maximum target frames per second.
    pub fn setMaxFPS(self: *Self, max: u32) void {
        self.max_fps = max;
    }

    /// Presents the final rendered image for all windows, handling buffering and frame capping.
    pub fn presentAll(self: *Self, asset_manager: *AssetManager) !void {
        const frame_delay = if (self.max_fps > 0) 1000 / self.max_fps else 0;
        const frame_start_time = sdl.getTicks64();

        self.frame_count += 1;
        if (frame_start_time - self.last_frame_time >= 1000) {
            self.fps = self.frame_count;
            self.frame_count = 0;
            self.last_frame_time = frame_start_time;
        }

        var iter = self.renderers.iterator();
        while (iter.next()) |r| {
            const ren: sdl.Renderer = r.value_ptr.*;
            const ren_queue = self.render_queues.getPtr(r.key_ptr.*).?;

            ren_queue.mutex.lock();
            errdefer ren_queue.mutex.unlock();

            const has_new_items = ren_queue.front_buffer.items.len > 0;
            const items_to_draw = if (has_new_items) ren_queue.front_buffer.items else ren_queue.back_buffer.items;

            try ren.setColor(sdl.Color.rgba(0, 0, 0, 255));
            try ren.clear();
            try self.renderDrawables(ren, asset_manager, items_to_draw);

            if (has_new_items) {
                ren_queue.back_buffer.clearRetainingCapacity();
                try ren_queue.back_buffer.appendSlice(ren_queue.front_buffer.items);
                ren_queue.front_buffer.clearRetainingCapacity();
            }

            ren_queue.mutex.unlock();
            ren.present();
        }

        const frame_time = sdl.getTicks64() - frame_start_time;
        if (frame_delay > frame_time) {
            sdl.delay(@as(u32, @intCast(frame_delay - frame_time)));
        }
    }

    /// Sets the draw color for a specific renderer.
    pub fn setColorRGB(self: *Self, renderer_id: []const u8, r: u8, g: u8, b: u8) !void {
        const ren: sdl.Renderer = try self.getRenderer(renderer_id);
        try ren.setColorRGB(r, g, b);
    }

    /// Sets the draw color with alpha for a specific renderer.
    pub fn setColorRGBA(self: *Self, renderer_id: []const u8, r: u8, g: u8, b: u8, a: u8) !void {
        const ren: sdl.Renderer = try self.getRenderer(renderer_id);
        try ren.setColorRGBA(r, g, b, a);
    }
};
