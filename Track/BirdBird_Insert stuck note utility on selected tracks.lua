--[[
 * ReaScript Name: Insert stuck note utility on selected tracks.lua
 * Author: BirdBird
 * Licence: GPL v3
 * REAPER: 6.0
 * Extensions: None
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2020-11-26)
     + Initial Release
--]]

local fxName = 'BB_Stuck Note Utility.jsfx'
reaper.Undo_BeginBlock()

local trackCount = reaper.CountSelectedTracks(0)
for i = 0, trackCount - 1 do
    local track = reaper.GetSelectedTrack(0, i)
    local fxID = reaper.TrackFX_AddByName( track, fxName, false, 1 )
    if fxID < 0 then 
        reaper.ReaScriptError('Could not find ' .. fxName .. ', please install it from ReaPack.') 
        return
    else
        reaper.TrackFX_CopyToTrack( track, fxID, track, 0, true ) --reorder
    end
end

reaper.Undo_EndBlock('Insert stuck note utility selected tracks', -1)