--[[
 * ReaScript Name: Remove stuck note utility from all tracks.lua
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

local trackCount = reaper.CountTracks(0)
for i = 0, trackCount - 1 do
    local track = reaper.GetTrack(0, i)
    local fxID = reaper.TrackFX_AddByName( track, fxName, false, 0 )
    if fxID ~= -1 then
        reaper.TrackFX_Delete(track, fxID)        
    end
end

reaper.Undo_EndBlock('Remove stuck note utility from all tracks', -1)