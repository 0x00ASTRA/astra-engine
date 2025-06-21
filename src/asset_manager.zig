const std = @import("std");
const sdl = @import("sdl2");

pub const AssetType = union(enum) {
    pub const ImageAsset = struct { surface: sdl.Surface, num_users: usize };
    pub const TextureAsset = struct { texture: sdl.Texture, num_users: usize };

    image: ImageAsset,
    textture: TextureAsset,
};

pub const AssetManager = struct {
    const Self = @This();
    allocator: std.mem.Allocator,
    texture_pool: std.StringHashMap(AssetType.TextureAsset),
    image_pool: std.StringHashMap(AssetType.ImageAsset),
    mutex: std.Thread.Mutex,

    pub fn init(allocator: std.mem.Allocator) !Self {
        const t = std.StringHashMap(AssetType.TextureAsset).init(allocator);
        const i = std.StringHashMap(AssetType.ImageAsset).init(allocator);
        const asset_manager = Self{
            .allocator = allocator,
            .texture_pool = t,
            .image_pool = i,
            .mutex = std.Thread.Mutex{},
        };
        return asset_manager;
    }

    pub fn deinit(self: *Self) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        var texture_iter = self.texture_pool.iterator();
        while (texture_iter.next()) |iter| {
            self.allocator.free(iter.key_ptr.*);
            iter.value_ptr.texture.destroy();
        }
        self.texture_pool.deinit();

        var image_iter = self.image_pool.iterator();
        while (image_iter.next()) |iter| {
            self.allocator.free(iter.key_ptr.*);
            iter.value_ptr.surface.destroy();
        }
        self.image_pool.deinit();
    }

    pub fn loadImage(self: *Self, filename: [:0]const u8) !sdl.Surface {
        self.mutex.lock();
        defer self.mutex.unlock();
        if (self.image_pool.get(filename)) |i| {
            i.num_users += 1;
            return i.surface;
        }

        const img = try sdl.image.loadSurface(filename);
        try self.image_pool.put(self.allocator.dupeZ(u8, filename), .{ .surface = img, .num_users = 1 });
        return img;
    }

    pub fn unloadImage(self: *Self, filename: [:0]const u8) !void {
        self.mutex.lock();
        defer self.mutex.unlock();
        if (self.image_pool.get(filename)) |i| {
            i.num_users -= 1;
            if (i.num_users < 1) {
                i.surface.destroy();
                self.image_pool.remove(filename);
            }
        } else {
            return error.InvalidFileName;
        }
    }

    pub fn loadTexture(self: *Self, renderer: sdl.Renderer, filename: [:0]const u8) !sdl.Texture {
        self.mutex.lock();
        defer self.mutex.unlock();
        if (self.texture_pool.get(filename)) |t| {
            t.num_users += 1;
            return t.texture;
        }
        const texture = try sdl.image.loadTexture(renderer, filename);
        try self.texture_pool.put(self.allocator.dupeZ(u8, filename), .{ .texture = texture, .num_users = 1 });
        return texture;
    }

    pub fn unloadTexture(self: *Self, filename: [:0]const u8) !void {
        self.mutex.lock();
        defer self.mutex.unlock();
        if (self.texture_pool.get(filename)) |t| {
            t.num_users -= 1;
            if (t.num_users < 1) {
                t.texture.destroy();
                self.texture_pool.remove(filename);
            }
        } else {
            return error.InvalidTextureName;
        }
    }
};
