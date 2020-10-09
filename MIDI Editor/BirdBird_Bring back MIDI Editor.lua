--[[
 * ReaScript Name: Bring back MIDI Editor.lua
 * Author: BirdBird
 * Licence: GPL v3
 * REAPER: 6.0
 * Extensions: None
 * Version: 1.0
--]]
 
--[[
 * Changelog:
 * v1.0 (2020-10-10)
     + Initial Release
--]]

if not reaper.BR_Win32_GetWindowText then
    reaper.ShowMessageBox("This script requires the SWS Extension to fuction. You can get it from https://www.sws-extension.org/.", "BirdBird - Missing Packages", 0)
    return
end

if not reaper.JS_Window_ListAllTop then
    reaper.ShowMessageBox("This script requires js_ReaScriptAPI to function. You can get it through ReaPack.", "BirdBird - Missing Packages", 0)
    return
end

local openMediaItemPropertiesForAudioItems = true --set to true if you want it to open media item properties for audio items
local offscreen = 10000 --position for "offscreen" editor

function p(msg) reaper.ShowConsoleMsg(tostring(msg) .. '\n') end

--Open Media Item Properties window for audio items
local selectedItemCount = reaper.CountSelectedMediaItems(0)
if selectedItemCount > 0 then
    local selectedItem = reaper.GetSelectedMediaItem(0, 0)
    local activeTake = reaper.GetMediaItemTake(selectedItem, 0)
    if not reaper.TakeIsMIDI(activeTake) == true and openMediaItemPropertiesForAudioItems then
        reaper.Main_OnCommand(40009, 0) 
        return
    end
end

local mainHandle = reaper.GetMainHwnd()
local retval, list = reaper.JS_Window_ListAllTop()
local foundMIDIEditor = false
for address in string.gmatch(list, '([^,]+)') do
    local hwnd = reaper.JS_Window_HandleFromAddress(address)
    if reaper.JS_Window_GetParent(hwnd) == mainHandle then
        local _, text = reaper.BR_Win32_GetWindowText( hwnd )
        
        if text:find("^Edit MIDI") or text:find("^MIDI take") then
            --if the window has been closed open it back up manually
            local visible = reaper.JS_Window_IsVisible( hwnd )
            if not visible then
                foundMIDIEditor = true
                reaper.Main_OnCommand(40153, 0)
                return
            end
            
            --retrieve window position
            local retval, left = reaper.GetProjExtState(0, "BB_MIDI_Window", "left")
            left = tonumber(left)
            local retval, top = reaper.GetProjExtState(0, "BB_MIDI_Window", "top")
            top = tonumber(top)

            --restore default if something went wrong
            if left == offscreen or top == offscreen then
                left = 0
                top = 0
            end

            if left == nil or top == nil then
                left = 0
                top = 0
            end
            
            --move editor and focus it
            reaper.PreventUIRefresh(1)
            
            reaper.JS_Window_Move( hwnd, left, top)
            reaper.JS_Window_SetForeground( hwnd )
            foundMIDIEditor = true
            
            reaper.PreventUIRefresh(-1)
        end
    end
end

if not foundMIDIEditor then
    reaper.Main_OnCommand(40153, 0) --open items in MIDI Editor
end
