--[[
 * ReaScript Name: BirdBird_Select root track of selected track.lua
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
function main()
local selectedTrack = reaper.GetSelectedTrack(0, 0)
	if not selectedTrack then
		return
	end
	reaper.SetTrackSelected(selectedTrack, false)

	--traverse the parents until the root track is found
	while (hasParent(selectedTrack)) do
		selectedTrack = reaper.GetParentTrack(selectedTrack)
	end    

	reaper.SetTrackSelected(selectedTrack, true)
end

function hasParent(track)
	return reaper.GetParentTrack(track) ~= nil
end
--==========--
main()
