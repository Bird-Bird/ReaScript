--[[
 * ReaScript Name: Create new track (Match height).lua
 * Author: BirdBird
 * Licence: GPL v3
 * REAPER: 6.0
 * Extensions: None
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2020-01-05)
 	+ Initial Release
--]]

local defaultHeight = 30
function main()
    reaper.Main_OnCommand( 40297, 0 ) --unselect all tracks
    reaper.Main_OnCommand( 41110, 0 ) --select track under mouse
    local selectedTrackCount = reaper.CountSelectedTracks(0)
    if selectedTrackCount == 0 then
        reaper.Main_OnCommand(40001, 0) --insert new track
        local newTrack = reaper.GetSelectedTrack(0, 0)
        reaper.SetMediaTrackInfo_Value(newTrack, 'I_HEIGHTOVERRIDE', defaultHeight)
        return 
    end


    local mainTrack = reaper.GetSelectedTrack(0, 0)
    local trackHeight = reaper.GetMediaTrackInfo_Value(mainTrack, 'I_HEIGHTOVERRIDE')
    reaper.Main_OnCommand(40001, 0) --insert new track
    local newTrack = reaper.GetSelectedTrack(0, 0)
    reaper.SetMediaTrackInfo_Value(newTrack, 'I_HEIGHTOVERRIDE', trackHeight)
end

reaper.PreventUIRefresh(-1)

reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock('Insert new track', -1)

reaper.PreventUIRefresh(1)