--[[
 * ReaScript Name: BirdBird_Open MIDI Editor with custom settings (Scroll, Zoom, Snap).lua
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
local openMediaItemPropertiesForAudioItems = true --set to true if you want it to open media item properties for audio items
local defaultZoomLevel = 17 --default vertical zoom level, increase if you want more vertical zoom
local doHorizontalZoom = true --will zoom and center the item horizontally in the MIDI Editor

local moveEditCursorToItemStart = true --will move edit cursor to beginning of item if set to true

local useDefaultSnap = true --will use the snap setting below if set to true
local defaultGridSnap = 1/8

--=====UTILITY=====--
function p(msg) reaper.ShowConsoleMsg(tostring(msg)..'\n')end

function trackGotInitialized(GUID)
    local trackExists
    local retval, trackState = reaper.GetProjExtState( 0, 'BirdBird_MIDI', GUID)
    if retval == 0 or trackState == nil then
        trackExists = false
    elseif trackState == 'true' then
        trackExists = true
    end
    
    return trackExists
end

function itemGotInitialized(mediaItem)
    local retval, initialized = reaper.GetSetMediaItemInfo_String(mediaItem, 'P_EXT:midiZoom', 'initialized', false)
    if initialized ~= 'initialized' then
        return false
    else
        return true
    end
end

function initializeItem(mediaItem)
    local retval, initialized = reaper.GetSetMediaItemInfo_String(mediaItem, 'P_EXT:midiZoom', 'initialized', true)
end
--===============MAIN===============--
local zoomOutSteps = 70
function main()
    local selectedItemCount = reaper.CountSelectedMediaItems(0)
    if selectedItemCount == 0 then  --return if no items are selected
        return
    end
    
    local selectedItem = reaper.GetSelectedMediaItem(0, 0)
    local selectedItemTrack = reaper.GetMediaItem_Track(selectedItem)
    local activeTake = reaper.GetMediaItemTake(selectedItem, 0)

    if reaper.TakeIsMIDI(activeTake) == true then
        if moveEditCursorToItemStart == true then
            reaper.Main_OnCommand(41173, 0) --move cursor to start of item
        end
        
        --open item and initialize settings if needed
        reaper.Main_OnCommand(40153, 0) --open selected item in midi editor
        
        local active_MIDI_editor = reaper.MIDIEditor_GetActive();
        
        if doHorizontalZoom == true then
            reaper.MIDIEditor_OnCommand(active_MIDI_editor, 40468); --zoom one loop iteration
        end
        
        --zoom vertically 
        if itemGotInitialized(selectedItem) == false then --do default vertical zoom and mark track as initialized
            initializeItem(selectedItem)
            --reaper.MIDIEditor_OnCommand(active_MIDI_editor, 40466); --zoom to content   
            
            if useDefaultSnap == true then
                reaper.SetMIDIEditorGrid(0, defaultGridSnap) --default grid snap
            end
            
            --Zoom all the way out vertically
            for i = 1, zoomOutSteps do 
                reaper.MIDIEditor_OnCommand(active_MIDI_editor, 40112); --zoom out vertically"
            end
    
            --Zoom back in vertically
            for i = 1, defaultZoomLevel do 
                reaper.MIDIEditor_OnCommand(active_MIDI_editor, 40111); --zoom in vertically"
            end
        end
    elseif openMediaItemPropertiesForAudioItems == true then
        --open media item properties window for audio items
        reaper.Main_OnCommand(40009, 0)
    end
end
  
main()
