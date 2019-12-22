--[[
 * ReaScript Name: BirdBird_Toggle compact for selected folder tracks (tiny).lua
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
local scriptTitle = 'Toggle compact for selected folder tracks (tiny)'

function main() 
    --check for selected tracks
	local selectedTrackCount = reaper.CountSelectedTracks(0)
	if selectedTrackCount == 0 then
		return
    end

    reaper.PreventUIRefresh(1)
    reaper.Undo_BeginBlock()

    for i = 0, selectedTrackCount-1 do
		local track = reaper.GetSelectedTrack(0, i)
        
        local compactMode = reaper.GetMediaTrackInfo_Value(track, 'I_FOLDERCOMPACT' )
        if compactMode == 1 or compactMode == 2 then
            reaper.SetMediaTrackInfo_Value(track, 'I_FOLDERCOMPACT', 0)    
        elseif compactMode == 0 then
            reaper.SetMediaTrackInfo_Value(track, 'I_FOLDERCOMPACT', 2)
        end
    end
    
    reaper.Undo_EndBlock(scriptTitle, -1)
    reaper.PreventUIRefresh(-1)
end
--==========--
main()