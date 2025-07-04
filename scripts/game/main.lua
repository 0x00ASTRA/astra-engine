-- The _init function is called once when the game starts
local win_id = Engine.get_main_window_id()

local cx = 400
local cy = 400

local rx = 10
local ry = 10

function _init()
    print("Lua: _init() called. Game is starting up!")
    Engine.log("\nLOG FUNCTION IS WORKING!\n")
    Engine.log(string.format("%s", win_id))
    local w,h = Engine.get_window_dimensions(win_id)

    Engine.log(string.format("%d,%d", w,h))
end


-- The _draw function is called every frame for rendering
function _draw()
    -- Render.draw_circle(win_id, cx, cy, 30, 255, 0, 0, 255, true)
    -- Render.draw_circle(win_id, cx, cy, 30, 0, 255, 0, 255, false)
    --
    -- Render.draw_rect(win_id, rx, ry, 100, 100, 0, 255, 0, 255, true)
    -- Render.draw_rect(win_id, rx, ry, 100, 100, 255, 0, 0, 255, false)
    Render.draw_texture(win_id, cx, cy, 200,200, "assets/textures/bird.png", 255,255,255,255)
    Render.draw_text(win_id, rx, ry, 3, "./assets/fonts/JetBrainsMono/JetBrainsMonoNerdFont-Regular.ttf", 24, 255, 255, 255, 255, 255,100,100,255, "Hello World");
end

local forward = true

function _update()
    if (forward) then 
        cy = cy + 1
        if (cy > 600) then
            forward = false
        end
    else 
        cy = cy - 1
        if (cy < 200) then
            forward = true
        end
    end
    Engine.sleep(20)
end
