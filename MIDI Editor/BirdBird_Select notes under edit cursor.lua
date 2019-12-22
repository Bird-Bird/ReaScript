--[[
 * ReaScript Name: Select notes under edit cursor.lua
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
--=====MAIN=====--
function main()
    local midiEditor = reaper.MIDIEditor_GetActive()
    if midiEditor == nil then
        return
    end

    local activeTake = reaper.MIDIEditor_GetTake(midiEditor)

    local takeAlloc = reaper.FNG_AllocMidiTake(activeTake)

    local editCursorPosition = reaper.GetCursorPosition()
    local editCursorPPQ = reaper.MIDI_GetPPQPosFromProjTime(activeTake, editCursorPosition)

    local noteCount = reaper.FNG_CountMidiNotes(takeAlloc)
    for i = 0, noteCount-1 do
        local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote( activeTake, i )
        local note = reaper.FNG_GetMidiNote( takeAlloc, i )
        if editCursorPPQ > startppqpos and editCursorPPQ < endppqpos then
            if selected == false then
                reaper.FNG_SetMidiNoteIntProperty(note, 'SELECTED', 1)
            end
        else
            if selected == true then
                reaper.FNG_SetMidiNoteIntProperty(note, 'SELECTED', 0)
            end
        end
    end

    reaper.FNG_FreeMidiTake(takeAlloc)
end
--==========--
main()