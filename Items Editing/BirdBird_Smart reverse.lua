--[[
* ReaScript Name: Smart reverse.lua
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
* v1.1 (2020-10-02)
    + Improved fade behaviour
--]]

function main()
    local items = {}
    local itemCount = reaper.CountSelectedMediaItems(0)
    for i = itemCount - 1, 0, -1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        reaper.SetMediaItemSelected(item, false)
        table.insert(items, item)
    end    
    
    local itemCount = reaper.CountSelectedMediaItems(0)
    for i = 1, #items do
        local item = items[i]
        reaper.SetMediaItemSelected(item, true)

        local take = reaper.GetMediaItemTake(item, 0)
        local retval, section, start, length, fade, reverse = reaper.BR_GetMediaSourceProperties( take )
        
        --Offset item position
        local itemPos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
        local itemLength = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
        local itemEnd = itemPos + itemLength
        
        local targetPos = reverse and reaper.SnapToGrid(0, itemPos) or reaper.SnapToGrid(0, itemEnd) --snap end to closest if very close, otherwisse next
        local offset = reverse and targetPos - itemPos or targetPos - itemEnd        
        reaper.SetMediaItemInfo_Value(item, 'D_POSITION', itemPos + offset)
        
        --Swap fades
        local fadeInLength =  reaper.GetMediaItemInfo_Value(item, 'D_FADEINLEN')
        local fadeInDir =     reaper.GetMediaItemInfo_Value(item, 'D_FADEINDIR')
        local fadeOutLength = reaper.GetMediaItemInfo_Value(item, 'D_FADEOUTLEN')
        local fadeOutDir =    reaper.GetMediaItemInfo_Value(item, 'D_FADEOUTDIR')

        reaper.SetMediaItemInfo_Value(item, 'D_FADEINLEN', fadeOutLength)
        reaper.SetMediaItemInfo_Value(item, 'D_FADEINDIR', fadeOutDir)
        reaper.SetMediaItemInfo_Value(item, 'D_FADEOUTLEN', fadeInLength)
        reaper.SetMediaItemInfo_Value(item, 'D_FADEOUTDIR', fadeInDir)
        
        reaper.Main_OnCommand(41051, -1) --take reverse
        
        reaper.SetMediaItemSelected(item, false)
    end

    for i = 1, #items do
        reaper.SetMediaItemSelected(items[i], true)
    end
end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock('Smart reverse', -1)
reaper.PreventUIRefresh(-1)