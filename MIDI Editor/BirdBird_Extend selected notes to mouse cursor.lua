--[[
 * ReaScript Name: Extend selected notes to mouse cursor.lua
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

local midiEditor = reaper.MIDIEditor_GetActive()
if not midiEditor then
    return 
end
local take = reaper.MIDIEditor_GetTake(midiEditor)
if not take then
    return
end

function main()
    local window, segment, details = reaper.BR_GetMouseCursorContext()
    local mousePosition =  reaper.BR_GetMouseCursorContext_Position()
    local mousePPQ = reaper.MIDI_GetPPQPosFromProjTime(take, mousePosition)

    local noteCount = reaper.MIDI_CountEvts(take)
    for i = 0, noteCount-1 do
        local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote( take, i )
        if selected then
            local note = {channel = chan, pitch = pitch, vel = vel, pos = startppqpos, endPos = endppqpos, chan = chan}
            reaper.MIDI_SetNote( take, i, true, muted, startppqpos, mousePPQ, chan, pitch, vel, true)
        end
    end
end

main()