--[[
 * ReaScript Name: Delete under mouse
 * Author: BirdBird
 * Licence: GPL v3
 * REAPER: 6.0
 * Extensions: None
 * Version: 1.2
--]]
 
--[[
 * Changelog:
 * v1.0 (2020-01-10)
     + Initial Release
 * v1.1 (2020-02-02)
     + Improve deletion
--]]

local steps = 50 --increasing this may catch more items, at the cost of performance
function init()
    reaper.Undo_BeginBlock()
end

function p(msg) reaper.ShowConsoleMsg(tostring(msg) .. '\n') end

lastX, lastY = reaper.GetMousePosition()
function update()
    local x,y = reaper.GetMousePosition()
    for i = 1, steps do
        local t = (1/steps) * i
        
        local ix = math.floor(lerp(lastX ,x, t))
        local iy = math.floor(lerp(lastY ,y, t))

        local item ,take = reaper.GetItemFromPoint(ix, iy, false)
        if item ~= nil then
            reaper.DeleteTrackMediaItem(reaper.GetMediaItemTrack(item), item)
            reaper.UpdateArrange()
        end
    end
    lastX = x
    lastY = y
end

function lerp(a, b, c)
	return a + (b - a) * c
end

function exit()
    reaper.Undo_EndBlock('Delete under mouse', -1)
end

local terminateScript = false
local VKLow, VKHi = 8, 0xFE
local VKState0 = string.rep("\0", VKHi - VKLow + 1)
local startTime = 0

function awake()
    keyState = reaper.JS_VKeys_GetState(startTime - 0.5):sub(VKLow, VKHi)
    startTime = reaper.time_precise()
    thisCycleTime = startTime

    reaper.atexit(atExit)
    reaper.JS_VKeys_Intercept(-1, 1)

    keyState = reaper.JS_VKeys_GetState(-2):sub(VKLow, VKHi)

    local terminate = init()
    if terminate == true then
        return true
    else
        return false
    end
end

function scriptShouldStop()
    local prevCycleTime = thisCycleTime or startTime
    thisCycleTime = reaper.time_precise()

    local prevKeyState = keyState
    keyState = reaper.JS_VKeys_GetState(startTime - 0.5):sub(VKLow, VKHi)

    -- All keys are released.
    if keyState ~= prevKeyState and keyState == VKState0 then
        return true
    end

    -- Any keys were pressed.
    local keyDown = reaper.JS_VKeys_GetDown(prevCycleTime):sub(VKLow, VKHi)
    if keyDown ~= prevKeyState and keyDown ~= VKState0 then
        local p = 0
        ::checkNextKeyDown:: do
            p = keyDown:find("\1", p + 1)
            if p then
                if prevKeyState:byte(p) == 0 then
                    return true
                else
                    goto checkNextKeyDown
                end
            end
        end
    end

    return false
end

function main()
    if scriptShouldStop() or terminateScript then 
        exit()
        return 0 
    end
    
    update()
    reaper.defer(main)
end

function atExit()
    reaper.JS_VKeys_Intercept(-1, -1)
end
--------------------------------------
local terminate = awake()
if terminate == false then    
    main()
end
