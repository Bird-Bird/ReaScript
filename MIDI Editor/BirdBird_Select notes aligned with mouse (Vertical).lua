--[[
 * ReaScript Name: BirdBird_Select notes aligned with mouse (Vertical).lua
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

    local window, segment, details = reaper.BR_GetMouseCursorContext()
    local mousePosition =  reaper.BR_GetMouseCursorContext_Position()
    local mousePPQ = reaper.MIDI_GetPPQPosFromProjTime(activeTake, mousePosition)

    local noteCount = reaper.FNG_CountMidiNotes(takeAlloc)
    for i = 0, noteCount-1 do
        local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote( activeTake, i )
        local note = reaper.FNG_GetMidiNote( takeAlloc, i )
        if mousePPQ > startppqpos and mousePPQ < endppqpos then
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