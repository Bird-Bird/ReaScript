--[[
 * ReaScript Name: BirdBird_Set time selection to active MIDI item and enable repeat.lua
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

function p(msg) reaper.ShowConsoleMsg(tostring(msg)..'\n')end

local midiEditor = reaper.MIDIEditor_GetActive()
if midiEditor == nil then
    return
end
local activeTake = reaper.MIDIEditor_GetTake(midiEditor)
local activeItem = reaper.GetMediaItemTake_Item(activeTake)
local activeItemPosition = reaper.GetMediaItemInfo_Value(activeItem, 'D_POSITION')
local activeItemLength = reaper.GetMediaItemInfo_Value(activeItem, 'D_LENGTH')
local activeItemEndPosition = activeItemPosition + activeItemLength

reaper.GetSet_LoopTimeRange(1, 1, activeItemPosition, activeItemEndPosition, 0) --make time selection
reaper.GetSetRepeat(1) --enable repeat