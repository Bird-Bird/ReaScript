--[[
 * ReaScript Name: Smart duplicate notes.lua
 * Author: BirdBird
 * Licence: GPL v3
 * REAPER: 6.0
 * Extensions: None
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2020-04-10)
 	+ Lost half my braincells trying to get swing to work, then gave up
--]]

function p(msg) reaper.ShowConsoleMsg(tostring(msg)..'\n')end

local midiEditor = reaper.MIDIEditor_GetActive()
if not midiEditor then
    return 
end
local take = reaper.MIDIEditor_GetTake(midiEditor)
if not take then
    return
end

function getNextGridDivision(time)
    local startCursorPos = reaper.GetCursorPosition()
    reaper.SetEditCurPos2(0, getPreviousGridDivision(time), false, false)
    reaper.Main_OnCommand(40647, 0) --move edit cursor right a grid division
    
    local cursorPos = reaper.GetCursorPosition()
    if cursorPos == time then
        reaper.Main_OnCommand(40647, 0) --move edit cursor right a grid division
        cursorPos = reaper.GetCursorPosition()
    end

    reaper.SetEditCurPos2( 0, startCursorPos, false, false )
    return cursorPos
end

function getPreviousGridDivision(time)
    local startCursorPos = reaper.GetCursorPosition()
    reaper.SetEditCurPos2(0, time, false, false)
    reaper.Main_OnCommand(40646, 0) --move edit cursor left a grid division
    local cursorPos = reaper.GetCursorPosition()

    reaper.SetEditCurPos2( 0, startCursorPos, false, false )
    return cursorPos
end

function getClosestGridDivision(time)
    local midiGrid, midiSwing = reaper.MIDI_GetGrid(take)
    local _, arrangeGrid, swingEnabled, swingAmount = reaper.GetSetProjectGrid(0, false) -- backup current grid settings
    reaper.GetSetProjectGrid(0, true, midiGrid/4, midiSwing ~= 0 and 1 or 0, midiSwing)

    local next = getNextGridDivision(time)
    local prev = getPreviousGridDivision(time)
    local source = getNextGridDivision(prev)

    reaper.GetSetProjectGrid(0, true, arrangeGrid, swingEnabled, swingAmount)
    
    local fpt = 0.001
    if math.abs(source - time) < fpt then
        return source
    else
        return math.abs(prev - time) < math.abs(next - time) and prev or next
    end
end

function getClosestMIDIPPQFromTime(take, time)
    local midiGrid, midiSwing = reaper.MIDI_GetGrid(take)
    local _, arrangeGrid, swingEnabled, swingAmount = reaper.GetSetProjectGrid(0, false) -- backup current grid settings
    reaper.GetSetProjectGrid(0, true, midiGrid/4, midiSwing ~= 0 and 1 or 0, midiSwing)

    local pos = getClosestGridDivision(time)
    local ppq = reaper.MIDI_GetPPQPosFromProjTime(take, pos)

    reaper.GetSetProjectGrid(0, true, arrangeGrid, swingEnabled, swingAmount)
    return ppq
end

function getPreviousPPQFromTime(take, time)
    local midiGrid, midiSwing = reaper.MIDI_GetGrid(take)
    local _, arrangeGrid, swingEnabled, swingAmount = reaper.GetSetProjectGrid(0, false) -- backup current grid settings
    reaper.GetSetProjectGrid(0, true, midiGrid/4, midiSwing ~= 0 and 1 or 0, midiSwing)

    local pos =  getPreviousGridDivision(time)
    local ppq = reaper.MIDI_GetPPQPosFromProjTime(take, pos)

    reaper.GetSetProjectGrid(0, true, arrangeGrid, swingEnabled, swingAmount)
    return ppq
end

function getNextPPQFromTime(take, time)
    local midiGrid, midiSwing = reaper.MIDI_GetGrid(take)
    local _, arrangeGrid, swingEnabled, swingAmount = reaper.GetSetProjectGrid(0, false) -- backup current grid settings
    reaper.GetSetProjectGrid(0, true, midiGrid/4, midiSwing ~= 0 and 1 or 0, midiSwing)

    local pos =  getNextGridDivision(time)
    local ppq = reaper.MIDI_GetPPQPosFromProjTime(take, pos)

    reaper.GetSetProjectGrid(0, true, arrangeGrid, swingEnabled, swingAmount)
    return ppq
end

function main()
    local window, segment, details = reaper.BR_GetMouseCursorContext()
    local mousePosition =  reaper.BR_GetMouseCursorContext_Position()
    
    local mousePPQ = reaper.MIDI_GetPPQPosFromProjTime(take, mousePosition)
    local retval, inlineEditor, noteRow, ccLane, ccLaneVal, ccLaneId = reaper.BR_GetMouseCursorContext_MIDI()

    local noteCount = reaper.MIDI_CountEvts(take)
    local buffer = {}
    local minPos = math.huge
    local maxPos = 0
    local minPitch = math.huge
    for i = 0, noteCount-1 do --collect selected notes into a buffer
        local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote( take, i )
        if selected then
            local note = {channel = chan, pitch = pitch, vel = vel, pos = startppqpos, endPos = endppqpos, chan = chan}
            table.insert(buffer, note)
            minPos = math.min(startppqpos, minPos)
            maxPos = math.max(endppqpos, maxPos)
            
            minPitch = math.min(pitch, minPitch)
            reaper.MIDI_SetNote( take, i, false, muted, startppqpos, endppqpos, chan, pitch, vel, true)
        end
    end

    --grid stuff
    local midiGrid, midiSwing = reaper.MIDI_GetGrid(take)
    local _, arrangeGrid, swingEnabled, swingAmount = reaper.GetSetProjectGrid(0, false) -- backup current grid settings
    reaper.GetSetProjectGrid(0, true, midiGrid/4, midiSwing ~= 0 and 1 or 0, midiSwing)
    
    local minTime = reaper.MIDI_GetProjTimeFromPPQPos(take, minPos)
    local maxTime = reaper.MIDI_GetProjTimeFromPPQPos(take, maxPos)

    local startGrid = getPreviousPPQFromTime(take, minTime)
    local closestStart = getClosestMIDIPPQFromTime(take, minTime)
    if math.abs(closestStart - minPos) < 1 then
        startGrid = closestStart
    end
    
    local endGrid = getNextPPQFromTime(take, maxTime)
    local closestEnd = getClosestMIDIPPQFromTime(take, maxTime)
    if math.abs(closestEnd - maxPos) < 1 then
        endGrid = closestEnd
    end

    local offset = endGrid - startGrid

    reaper.GetSetProjectGrid(0, true, arrangeGrid, swingEnabled, swingAmount)--restore grid stuff
    
    for i = 1, #buffer do
        local note = buffer[i]
        reaper.MIDI_InsertNote(take, true, false, note.pos + offset, note.endPos + offset, note.chan, note.pitch, note.vel, true)
    end

    reaper.MIDIEditor_OnCommand(midiEditor, 40659)
    reaper.MIDI_Sort(take)
end

reaper.PreventUIRefresh(1)
main()
reaper.PreventUIRefresh(-1)