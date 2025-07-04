const std = @import("std");
const sdl = @import("sdl2");

// TODO: Add timeout based garbage collection for offloading textures.
// (once num users = 0) spawn thread that will check last time used, if
// time > max_time then offload the asset

pub const AssetType = union(enum) {
    pub const ImageAsset = struct { surface: sdl.Surface, num_users: usize, last_time_used: i64 };
    pub const TextureAsset = struct { texture: sdl.Texture, num_users: usize, last_time_used: i64 };
    pub const FontAsset = struct { font: sdl.ttf.Font, num_users: usize, last_time_used: i64 };

    image: ImageAsset,
    texture: TextureAsset,
    font: FontAsset,
};

pub const AssetManager = struct {
    const Self = @This();
    var _GC_TIME: i64 = 30 * std.time.us_per_s;
    allocator: std.mem.Allocator,
    texture_pool: std.StringHashMap(AssetType.TextureAsset),
    image_pool: std.StringHashMap(AssetType.ImageAsset),
    font_pool: std.StringHashMap(AssetType.FontAsset),
    texture_mutex: std.Thread.Mutex,
    image_mutex: std.Thread.Mutex,
    font_mutex: std.Thread.Mutex,
    gc_time: i64,

    pub fn init(allocator: std.mem.Allocator) !Self {
        const t = std.StringHashMap(AssetType.TextureAsset).init(allocator);
        const i = std.StringHashMap(AssetType.ImageAsset).init(allocator);
        const f = std.StringHashMap(AssetType.FontAsset).init(allocator);
        try sdl.ttf.init();
        const asset_manager = Self{
            .allocator = allocator,
            .texture_pool = t,
            .image_pool = i,
            .font_pool = f,
            .texture_mutex = std.Thread.Mutex{},
            .image_mutex = std.Thread.Mutex{},
            .font_mutex = std.Thread.Mutex{},
            .gc_time = Self._GC_TIME,
        };
        return asset_manager;
    }

    pub fn setGCTime(self: *Self, new_time: i64) void {
        self.gc_time = new_time;
    }

    pub fn deinit(self: *Self) void {
        self.font_mutex.lock();
        defer self.font_mutex.unlock();
        self.image_mutex.lock();
        defer self.image_mutex.unlock();
        self.texture_mutex.lock();
        defer self.texture_mutex.unlock();
        var texture_iter = self.texture_pool.iterator();
        while (texture_iter.next()) |iter| {
            std.debug.print("\x1b[96mAssetManager.deinit]\x1b[0m Unloading texture with id '{s}'...", .{iter.key_ptr.*});
            self.allocator.free(iter.key_ptr.*);
            iter.value_ptr.texture.destroy();
            std.debug.print("\x1b[92mDone\x1b[0m\n", .{});
        }
        self.texture_pool.deinit();

        var image_iter = self.image_pool.iterator();
        while (image_iter.next()) |iter| {
            std.debug.print("\x1b[96mAssetManager.deinit]\x1b[0m Unloading image with id '{s}'...", .{iter.key_ptr.*});
            self.allocator.free(iter.key_ptr.*);
            iter.value_ptr.surface.destroy();
            std.debug.print("\x1b[92mDone\x1b[0m\n", .{});
        }
        self.image_pool.deinit();

        var font_iter = self.font_pool.iterator();
        while (font_iter.next()) |iter| {
            std.debug.print("\x1b[96mAssetManager.deinit]\x1b[0m Unloading font with id '{s}'...", .{iter.key_ptr.*});
            self.allocator.free(iter.key_ptr.*);
            iter.value_ptr.font.close();
            std.debug.print("\x1b[92mDone\x1b[0m\n", .{});
        }
    }

    pub fn loadImage(self: *Self, filename: [:0]const u8) !sdl.Surface {
        self.image_mutex.lock();
        defer self.image_mutex.unlock();
        if (self.image_pool.get(filename)) |i| {
            i.num_users += 1;
            return i.surface;
        }

        const img = try sdl.image.loadSurface(filename);
        try self.image_pool.put(self.allocator.dupeZ(u8, filename), .{ .surface = img, .num_users = 1 });
        return img;
    }

    pub fn unloadImage(self: *Self, filename: [:0]const u8) !void {
        self.image_mutex.lock();
        defer self.image_mutex.unlock();
        if (self.image_pool.get(filename)) |i| {
            if (i.num_users > 0) {
                i.num_users -= 1;
            }
            if (i.num_users < 1) {
                i.surface.destroy();
                self.image_pool.remove(filename);
            }
        } else {
            return error.InvalidFileName;
        }
    }

    pub fn loadTexture(self: *Self, renderer: sdl.Renderer, filename: [:0]const u8) !sdl.Texture {
        self.texture_mutex.lock();
        defer self.texture_mutex.unlock();
        if (self.texture_pool.getPtr(filename)) |t| {
            t.num_users += 1;
            t.last_time_used = std.time.microTimestamp();
            return t.texture;
        }
        const texture = try sdl.image.loadTexture(renderer, filename);
        try self.texture_pool.put(try self.allocator.dupeZ(u8, filename), .{ .texture = texture, .num_users = 1, .last_time_used = std.time.microTimestamp() });
        std.debug.print("\x1b[96mCreated new texture\x1b[0m: '{s}'\n", .{filename});
        return texture;
    }

    pub fn unloadTexture(self: *Self, filename: [:0]const u8, force: bool) !void {
        self.texture_mutex.lock();
        defer self.texture_mutex.unlock();
        if (self.texture_pool.getPtr(filename)) |t| {
            if (t.num_users > 0) {
                t.num_users -= 1;
            }
            const cur_time: i64 = std.time.microTimestamp();
            if (t.num_users < 1 and cur_time - t.last_time_used > self.gc_time or force) {
                _ = self.texture_pool.remove(filename);
                t.texture.destroy();
                std.debug.print("\x1b[96mAssetManager.unloadTexture]\x1b[0m Unloaded texture with id '{s}'\n", .{filename});
            }
        } else {
            return error.InvalidTextureName;
        }
    }

    pub fn loadFont(self: *Self, filename: [:0]const u8, size: i32) !sdl.ttf.Font {
        self.font_mutex.lock();
        defer self.font_mutex.unlock();
        const font_name: [:0]const u8 = try std.fmt.allocPrintZ(self.allocator, "{s}_{d}", .{ filename, size });
        defer self.allocator.free(font_name);
        if (self.font_pool.getPtr(font_name)) |f| {
            f.num_users += 1;
            return f.font;
        }
        const font = try sdl.ttf.openFont(filename, size);
        const f_name: []const u8 = try std.fmt.allocPrint(self.allocator, "{s}_{d}", .{ filename, size });
        defer self.allocator.free(f_name);
        std.debug.print("\x1b[96mAssetManager.loadFont]\x1b[0m Loaded font with id '{s}'\n", .{f_name});

        const font_name_nonfree = try self.allocator.dupeZ(u8, @alignCast(f_name));
        try self.font_pool.put(font_name_nonfree, .{ .font = font, .num_users = 1, .last_time_used = std.time.microTimestamp() });
        return font;
    }

    pub fn unloadFont(self: *Self, filename: [:0]const u8, size: i32) !void {
        self.font_mutex.lock();
        defer self.font_mutex.unlock();
        const font_name: [:0]const u8 = try std.fmt.allocPrintZ(self.allocator, "{s}_{d}", .{ filename, size });
        if (self.font_pool.get(font_name)) |f| {
            f.num_users -= 1;
            if (f.num_users < 1 and (std.time.microTimestamp() - f.last_time_used) > self.gc_time) {
                f.font.close();
                const k_ptr = self.font_pool.getKeyPtr(font_name).?;
                self.font_pool.remove(font_name);
                self.allocator.destroy(k_ptr);
            }
        } else {
            return error.InvalidFont;
        }
    }

    pub fn loadFontTexture(self: *Self, renderer: sdl.Renderer, message: [:0]const u8, font_filename: [:0]const u8, font_size: i32, font_color: sdl.Color) !sdl.Texture {
        self.texture_mutex.lock();
        defer self.texture_mutex.unlock();
        const msg_str: [:0]const u8 = try std.fmt.allocPrintZ(self.allocator, "{s}_{s}_{d}_{}", .{ message, font_filename, font_size, font_color });
        defer self.allocator.free(msg_str);
        var hasher = std.hash.XxHash64.init(0);
        hasher.update(msg_str);
        const digest: u64 = hasher.final();
        const ft_name: [16]u8 = std.fmt.hex(digest);
        const name_z = try self.allocator.dupeZ(u8, &ft_name);
        defer self.allocator.free(name_z);
        if (self.texture_pool.get(name_z)) |t| {
            return t.texture;
        }

        const font = try self.loadFont(font_filename, font_size);
        const surface = try font.renderTextSolid(message, font_color); // TODO: change to enum switch
        const texture = try sdl.createTextureFromSurface(renderer, surface);
        const name_z_non_free = try self.allocator.dupeZ(u8, @alignCast(&ft_name));
        try self.texture_pool.put(name_z_non_free, .{ .texture = texture, .num_users = 1, .last_time_used = std.time.microTimestamp() });
        std.debug.print("\x1b[94m[LoadFontTexture]\x1b[0m  created texture with name '{s}'\n", .{&ft_name});
        return texture;
    }
    pub fn unloadFontTexture(self: *Self, message: [:0]const u8, font_filename: [:0]const u8, font_size: i32, font_color: sdl.Color, force: bool) !void {
        // self.mutex.lock();
        // defer self.mutex.unlock();
        const msg_str: [:0]const u8 = try std.fmt.allocPrintZ(self.allocator, "{s}_{s}_{d}_{}", .{ message, font_filename, font_size, font_color });
        defer self.allocator.free(msg_str);
        var hasher = std.hash.XxHash64.init(0);
        hasher.update(msg_str);
        const digest: u64 = hasher.final();
        const ft_name: [16]u8 = std.fmt.hex(digest);
        const name_z = try self.allocator.dupeZ(u8, &ft_name);
        defer self.allocator.free(name_z);
        try self.unloadTexture(name_z, force);
    }
};
