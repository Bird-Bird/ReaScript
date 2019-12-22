--[[
 * ReaScript Name: BirdBird_Adjust velocity for selected or closest notes (Mousewheel).lua
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

--=====Tweak these if you need to=====--
local noteRange = 3 --range of notes to search vertically
local horizontalRange = 3000 --range of notes to search horizontally, in PPQ
local velocitySensitivity = 12 --velocity step for each mouse roll

--=====UTILITY=====--
function p(msg) reaper.ShowConsoleMsg(tostring(msg)..'\n')end

function noteContainsMouse(mousePPQ, notePPQs, notePPQe)
    if mousePPQ >= notePPQs and mousePPQ <= notePPQe then
        return true
    else
        return false
    end
end
--=====MAIN=====--
function main()
    local window, segment, details = reaper.BR_GetMouseCursorContext()
    local mousePosition =  reaper.BR_GetMouseCursorContext_Position()

    local midiEditor = reaper.MIDIEditor_GetActive()
    local activeTake = reaper.MIDIEditor_GetTake(midiEditor)
    
    local dummy, notes, ccs, sysex = reaper.MIDI_CountEvts(activeTake)
    
    local mousePPQ = reaper.MIDI_GetPPQPosFromProjTime(activeTake, mousePosition)
    local retval, inlineEditor, noteRow, ccLane, ccLaneVal, ccLaneId = reaper.BR_GetMouseCursorContext_MIDI()

    local takeAlloc = reaper.FNG_AllocMidiTake(activeTake)
    local noteCount = reaper.FNG_CountMidiNotes(takeAlloc)

    local selectedNoteCount = 0
    for i = 0, noteCount-1 do
        local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote( activeTake, i )
        if selected then
            selectedNoteCount = selectedNoteCount + 1
        end
    end
    
    --tweak selected notes only if there is already a selection
    if selectedNoteCount > 0 then
        _,_,_,_,_,_,mouse_scroll  = reaper.get_action_context() 
        for i = 0, noteCount-1 do
            local note = reaper.FNG_GetMidiNote( takeAlloc, i )
            local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote( activeTake, i )
            
            if selected == true then
                if mouse_scroll > 0 then 
                    reaper.FNG_SetMidiNoteIntProperty(note, "VELOCITY", math.min(vel + velocitySensitivity,127)) --increase velocity
                else
                    reaper.FNG_SetMidiNoteIntProperty(note, "VELOCITY", math.max(vel - velocitySensitivity,1)) --decrease velocity
                end
            end
        end  
    else --find closest note and tweak it
        local closestNote
        local distanceHorizontal
        local distanceMinimum = 1000000000000
        local closestNoteRow = 1000000
        local hasWrappingNote = false
        local noteVelocity
        for i = 0, noteCount-1 do --for all notes
            local note = reaper.FNG_GetMidiNote( takeAlloc, i )
            local retval, selected, muted, startppqpos, endppqpos, chan, pitch, vel = reaper.MIDI_GetNote( activeTake, i )
            local noteRowDistance = math.abs(noteRow - pitch)
            if noteRowDistance <= noteRange then --if the note is in range
                --find the closest note here
                local distanceStart = math.abs(startppqpos - mousePPQ)
                local distanceEnd = math.abs(endppqpos - mousePPQ)

                local minDistance = math.min(distanceStart, distanceEnd)
                if minDistance > horizontalRange then
                    goto continue --prevent selection if the note is too far away horizontally
                end
                
                if noteContainsMouse(mousePPQ, startppqpos, endppqpos) == true then --if the note wraps the cursor
                    if noteRowDistance < closestNoteRow then
                        hasWrappingNote = true
                        closestNoteRow = noteRowDistance
                        closestNote = note
                        noteVelocity = vel
                    end
                elseif hasWrappingNote == false then
                    if minDistance < distanceMinimum then
                        distanceMinimum = minDistance
                        closestNote = note
                        noteVelocity = vel
                    end
                end
            end
            ::continue::
        end

        if closestNote ~= nil then
            _,_,_,_,_,_,mouse_scroll  = reaper.get_action_context() 
            if mouse_scroll > 0 then 
                reaper.FNG_SetMidiNoteIntProperty(closestNote, "VELOCITY", math.min(noteVelocity + velocitySensitivity,127)) --increase velocity
            else
                reaper.FNG_SetMidiNoteIntProperty(closestNote, "VELOCITY", math.max(noteVelocity - velocitySensitivity,1)) --decrease velocity
            end
        end
    end

    reaper.FNG_FreeMidiTake(takeAlloc)
end

reaper.defer(main)