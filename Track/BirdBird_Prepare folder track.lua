--[[
* ReaScript Name: Prepare folder track
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

local trackID = 'IFolder'

reaper.Undo_BeginBlock()

local track = reaper.GetLastTouchedTrack()
if track ~= nil then
    local ret, name = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', '', false)
    if name ~= 'IFolder' then
        reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', trackID, true)
    else
        reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', 'Default', true)
    end
end

reaper.Undo_EndBlock('Preapare folder track', -1)