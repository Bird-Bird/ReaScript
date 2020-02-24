--[[
* ReaScript Name: Delete item under mouse
* Author: BirdBird
* Licence: GPL v3
* REAPER: 6.0
* Extensions: None
* Version: 1.0
--]]

--[[
* Changelog:
* v1.0 (2020-02-02)
    + Initial Release
--]]

local x,y = reaper.GetMousePosition()
local item,take = reaper.GetItemFromPoint( x, y, false )
if item ~= nil then
    reaper.Undo_BeginBlock()
    reaper.DeleteTrackMediaItem(reaper.GetMediaItemTrack(item), item)
    reaper.Undo_EndBlock('Delete item under mouse', -1)
    reaper.UpdateArrange()
end