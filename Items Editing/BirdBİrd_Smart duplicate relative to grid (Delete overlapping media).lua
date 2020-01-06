--[[
* ReaScript Name: Smart duplicate relative to grid (Delete overlapping media).lua
* Author: MPL, BirdBird mod
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
local deleteOverlapsOnFreeItemPositioningMode = true

--=====UTILITY=====--
floatingPointThreshold = 0.000001
function p(msg) reaper.ShowConsoleMsg(tostring(msg)..'\n')end
function contains(table, element)
    for _, value in pairs(table) do
        if value == element then
            return true
        end
    end
    return false
end

function getSelectedItems()
    --return if no items are selected
    local selectedItemCount = reaper.CountSelectedMediaItems(0)
    if selectedItemCount == 0 then
        return 0
    end

    --return selected items
    local items = {}
    for i = 0, selectedItemCount - 1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        table.insert( items,item)
    end

    return items
end

function getTracksWithMediaItemsSelected()
    local tracks = {}
    local items = getSelectedItems()
    for i = 1, #items do 
        local item = items[i]
        local itemTrack = reaper.GetMediaItemTrack(item)
        if contains(tracks, itemTrack) == false then
            table.insert( tracks, itemTrack)
        end
    end

    return tracks
end

function isBetween(x, a,b)
	if x >= a and x <=b then
		return true
	else
		return false
	end
end

function getItemsInRange(track, startPos, endPos)
	local freeItemPositioning = reaper.GetMediaTrackInfo_Value(track, 'B_FREEMODE')
	local itemsInRange = {}
    local trackItemCount = reaper.CountTrackMediaItems(track)
	
	if freeItemPositioning == 1 and deleteOverlapsOnFreeItemPositioningMode == false then
		goto empty
	end
	
	for i = 0, trackItemCount-1 do
        local item = reaper.GetTrackMediaItem(track, i)
		local itemPosition = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
		local itemLength = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
		
		local itemEndPosition = itemPosition + itemLength - floatingPointThreshold
		itemPosition = itemPosition + floatingPointThreshold

		local itemOverlapsStart = isBetween(startPos, itemPosition, itemEndPosition)
		
		local itemOverlapsEnd = isBetween(endPos, itemPosition, itemEndPosition)
		
		if (isBetween(startPos, itemPosition, itemEndPosition) or isBetween(endPos, itemPosition, itemEndPosition)) or (itemPosition >= startPos and itemEndPosition <= endPos) then --item is in range
			table.insert(itemsInRange, item) 
        end
    end

	::empty::
	return itemsInRange
end

selectedItems = {}
function saveItemSelection()
	local selectedItemCount = reaper.CountSelectedMediaItems(0)
	for i = 0, selectedItemCount-1 do
        local item = reaper.GetSelectedMediaItem(0, i)
        table.insert(selectedItems, item)
    end
end

function restoreItemSelection()
    for i = 1, #selectedItems do 
        local item = selectedItems[i]
        reaper.SetMediaItemSelected(item, true)
    end
end
--=====MAIN=====--  
function main()
    selectedItemCount = reaper.CountSelectedMediaItems(0)
	if  selectedItemCount == 0 then
		return
	end

	local tracksWithItems = getTracksWithMediaItemsSelected()
	saveItemSelection()
	local loopStart, loopEnd = reaper.GetSet_LoopTimeRange(0, false, 1, 1, 0) --save time selection
	
	startPosition = math.huge
    endPosition = 0
    for i = 1, selectedItemCount do
        item = reaper.GetSelectedMediaItem(0, i-1)
        if item ~= nil then
        	itemPosition = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
        	itemLength = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
        	startPosition= math.min(startPosition,itemPosition)
        	endPosition= math.max(endPosition,itemPosition+itemLength)
        end  
    end
    selectionLength = endPosition - startPosition   

	--set target grid positions
	closestDivision = reaper.BR_GetClosestGridDivision(startPosition)  
    if math.abs(closestDivision - startPosition) < floatingPointThreshold then 
        previousDivision = closestDivision
    else 
        previousDivision = reaper.BR_GetPrevGridDivision(startPosition)
    end
      
    closestDivision2 = reaper.BR_GetClosestGridDivision(endPosition)     
    if math.abs(closestDivision2 - endPosition) < floatingPointThreshold then
        nextDivision = closestDivision2
    else 
    	nextDivision = reaper.BR_GetNextGridDivision(endPosition) 
    end  
      
    nudgeAmount = selectionLength + (startPosition - previousDivision) + (nextDivision - endPosition)
	
	--delete overlapping items
	reaper.Main_OnCommand(40289, 0) --unselect all items
    local duplicateStartPos = nextDivision
    local duplicateEndPos = nextDivision + (nextDivision - previousDivision)
	
	reaper.GetSet_LoopTimeRange(1, false, duplicateStartPos, duplicateEndPos, 0) --make time selection
	
	--select items in range
	for i = 1, #tracksWithItems do
		local track = tracksWithItems[i]
		local itemsInRange = getItemsInRange(track, duplicateStartPos, duplicateEndPos)
		
		for j = 1, #itemsInRange do
			local item = itemsInRange[j]
			reaper.SetMediaItemSelected(item, true)
		end
	end
		
	reaper.Main_OnCommand(40061, 0) --split items at time selection
	reaper.Main_OnCommand(40006, 0) -- remove selected items

	restoreItemSelection()
	
	reaper.ApplyNudge(0, 0, 5, 1, nudgeAmount , 0, 1)    
	reaper.GetSet_LoopTimeRange(1, false, loopStart, loopEnd, 0) --restore time selection
end
     
reaper.Undo_BeginBlock()
reaper.PreventUIRefresh(1)
main()
reaper.PreventUIRefresh(-1)
reaper.UpdateArrange()
reaper.Undo_EndBlock("Smart duplicate relative to grid (Delete overlapping media)", 0)