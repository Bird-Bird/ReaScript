--[[
 * ReaScript Name: Initialize dragged audio item with custom settings
 * Author: BirdBird
 * Licence: GPL v3
 * REAPER: 6.0
 * Extensions: None
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2019-27-19)
 	+ Initial Release
--]]

local defaultGain = -10
local focusArrangeID = reaper.NamedCommandLookup('_BR_FOCUS_ARRANGE_WND')
local mediaExplorerWindowName = 'SysListView32'

function isMEFocused()
    local focusedWindow =  reaper.JS_Window_GetFocus()
    local windowClass = reaper.JS_Window_GetClassName( focusedWindow )

    return windowClass == mediaExplorerWindowName
end

local lastSelectedItem = nil
local lastItemCount = 0
local lastProject = ''
function main()
    local skip = false
    local selectedItem = reaper.GetSelectedMediaItem(0, 0)
    local itemCount = reaper.CountMediaItems(0)

    local project , projfn = reaper.EnumProjects(-1)
    --track if current project has changed
    if project ~= lastProject then
        lastProject = project
        skip = true
    end

    if isMEFocused() == true and skip == false then
        local selectedItemCount = reaper.CountSelectedMediaItems(0)

        if itemCount > lastItemCount and (lastSelectedItem ~= selectedItem and selectedItemCount == 1) then
            local take = reaper.GetTake(selectedItem,0)
            reaper.SetMediaItemTakeInfo_Value(take,"D_VOL",10^(defaultGain/20))
            reaper.UpdateArrange()

            reaper.Main_OnCommand(focusArrangeID, 0)
        end
    end

    lastSelectedItem = selectedItem
    lastItemCount = itemCount

    reaper.defer(main)
end

main()