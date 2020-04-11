--[[
 * ReaScript Name: Nudge notes (Perform until shortcut released).lua
 * Author: BirdBird
 * Licence: GPL v3
 * REAPER: 6.0
 * Extensions: None
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2020-04-11)
     + Initial Release
--]]

function p(msg) reaper.ShowConsoleMsg('\n' .. tostring(msg)) end

local terminateScript = false
local sensitivity = 1

local track
local take
local activeMIDI

activeMIDI = reaper.MIDIEditor_GetActive()
if activeMIDI then
    take = reaper.MIDIEditor_GetTake(activeMIDI)
end

if not activeMIDI or not take then
    return
end

--=====STATES=====--
local notes = {}
function init()
    local window, segment, details = reaper.BR_GetMouseCursorContext()
    local mousePosition =  reaper.BR_GetMouseCursorContext_Position()
    local mousePPQ = reaper.MIDI_GetPPQPosFromProjTime(take, mousePosition)

    local noteCount = reaper.MIDI_CountEvts(take)
    for i = 0, noteCount-1 do
        local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote( take, i )
        if selected then          
            local note = { idx = i,channel = chan, pitch = pitch, vel = vel, pos = startppqpos, endPos = endppqpos, chan = chan, muted = muted}
            table.insert(notes, note)
        end
    end

    reaper.Undo_BeginBlock()
end

local lastX, lastY = reaper.GetMousePosition()
function update()
    local x,y = reaper.GetMousePosition()
    local dx = x - lastX
    local offset = dx * sensitivity
    for i = 1, #notes do
        local note = notes[i]
        note.pos = note.pos + offset
        note.endPos = note.endPos + offset --* (dx > 0 and 0 or 1) --+ offset, preserve offset for end, makes more sense in a lot more cases
        reaper.MIDI_SetNote( take, note.idx, true, note.muted, note.pos, note.endPos, note.chan, note.pitch, note.vel, true)
              
    end

    lastX, lastY = x,y
end

function exit()
    atExit()
    reaper.MIDI_Sort(take)
    reaper.Undo_EndBlock('Nudge Notes', 1)
end

--=====EXECUTION=====--
--[[
Thanks to Alkamist as i am mostly using his implementation of handling keyboard input from his Zoom Tool down below.
It is a brilliant script, check it out here! 
https://forum.cockos.com/showthread.php?t=223411
--]]
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
    xpcall(
        function()
            if scriptShouldStop() or terminateScript then 
                exit()
                return 0 
            else
                update()
                reaper.defer(main)
            end
        end
    , crash)
end

function crash()
    p('-----------------------------------------------------------------')
    local byLine = "([^\r\n]*)\r?\n?"
    local trimPath = "[\\/]([^\\/]-:%d+:.+)$"
    local err = errObject and string.match(errObject, trimPath) or "Couldn't get error message."
    
    local trace = debug.traceback()
    local stack = {}
    for line in string.gmatch(trace, byLine) do
        local str = string.match(line, trimPath) or line
        stack[#stack + 1] = str
    end
    
    local name = ({reaper.get_action_context()})[2]:match("([^/\\_]+)$")
        reaper.ShowConsoleMsg(
            "Error: " ..
                err ..
                "\n\n" ..
                    "Stack traceback:\n\t" ..
                        table.concat(stack, "\n\t", 2) ..
                            "\n\n" ..
                            "Reaper:       \t" .. reaper.GetAppVersion() .. "\n" .. "Platform:     \t" .. reaper.GetOS()
        )

    exit()
    atExit()
end

function atExit()
    reaper.JS_VKeys_Intercept(-1, -1)
end
--------------------------------------
awake()
main()

