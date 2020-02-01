--[[
 * ReaScript Name: Quick Resample.lua
 * Author: BirdBird
 * Licence: GPL v3
 * REAPER: 6.0
 * Extensions: None
 * Version: 1.5
--]]
 
--[[
 * Changelog:
 * v1.0 (2019-12-19)
	 + Initial Release
 * v1.1 
	 + Added multiout recording support
 * v1.3
	 + Fixed workflow issues with record mode
 * v1.4
	 + Fixed more workflow issues
--]]

--=====UTILITY=====--
local resampleTrackName = 'Resample'
local insertNewTrackCommandID = 40001
local unselectAllTracksCommandID = 40297
local clearAutomaticRecordArmCommandID = 40738
local transportRecordCommandID = 1013

function p(message) reaper.ShowConsoleMsg(tostring(message)..'\n')end

function checkForResampleTrack()
	local trackCount = reaper.CountTracks(0)
	for i = 0, trackCount-1 do
		local track = reaper.GetTrack(0, i)
		local retval, trackIsResampleTrack = reaper.GetSetMediaTrackInfo_String(track, "P_EXT:BirdBirdResample", '0', false)
		if trackIsResampleTrack == '1' then
			return track
		end
	end
	return nil
end

function markTrackAsResampleTrack(track)
    reaper.GetSetMediaTrackInfo_String(track, "P_EXT:BirdBirdResample", '1', true)
end

function createNewResampleTrack()
	reaper.Main_OnCommand(insertNewTrackCommandID, 0)

	local newTrack = reaper.GetSelectedTrack(0, 0)
	markTrackAsResampleTrack(newTrack)
	reaper.Main_OnCommand(40737, 0)
	
	reaper.GetSetMediaTrackInfo_String(newTrack, 'P_NAME', resampleTrackName, true) --give it a fancy name
	reaper.SetTrackColor(newTrack, reaper.ColorToNative(0, 0, 0)|0x100000) --give it a fancy color
	
	--record stereo out
	reaper.SetMediaTrackInfo_Value(newTrack, 'I_RECMODE', 1)
	reaper.SetMediaTrackInfo_Value(newTrack, 'I_RECINPUT', -1)
	
	--disable record monitoring
	reaper.SetMediaTrackInfo_Value(newTrack, 'I_RECMONITEMS', 0)
	reaper.SetMediaTrackInfo_Value(newTrack, 'I_RECMON', 0)
	
	--enable free item positioning
	reaper.SetMediaTrackInfo_Value(newTrack, 'B_FREEMODE', 1)

	--disable master/parent send
	reaper.SetMediaTrackInfo_Value(newTrack, 'B_MAINSEND', 0)

	return newTrack
end

function clearReceives(track)
	local receiveCount = reaper.GetTrackNumSends(track, -1)
	for i = 0, receiveCount - 1 do
		reaper.RemoveTrackSend(track, -1, 0)
	end
end

--=====UTILITY=====--
function main()
    reaper.PreventUIRefresh(1)

	--check for selected tracks
	local selectedTrackCount = reaper.CountSelectedTracks(0)
	if selectedTrackCount == 0 then
		reaper.ShowMessageBox('Please select tracks to resample.', 'Error', 0)
		return
	end

	--get selected tracks
	local lastTouchedTrack =  reaper.GetLastTouchedTrack()
	local selectedTracks = {}
	for i = 0, selectedTrackCount-1 do
		local track = reaper.GetSelectedTrack(0, i)
		table.insert( selectedTracks, track)
	end

	--check/get resample track and select it
	reaper.Main_OnCommand(unselectAllTracksCommandID, 0)
	local resampleTrack = checkForResampleTrack()
	if not resampleTrack then
		resampleTrack = createNewResampleTrack()
	end
	reaper.Main_OnCommand(clearAutomaticRecordArmCommandID, 0)

	--clear receives on resample track
	clearReceives(resampleTrack)

	--send selected tracks to resample track
	for i=1, #selectedTracks do
		local track = selectedTracks[i]
		--multiout support
		local numberOfChannels = reaper.GetMediaTrackInfo_Value(track, 'I_NCHAN')/2
		for j=0, numberOfChannels-1 do
			local sendID = reaper.CreateTrackSend(track, resampleTrack)
			reaper.SetTrackSendInfo_Value( track, 0, sendID, 'I_SRCCHAN', j*2)
		end
	end

	--move resample track above the last touched track
	reaper.SetTrackSelected(resampleTrack, true)
	local lastSelectedSourceTrack = lastTouchedTrack
	local lastSelectedSourceTrackID = reaper.GetMediaTrackInfo_Value(lastSelectedSourceTrack, "IP_TRACKNUMBER")
	reaper.ReorderSelectedTracks(lastSelectedSourceTrackID-1, 2)
	reaper.SetMediaTrackInfo_Value(resampleTrack, 'I_RECARM', 1)
	
	reaper.PreventUIRefresh(-1)

	--restore selection
	reaper.Main_OnCommand(40297, -1) --unselect all tracks
	for i=1, #selectedTracks do --restore track selection
		local track = selectedTracks[i]
		reaper.SetTrackSelected(track, true)
	end
	
	reaper.Main_OnCommand(transportRecordCommandID, 0)
end

main()

