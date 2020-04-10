--[[
 * ReaScript Name: Paste notes at mouse cursor (Grid relative).lua
 * Author: BirdBird
 * Licence: GPL v3
 * REAPER: 6.0
 * Extensions: None
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2020-04-10)
 	+ Initial Release
--]]

function p(msg) reaper.ShowConsoleMsg(tostring(msg)..'\n')end

function getClosestMIDIPPQFromTime(take, time)
    local midiGrid, midiSwing = reaper.MIDI_GetGrid(take)
    _, arrangeGrid, swingEnabled, swingAmount = reaper.GetSetProjectGrid(0, false) -- backup current grid settings
    reaper.GetSetProjectGrid(0, true, midiGrid/4, midiSwing ~= 0 and 1 or 0, midiSwing)

    local pos = reaper.BR_GetClosestGridDivision(time)
    local ppq = reaper.MIDI_GetPPQPosFromProjTime(take, pos)

    reaper.GetSetProjectGrid(0, true, arrangeGrid, swingEnabled, swingAmount)
    return ppq
end

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
    local retval, inlineEditor, noteRow, ccLane, ccLaneVal, ccLaneId = reaper.BR_GetMouseCursorContext_MIDI()

    local noteCount = reaper.MIDI_CountEvts(take)
    local buffer = {}
    local minPos = math.huge
    local minPitch = math.huge
    for i = 0, noteCount-1 do --collect selected notes into a buffer
        local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote( take, i )
        if selected then
            local note = {channel = chan, pitch = pitch, vel = vel, pos = startppqpos, endPos = endppqpos, chan = chan}
            table.insert(buffer, note)
            minPos = math.min(startppqpos, minPos)
            minPitch = math.min(pitch, minPitch)
            reaper.MIDI_SetNote( take, i, false, muted, startppqpos, endppqpos, chan, pitch, vel, true)
        end
    end

    local minTime = reaper.MIDI_GetProjTimeFromPPQPos(take, minPos)
    local minPPQGrid = getClosestMIDIPPQFromTime(take, minTime)
    local gridOffset = minPos - minPPQGrid

    local closestPPQ = getClosestMIDIPPQFromTime(take, mousePosition)
    local PPQOffset = closestPPQ - minPos
    local pitchOffset = noteRow - minPitch
    
    for i = 1, #buffer do
        local note = buffer[i]
        reaper.MIDI_InsertNote(take, true, false, note.pos + PPQOffset + gridOffset, note.endPos + PPQOffset + gridOffset, note.chan, note.pitch + pitchOffset, note.vel, true)
    end

    reaper.MIDI_Sort(take)
    reaper.SetProjectGrid( 0, arrangeGrid ) --restore arrange grid
end

reaper.PreventUIRefresh(1)
main()
reaper.PreventUIRefresh(0)
