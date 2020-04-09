--[[
 * ReaScript Name: Quick MIDI Preview.lua
 * Author: BirdBird
 * Licence: GPL v3
 * REAPER: 6.0
 * Extensions: None
 * Provides: Resources/BB_MIDI Bridge.jsfx
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2019-12-19)
     + Initial Release
 * v2.0 (2020-04-09)
     + Major upgrade to script behaviour.
     + Script no longer uses transport play.
     + Uses a MIDI bridge jsfx to preview notes instead.
--]]

function p(msg) reaper.ShowConsoleMsg('\n' .. tostring(msg)) end

local terminateScript = false
local initialized = false

local fxName = 'BB_MIDI Bridge.jsfx'
local gmemID = 'BB_MIDIPreview'

local track
local take
local activeMIDI

activeMIDI = reaper.MIDIEditor_GetActive()
if activeMIDI then
    take = reaper.MIDIEditor_GetTake(activeMIDI)
end
if take then
    track = reaper.GetMediaItemTake_Track(take)
end

if not activeMIDI or not take or not track then
    return
end

--=====FUNCTIONS=====--
function addJSFX() --insert MIDI Bridge and attach gmem
    local fxID = reaper.TrackFX_AddByName( track, fxName, false, 1 )
    if fxID < 0 then 
        reaper.ReaScriptError('Could not find BB_MIDI Bridge.jsfx, please install it from ReaPack.') 
        terminateScript = true
    else
        reaper.TrackFX_CopyToTrack( track, fxID, track, 0, true ) --reorder
        reaper.gmem_attach(gmemID)
    end
end

function handleReorder() --order MIDI Bridge to be the first fx on track
    local id = reaper.TrackFX_AddByName( track, fxName, false, 0 )
    if id == 0 then
        reaper.gmem_write(1, 1) --init jsfx
        initialized = true
    end
end

local index = 3
function pushMessage(msg)
    reaper.gmem_write(index, msg)
    reaper.gmem_write(2, index + 1)
    index = index + 1
end

--gmem[1] -------> init state
--gmem[2] -------> target index
function resetGMEM()
    reaper.gmem_write(1, 0)
    reaper.gmem_write(2, 3)
end

function packMIDIData(status, data1, data2)
    local val = status + (data1 << 8) + (data2 << 16)
    return val
end

function getNoteBuffer() --get a table of all the notes under edit cursor
    local editCursorPosition = reaper.GetCursorPosition()
    local editCursorPPQ = reaper.MIDI_GetPPQPosFromProjTime(take, editCursorPosition)
    
    local noteCount = reaper.MIDI_CountEvts(take)
    local buffer = {}
    for i = 0, noteCount-1 do
        local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote( take, i )
        if editCursorPPQ > startppqpos and editCursorPPQ < endppqpos then --Note is over edit cursor
            buffer[pitch] = {channel = chan, pitch = pitch, vel = vel}
        end
    end

    return buffer
end

--=====STATES=====--
function init()
    addJSFX()
    return false
end

local lastNoteBuffer = {}
function update()
    if not initialized then 
        handleReorder()
    else
        --main loop
        reaper.MIDIEditor_OnCommand(activeMIDI, 40443) --move edit cursor to mouse cursor
        local noteBuffer = getNoteBuffer()

        --handle note on Messages
        for note, noteData in pairs(noteBuffer) do
            if lastNoteBuffer[note] == nil then --new MIDI note, send note on message
                local channel = noteData.channel
                local noteOn = 0x90 + (channel & 0x0F)
                local pitch = noteData.pitch & 0xFF
                local vel = noteData.vel & 0xFF
                local gmemMessage = packMIDIData(noteOn, pitch, vel)
                pushMessage(gmemMessage)
            end
        end

        --handle note off messages
        for lastNote, noteData in pairs(lastNoteBuffer) do
            if noteBuffer[lastNote] == nil then --MIDI note out of range, send note off message
                local channel = noteData.channel
                local noteOn = 0x80 + (channel & 0x0F)
                local pitch = noteData.pitch & 0xFF
                local vel = noteData.vel & 0xFF
                local gmemMessage = packMIDIData(noteOn, pitch, vel)
                pushMessage(gmemMessage)
            end
        end 

        lastNoteBuffer = noteBuffer
    end
end

function exit()
    local allNotesOff = reaper.NamedCommandLookup('_S&M_CC123_SEL_TRACKS')
    reaper.SetTrackSelected(track, true)
    reaper.Main_OnCommand(allNotesOff, 0) --send all notes off to selected track

    local fxID = reaper.TrackFX_AddByName(track, fxName, false, 0 ) --delete MIDI bridge
    reaper.TrackFX_Delete( track, fxID )

    resetGMEM()
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
end

function atExit()
    reaper.JS_VKeys_Intercept(-1, -1)
end
--------------------------------------
awake()
main()

