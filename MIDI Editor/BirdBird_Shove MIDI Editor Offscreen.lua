--[[
 * ReaScript Name: Shove MIDI Editor Offscreen.lua
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
local offscreen = 10000

if not reaper.BR_Win32_GetWindowText then
    reaper.ShowMessageBox("This script requires the SWS Extension to fuction. You can get it from https://www.sws-extension.org/.", "BirdBird - Missing Packages", 0)
    return
end

if not reaper.JS_Window_ListAllTop then
    reaper.ShowMessageBox("This script requires js_ReaScriptAPI to function. You can get it through ReaPack.", "BirdBird - Missing Packages", 0)
    return
end


function p(msg) reaper.ShowConsoleMsg(tostring(msg) .. '\n') end

local mainHandle = reaper.GetMainHwnd()
local trackWindow = reaper.JS_Window_FindChildByID(mainHandle, 0x3E8)
local retval, list = reaper.JS_Window_ListAllTop()
for address in string.gmatch(list, '([^,]+)') do
    local hwnd = reaper.JS_Window_HandleFromAddress(address)
    if reaper.JS_Window_GetParent(hwnd) == mainHandle then
        local _, text = reaper.BR_Win32_GetWindowText( hwnd )
        
        if text:find("^Edit MIDI") or text:find("^MIDI take") then
            --save window position to retrieve later
            local retval, left, top, right, bottom = reaper.JS_Window_GetRect(hwnd)
            if left ~= offscreen and top ~= offscreen then
                reaper.SetProjExtState( 0, "BB_MIDI_Window", "left", tostring(left))
                reaper.SetProjExtState( 0, "BB_MIDI_Window", "top", tostring(top))

                --shove MIDI Editor away and set focus to arrange view
                reaper.JS_Window_Move( hwnd, offscreen, offscreen)
                reaper.JS_Window_SetFocus(trackWindow)
                return
            end
        end
    end
end

    