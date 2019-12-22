--[[
 * ReaScript Name: BirdBird_Select Folder Children.lua
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
local selectSnapOffset = true --selects the item if snap offset is in range of the folder item

--=====UTILITY=====--
function p(message)
    reaper.ShowConsoleMsg([[
    
    ]])
    reaper.ShowConsoleMsg(tostring(message))
end

function contains(parentItem, item)
    local parentItem = parentItem
    local item = item
    local offset = 0.0000001
    
    local parentIn = reaper.GetMediaItemInfo_Value( parentItem,"D_POSITION") - 0.000000000001
    local parentOut = parentIn + reaper.GetMediaItemInfo_Value( parentItem,"D_LENGTH") + 0.000000000002

    parentIn = parentIn - offset  
    parentOut = parentOut - offset

    local itemIn = reaper.GetMediaItemInfo_Value( item,"D_POSITION") 
    local itemOut = itemIn + reaper.GetMediaItemInfo_Value( item,"D_LENGTH")
    local snapOffset = itemIn + reaper.GetMediaItemInfo_Value(item, 'D_SNAPOFFSET')
    
    if isBetween(itemIn, parentIn, parentOut) or (isBetween(snapOffset, parentIn,parentOut) == true and selectSnapOffset == true) then
        return true
    else
        return false
    end
end

function isBetween(x, a, b)
    if x >= a and x <= b then
        return true
    else
        return false
    end
end

function trackReachesParent(parent, child)
    local currentTrack = child
    while (currentTrack ~= nil)
    do
        local parentTrack = reaper.GetParentTrack(currentTrack)
        if(parentTrack == nil) then
            return false
        elseif parentTrack == parent then
            return true
        end
        currentTrack = parentTrack
    end  
end

function getChildTracks(track)
    local folderTrack = track
    local folderID = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
    local count = reaper.CountTracks(0) - 1

    local children = {}
    for i=folderID, count do
        local childTrack = reaper.GetTrack(0, i)
        if trackReachesParent(track, childTrack) then
            table.insert(children, childTrack)
        else
            break
        end
    end

    return children
end

function hasParent(track)
    return reaper.GetParentTrack(track) ~= nil
end

function markName(track)
    local ree, name = reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', 'dummy', false)
    if hasPrefix(name) == false then
        name = trackIdentifier .. ' ' .. name
        reaper.GetSetMediaTrackInfo_String(track, 'P_NAME', name, true)
    end
end

--=====MAIN=====--
function main()
    --check for selected items
    local selectedItemCount = reaper.CountSelectedMediaItems(0)
    if selectedItemCount == 0 then
        --reaper.ShowMessageBox("No media items selected.", "Error", 0) --silently failing is less annoying to use
        return
    end

    --get selected items
    local selectedItems = {}
    for i = 0, selectedItemCount - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        table.insert(selectedItems, item)
    end

    --select folder children for every selected item
    local runOnTracks = {}
    for i = 1, #selectedItems do
        local item = selectedItems[i]
        local itemTrack = reaper.GetMediaItemTrack(item)
        local children = getChildTracks(itemTrack)
        
        for x = 1, #children do
            local track = children[x]
            
            --for each media item on child track
            local trackItemCount = reaper.CountTrackMediaItems(track)
            for j = 0, trackItemCount-1 do
                local childItem = reaper.GetTrackMediaItem(track, j)
                
                --check if item is under a target and select it
                if contains(item, childItem) == true then
                    reaper.SetMediaItemSelected(childItem, true)
                end
            end
        end
    end

    reaper.UpdateArrange()
end
--==========--
main()
