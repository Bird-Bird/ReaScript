--[[
 * ReaScript Name: BirdBird_Quick MIDI Preview.lua
 * Author: BirdBird
 * Licence: GPL v3
 * REAPER: 6.0
 * Extensions: None
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2019-12-19)
 	+ Initial Release
--]]

local startCursorPosition
local midiEditor

function init()
    midiEditor = reaper.MIDIEditor_GetActive()
    if midiEditor == nil then
        return true
    end
    
    startCursorPosition =  reaper.GetCursorPosition()
    reaper.MIDIEditor_OnCommand(midiEditor,40443) --move edit cursor to mouse cursor
    reaper.MIDIEditor_OnCommand(midiEditor,1140) --start playback

    return false
end

function update()
end

function exit()
    reaper.MIDIEditor_OnCommand(midiEditor,1142) --stop playback
    reaper.SetEditCurPos2(0, startCursorPosition, false, false)
end

--[[
Thanks to Alkamist as i am directly using his implementation of handling keyboard input from his Zoom Tool down below.
It is a brilliant script, check it out here! 
https://forum.cockos.com/showthread.php?t=223411
]]
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

    init()
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
awake()
main()

