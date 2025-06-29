-- The _init function is called once when the game starts
local win_id = Engine.get_main_window_id()
local x = 0
local y = 0
local forward = false

function _init()
    print("Lua: _init() called. Game is starting up!")
    Engine.log("\nLOG FUNCTION IS WORKING!\n")
    Engine.log(string.format("%s", win_id))

end


-- The _draw function is called every frame for rendering
function _draw()
    Render.draw_circle(win_id, x, y, 30, 255, 0, 0, 255, true)
end

function _update()
    if (forward) then
        x = x + 1
        y =  y + 1
        if (x > 800) then
            forward = false
        end
    else
        x = x - 1
        y = y - 1
        if (x < 0) then
            forward = true
        end
    end
end
