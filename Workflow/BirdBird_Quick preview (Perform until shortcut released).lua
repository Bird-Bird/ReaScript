--[[
 * ReaScript Name: Quick preview (Perform until shortcut released).lua
 * Author: BirdBird
 * Licence: GPL v3
 * REAPER: 6.0
 * Extensions: None
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2020-01-10)
 	+ Initial Release
--]]

local followMouse = true
local soloTrackUnderMouse = false

local startCursorPosition
local midiEditor

local selection = {}
local track = nil
function init()
    startCursorPosition =  reaper.GetCursorPosition()


    local item, position = reaper.BR_ItemAtMouseCursor()
    local trackAtCursor, context, mousePosition = reaper.BR_TrackAtMouseCursor()
    if context ~= 2 then
        return true
    end

    local startPosition = position
    if item ~= nil and followMouse == false then
        local itemPosition = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
        startPosition = itemPosition
    end
    
    if trackAtCursor ~= nil and soloTrackUnderMouse == true then
        reaper.SetMediaTrackInfo_Value(trackAtCursor, 'I_SOLO', 1) -- solo track
        track = trackAtCursor
    end
        
    reaper.SetEditCurPos2(0, startPosition, false, true)
    reaper.Main_OnCommand(1007, -1) -- start playback
    
    return false
end

function update()
end

function exit()
    reaper.Main_OnCommand(1016, -1) -- stop playback
    if track ~= nil then
        reaper.SetMediaTrackInfo_Value(track, 'I_SOLO', 0) -- unsolo track
    end
    reaper.SetEditCurPos2(0, startCursorPosition, false, false)
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
    
    --update()
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
