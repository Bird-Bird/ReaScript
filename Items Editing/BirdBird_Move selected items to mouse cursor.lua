--[[
 * ReaScript Name: Move selected items to mouse cursor
 * Author: BirdBird
 * Licence: GPL v3
 * REAPER: 6.0
 * Extensions: None
 * Version: 1.1
--]]
 
--[[
 * Changelog:
 * v1.0 (2020-18-03)
     + Initial Release
--]]

local selectedItemCount = reaper.CountSelectedMediaItems(0)
if selectedItemCount == 0 then return end

local items = {}

local min = math.huge
for i = 0, selectedItemCount-1 do 
    local item = reaper.GetSelectedMediaItem(0, i)
    local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    min = math.min(pos, min)
end

for i = 0, selectedItemCount-1 do 
    local item = reaper.GetSelectedMediaItem(0, i)
    local pos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
    local offset = pos - min
    items[item] = offset
end

local mousePos = reaper.BR_PositionAtMouseCursor(1)
mousePos = reaper.SnapToGrid(0, mousePos)

for item, offset in pairs(items) do
    reaper.SetMediaItemInfo_Value(item, 'D_POSITION', mousePos + offset)
end