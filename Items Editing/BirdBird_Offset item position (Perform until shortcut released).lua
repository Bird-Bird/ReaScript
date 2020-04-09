--[[
 * ReaScript Name: Offset item position (Perform until shortcut released)
 * Author: BirdBird
 * Licence: GPL v3
 * REAPER: 6.0
 * Extensions: None
 * Version: 1.1
--]]
 
--[[
 * Changelog:
 * v1.0 (2020-07-04)
     + Initial Release
--]]


function p(msg) reaper.ShowConsoleMsg(tostring(msg) .. '\n') end

local items = {}
local sensitivity = 0.00003

function init()
    local selectedItemCount = reaper.CountSelectedMediaItems(0)
    for i = 0, selectedItemCount-1 do 
        local item = reaper.GetSelectedMediaItem(0, i)
        table.insert( items, item )
    end
    return false
end

local lastX, lastY = reaper.GetMousePosition()
function update()
    local x,y = reaper.GetMousePosition()
    local dx, dy = lastX - x, lastY - y    
    
    for i = 1, #items do
        local item = items[i]
        local itemPos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
        reaper.SetMediaItemInfo_Value(item, 'D_POSITION', itemPos - (dx * sensitivity) )
    end

    lastX, lastY = x,y
end

function exit()

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
