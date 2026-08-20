local input = {}

local keyboard = nil
pcall(function()
    keyboard = dofile('/os/keyboard.lua')
end)

local keyboardMonitor = nil

function input.setKeyboardMonitor(side)
    keyboardMonitor = side
end

local function loadKeyboardMonitor()
    if keyboardMonitor and peripheral.isPresent(keyboardMonitor)
        and peripheral.getType(keyboardMonitor) == 'monitor' then
        return keyboardMonitor
    end
    return nil
end

function input.pull()
    while true do
        local e = { os.pullEvent() }
        local kind = e[1]

        if kind == 'monitor_touch' then
            local side = e[2]
            local x = e[3]
            local y = e[4]
            local configured = loadKeyboardMonitor()

            if configured and side == configured and keyboard then
                local monitor = peripheral.wrap(side)
                if monitor then
                    local event = keyboard.touch(monitor, x, y)
                    if event then
                        return event
                    end
                    -- Touching unused space on the keyboard monitor should not
                    -- accidentally become a tap on the main TouchOS display.
                    goto continue
                end
            end

            return { kind = 'touch', side = side, x = x, y = y }

        elseif kind == 'key' then
            local key = e[2]

            if key == keys.up then
                return { kind = 'move', dir = 'up' }
            elseif key == keys.down then
                return { kind = 'move', dir = 'down' }
            elseif key == keys.left then
                return { kind = 'move', dir = 'left' }
            elseif key == keys.right then
                return { kind = 'move', dir = 'right' }
            elseif key == keys.enter then
                return { kind = 'activate' }
            elseif key == keys.escape then
                return { kind = 'back' }
            elseif key == keys.backspace then
                return { kind = 'backspace' }
            end

            return { kind = 'key', key = key }

        elseif kind == 'char' then
            return { kind = 'char', char = e[2] }

        elseif kind == 'paste' then
            return { kind = 'paste', text = e[2] }

        elseif kind == 'monitor_resize' or kind == 'term_resize' then
            return { kind = 'resize' }
        end

        ::continue::
    end
end

return input
