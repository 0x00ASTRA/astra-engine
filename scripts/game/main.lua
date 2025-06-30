-- The _init function is called once when the game starts
local win_id = Engine.get_main_window_id()

local cx = 200
local cy = 200

local rx = 600
local ry = 600

function _init()
    print("Lua: _init() called. Game is starting up!")
    Engine.log("\nLOG FUNCTION IS WORKING!\n")
    Engine.log(string.format("%s", win_id))
    local w,h = Engine.get_window_dimensions(win_id)

    Engine.log(string.format("%d,%d", w,h))
end


-- The _draw function is called every frame for rendering
function _draw()
    Render.draw_circle(win_id, cx, cy, 30, 255, 0, 0, 255, true)
    Render.draw_circle(win_id, cx, cy, 30, 0, 255, 0, 255, false)

    Render.draw_rect(win_id, rx, ry, 100, 100, 0, 255, 0, 255, true)
    Render.draw_rect(win_id, rx, ry, 100, 100, 255, 0, 0, 255, false)
end

function _update()
end
