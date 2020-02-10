--[[
* ReaScript Name: Print item state chunk
* Author: BirdBird
* Licence: GPL v3
* REAPER: 6.0
* Extensions: None
* Version: 1.0
--]]

--[[
* Changelog:
* v1.0 (2020-10-02)
    + Initial Release
--]]

local item = reaper.GetSelectedMediaItem(0, 0)
if item ~= nil then
    local ret, chunk = reaper.GetItemStateChunk(item, '', false)
    reaper.ShowConsoleMsg(chunk)
end
