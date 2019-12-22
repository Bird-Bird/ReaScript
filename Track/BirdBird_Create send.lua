--[[
 * ReaScript Name: Create send.lua
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
local scriptTitle = 'Create sidechain'
local unselectAllChannelsID = 40297
local createNewTrackID = 40001

function createFaderSend(source, destination)
    --create send
    local sendID = reaper.CreateTrackSend(source, destination)
    --reaper.SetTrackSendInfo_Value( source, 0, sendID, 'I_DSTCHAN', 2)
end

function main()
    reaper.Undo_BeginBlock()
    
    --check for selected tracks
    local trackCount = reaper.CountSelectedTracks(0)
    if trackCount <= 1 then
        reaper.ShowMessageBox("No tracks selected. Select at least two tracks.", "Error", 0)
        return
    end

    local targetTrack = reaper.GetLastTouchedTrack()

    --gather all source trackss
    sourceTracks = {}
    for i = 0, trackCount-1 do
        local track = reaper.GetSelectedTrack(0, i)
        if track ~= targetTrack then
            table.insert(sourceTracks, track)
        end
    end

    --unselect all channels
    reaper.Main_OnCommand(unselectAllChannelsID, 0)
    
    --create sends
    for i = 1, #sourceTracks do
        local track = sourceTracks[i]
        createFaderSend(track, targetTrack)
    end
    
    reaper.Undo_EndBlock(scriptTitle, -1)
    reaper.PreventUIRefresh(1)
end
--=====MAIN=====--
reaper.PreventUIRefresh(-1)
main()
reaper.PreventUIRefresh(1)