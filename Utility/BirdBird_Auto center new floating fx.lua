--[[
 * ReaScript Name: Auto center new floating fx
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

--=====SETTINGS=====--
local screenStartX = 0
local screenStartY = 0
local screenX = 1920
local screenY = 1080

--=====UTILITY=====--
function p(msg) reaper.ShowConsoleMsg(tostring(msg)..'\n')end

--=====FUNCTIONS=====--
function onProjectStateChange(action)
    if string.match( action, '^Add FX: Track' ) or action == 'Insert virtual instrument on new track' then
        centerActiveFloatingFX()
    end
end

function centerActiveFloatingFX()
    local sx, sy = reaper.GetMousePosition()
    local tx, ty = screenStartX + screenX/2, screenStartY + screenY/2

    reaper.JS_Mouse_SetPosition(tx,ty) --move cursor to screen center
    
    --center floating plugin window
    local SWSCenterAction = reaper.NamedCommandLookup('_BR_MOVE_FX_WINDOW_TO_MOUSE_H_M_V_M')
    reaper.Main_OnCommand(SWSCenterAction, 0)

    reaper.JS_Mouse_SetPosition(sx,sy) --restore cursor position 
end

--=====MAIN=====--
local lastProjectChangeCount = 0
function main()
    local projectChangeCount = reaper.GetProjectStateChangeCount(0)
    if projectChangeCount > lastProjectChangeCount then
        local lastAction = reaper.Undo_CanUndo2(0) --get last action
        if lastAction ~= nil then      
            onProjectStateChange(lastAction) --something happened in the project
        end
        
        lastProjectChangeCount = projectChangeCount -- store "Project State Change Count" for the next pass
    end
    
    reaper.defer(main)    
end

main()