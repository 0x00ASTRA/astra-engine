const std = @import("std");

pub const Vec2 = struct {
    const Self = @This();
    x: f32,
    y: f32,

    pub fn add(v1: Self, v2: Self) Self {
        const vec: @Vector(2, f32) = .{ v1.x, v1.y };
        const other: @Vector(2, f32) = .{ v2.x, v2.y };
        const res: @Vector(2, f32) = vec + other;
        return Self{ .x = res[0], .y = res[1] };
    }

    pub fn addInPlace(self: *Self, vec: Vec2) *Self {
        const v1: @Vector(2, f32) = .{ self.x, self.y };
        const v2: @Vector(2, f32) = .{ vec.x, vec.y };
        const res: @Vector(2, f32) = v1 + v2;
        self.x = res[0];
        self.y = res[1];
        return self;
    }
};

pub const Vec3 = struct { x: f32, y: f32, z: f32 };
pub const Quat = struct { i: f32, j: f32, k: f32, w: f32 };

test "Vec2 addInPlace" {
    var v1: Vec2 = .{ .x = 20.5, .y = 20.0 };
    const v2: Vec2 = .{ .x = 20.5, .y = 10.5 };
    const res = v1.addInPlace(v2);
    try std.testing.expectEqual(res.*, Vec2{ .x = 41.0, .y = 30.5 });
}

test "Vec2 add" {
    const v1: Vec2 = .{ .x = 40.0, .y = 20.0 };
    const v2: Vec2 = .{ .x = 60.5, .y = 80.5 };
    const res: Vec2 = Vec2.add(v1, v2);
    try std.testing.expectEqual(res, Vec2{ .x = 100.5, .y = 100.5 });
}
