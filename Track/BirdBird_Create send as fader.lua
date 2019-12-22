--[[
 * ReaScript Name: BirdBird_Create send as fader.lua
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
local defaultTrackHeight = 28
local applyLayout19 = false

--=====FUNCTIONS=====--
local unselectAllChannelsID = 40297
local createNewTrackID = 40001

function createFaderSend(source, destination)
    --sekect the source track and create the fader
    reaper.Main_OnCommand(createNewTrackID, 0)
    
    --get the middle track and unselect it
    local middleTrack = reaper.GetSelectedTrack(0, 0)
    reaper.SetTrackSelected(middleTrack, false)
    setupMiddleTrack(source, middleTrack, destination)
    
    --create sends
    local sendMiddle = reaper.CreateTrackSend(source, middleTrack)
    local sendFinal = reaper.CreateTrackSend(middleTrack, destination)
end

function setupMiddleTrack(source, middle, destination)
    --disable master/parent send
    reaper.SetMediaTrackInfo_Value(middle, 'B_MAINSEND', 0)
    
    --name the track
    local ree, sourceName = reaper.GetSetMediaTrackInfo_String( source, 'P_NAME', 'dummy', false )
    local ree2, targetName = reaper.GetSetMediaTrackInfo_String( destination, 'P_NAME', 'dummy', false )

    reaper.GetSetMediaTrackInfo_String(middle, 'P_NAME', sourceName .. " >>> " .. targetName, true)

    --reorder the track
    local sourceID = reaper.GetMediaTrackInfo_Value(source, 'IP_TRACKNUMBER')
    reaper.SetTrackSelected(middle, true)
    reaper.ReorderSelectedTracks(sourceID-1, 0)
    
    if applyLayout19 == true then
        reaper.Main_OnCommand(41714, 0) --apply layout #19
    end
    reaper.SetTrackSelected(middle, false)
    
    --color the track
    reaper.SetTrackColor(middle, reaper.ColorToNative(0, 0, 0))

    --set track height
    reaper.SetMediaTrackInfo_Value(middle, 'I_HEIGHTOVERRIDE', defaultTrackHeight)
    reaper.SetMediaTrackInfo_Value(middle, 'B_HEIGHTLOCK', 1)
end

--=====MAIN=====--
local scriptTitle = 'Create send as fader'

function main()
    reaper.PreventUIRefresh(-1)
    reaper.Undo_BeginBlock()
    
    --check for selected tracks
    local trackCount = reaper.CountSelectedTracks(0)
    if trackCount <= 1 then
        reaper.ShowMessageBox("No tracks selected. Select at least two tracks.", "BirdBird_Create send as fader", 0)
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

main()