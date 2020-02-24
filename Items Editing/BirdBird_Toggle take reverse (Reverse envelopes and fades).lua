--[[
* ReaScript Name: Toggle take reverse (Reverse envelopes and fades)
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
--]]

function pm(msg) reaper.ShowConsoleMsg(tostring(msg) .. '\n') end

function main()
    local items = {}
    --save selection
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
        
        --offset item position
        local itemPos = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
        local itemLength = reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
        local playRate = reaper.GetMediaItemTakeInfo_Value(take, 'D_PLAYRATE')

        local itemEnd = itemPos + itemLength
        
        --swap fades
        local fadeInLength =  reaper.GetMediaItemInfo_Value(item, 'D_FADEINLEN')
        local fadeInDir =     reaper.GetMediaItemInfo_Value(item, 'D_FADEINDIR')
        local fadeInShape =   reaper.GetMediaItemInfo_Value(item, 'C_FADEINSHAPE')

        local fadeOutLength = reaper.GetMediaItemInfo_Value(item, 'D_FADEOUTLEN')
        local fadeOutDir =    reaper.GetMediaItemInfo_Value(item, 'D_FADEOUTDIR')
        local fadeOutShape =  reaper.GetMediaItemInfo_Value(item, 'C_FADEOUTSHAPE')

        reaper.SetMediaItemInfo_Value(item, 'D_FADEINLEN', fadeOutLength)
        reaper.SetMediaItemInfo_Value(item, 'D_FADEINDIR', fadeOutDir)
        reaper.SetMediaItemInfo_Value(item, 'C_FADEINSHAPE', fadeOutShape)
        
        reaper.SetMediaItemInfo_Value(item, 'D_FADEOUTLEN', fadeInLength)
        reaper.SetMediaItemInfo_Value(item, 'D_FADEOUTDIR', fadeInDir)
        reaper.SetMediaItemInfo_Value(item, 'C_FADEOUTSHAPE', fadeInShape)

        --reverse take envelopes
        local takeEnvelopeCount =  reaper.CountTakeEnvelopes(take)
        for j = 0, takeEnvelopeCount - 1 do
            local env =  reaper.GetTakeEnvelope(take, j)
            local pointCount =  reaper.CountEnvelopePoints(env)
            
            local pointBuffer = {}
            
            --fill envelope points
            for k = pointCount - 1, 0, -1 do 
                local e_retval, e_time, e_value, e_shape, e_tension, e_selected = reaper.GetEnvelopePoint(env, k)
                local e = {time = e_time, tension = e_tension, value = e_value, shape = e_shape, tension = e_tension, selected = e_selected}
                table.insert( pointBuffer, e)
                reaper.DeleteEnvelopePointEx( env, -1, k)
            end

            --insert points reversed
            for k = 1, #pointBuffer do
                local p = pointBuffer[k]

                --need to grab tension and shape from the next point as order is reversed
                local tension = k < #pointBuffer and pointBuffer[k+1].tension or p.tension
                local shape = k < #pointBuffer and pointBuffer[k+1].shape or p.shape

                reaper.InsertEnvelopePoint( env, itemLength*playRate - p.time, p.value, shape, tension*-1, p.selected, true )
            end
            reaper.Envelope_SortPoints(env)
        end
        
        reaper.Main_OnCommand(41051, -1) --take reverse
        
        reaper.SetMediaItemSelected(item, false)
    end

    --restore selection
    for i = 1, #items do
        reaper.SetMediaItemSelected(items[i], true)
    end
end

reaper.PreventUIRefresh(1)
reaper.Undo_BeginBlock()
main()
reaper.Undo_EndBlock('Smart reverse', -1)
reaper.PreventUIRefresh(-1)