local input = {}
local ok, keyboard = pcall(dofile, '/os/keyboard.lua')
if not ok then keyboard = nil end

local function keyboardSide()
    if not fs.exists('/os/settings.cfg') then return nil end
    local f=fs.open('/os/settings.cfg','r')
    if not f then return nil end
    local data=f.readAll(); f.close()
    local ok2,s=pcall(textutils.unserialize,data)
    if ok2 and type(s)=='table' then return s.keyboardMonitor end
    return nil
end

function input.pull()
    while true do
        local e={os.pullEvent()}
        local kind=e[1]
        if kind=='monitor_touch' then
            local side=keyboardSide()
            if side and e[2]==side and keyboard then
                local m=peripheral.wrap(side)
                if m then
                    local event=keyboard.touch(m,e[3],e[4])
                    if event then return event end
                end
            else
                return {kind='touch',side=e[2],x=e[3],y=e[4]}
            end
        elseif kind=='key' then
            local k=e[2]
            if k==keys.up then return {kind='move',dir='up'}
            elseif k==keys.down then return {kind='move',dir='down'}
            elseif k==keys.left then return {kind='move',dir='left'}
            elseif k==keys.right then return {kind='move',dir='right'}
            elseif k==keys.enter then return {kind='activate'}
            elseif k==keys.escape then return {kind='back'}
            elseif k==keys.backspace then return {kind='backspace'}
            else return {kind='key',key=k} end
        elseif kind=='char' then return {kind='char',char=e[2]}
        elseif kind=='paste' then return {kind='paste',text=e[2]}
        elseif kind=='monitor_resize' or kind=='term_resize' then return {kind='resize'}
        end
    end
end

return input
