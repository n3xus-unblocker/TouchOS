local app = { name = 'Monitor Setup', icon = 'Monitor' }

local MIN_W = 30
local MIN_H = 12

function app.run(ctx)
    local d = ctx.disp
    local u = ctx.ui
    local input = ctx.input
    local settings = ctx.settings

    local mode = 'screen'
    local selected = 1
    local monitors = {}

    local function scan()
        monitors = {}

        for _, side in ipairs(peripheral.getNames()) do
            if peripheral.getType(side) == 'monitor' then
                local m = peripheral.wrap(side)
                if m then
                    local w, h = m.getSize()
                    monitors[#monitors + 1] = {
                        side = side,
                        w = w,
                        h = h
                    }
                end
            end
        end

        table.sort(monitors, function(a, b)
            return a.side < b.side
        end)

        selected = u.clamp(selected, 1, math.max(1, #monitors))
    end

    local function save()
        ctx.saveSettings(settings)
    end

    local function draw()
        scan()

        local w, h = d.getSize()
        u.clear(d)
        u.header(d, 'Monitor Setup', mode == 'screen' and 'Choose main screen' or 'Choose touch keyboard')

        local toggleW = math.min(32, math.max(1, w - 2))
        local toggleX = math.max(1, math.floor((w - toggleW) / 2) + 1)

        u.button(
            d,
            {
                x = toggleX,
                y = 4,
                w = toggleW,
                h = 2,
                label = mode == 'screen' and 'MODE: SCREEN' or 'MODE: KEYBOARD'
            },
            true
        )

        local listTop = 7
        local listBottom = math.max(listTop, h - 4)
        local visible = math.max(1, listBottom - listTop + 1)

        for i = 1, math.min(#monitors, visible) do
            local m = monitors[i]
            local y = listTop + i - 1
            local isScreen = settings.screenMonitor == m.side
            local isKeyboard = settings.keyboardMonitor == m.side
            local usable = m.w >= MIN_W and m.h >= MIN_H and not isScreen

            local state
            if mode == 'screen' then
                state = isScreen and '[SCREEN]' or '[SET SCREEN]'
            else
                if isKeyboard then
                    state = '[KEYBOARD]'
                elseif usable then
                    state = '[SET KEYBOARD]'
                else
                    state = '[UNAVAILABLE]'
                end
            end

            local label = state .. ' ' .. m.side .. ' ' .. m.w .. 'x' .. m.h

            u.button(
                d,
                {
                    x = 1,
                    y = y,
                    w = w,
                    h = 1,
                    label = label
                },
                i == selected,
                mode == 'keyboard' and not usable
            )
        end

        local navY = math.max(1, h - 3)
        local half = math.max(1, math.floor(w / 2))
        u.button(d, { x = 1, y = navY, w = half, h = 2, label = 'SWITCH MODE' }, false)
        u.button(d, { x = half + 1, y = navY, w = w - half, h = 2, label = 'DONE + REBOOT' }, true)
        u.status(d, 'Touch a monitor to assign it', mode)
    end

    draw()

    while true do
        local e = input.pull()

        if e.kind == 'back' then
            os.reboot()

        elseif e.kind == 'resize' then
            draw()

        elseif e.kind == 'move' then
            if e.dir == 'up' then
                selected = u.clamp(selected - 1, 1, math.max(1, #monitors))
            elseif e.dir == 'down' then
                selected = u.clamp(selected + 1, 1, math.max(1, #monitors))
            end
            draw()

        elseif e.kind == 'touch' then
            local w, h = d.getSize()
            local listTop = 7
            local navY = math.max(1, h - 3)
            local half = math.max(1, math.floor(w / 2))

            if e.y >= navY then
                if e.x <= half then
                    mode = mode == 'screen' and 'keyboard' or 'screen'
                    draw()
                else
                    os.reboot()
                end
            elseif e.y >= listTop and e.y < navY then
                local index = e.y - listTop + 1
                local m = monitors[index]

                if m then
                    selected = index

                    if mode == 'screen' then
                        settings.screenMonitor = m.side
                        if settings.keyboardMonitor == m.side then
                            settings.keyboardMonitor = nil
                        end
                        save()
                    else
                        local usable = m.w >= MIN_W
                            and m.h >= MIN_H
                            and m.side ~= settings.screenMonitor

                        if usable then
                            settings.keyboardMonitor = m.side
                            save()
                        end
                    end

                    draw()
                end
            elseif e.y == 4 then
                mode = mode == 'screen' and 'keyboard' or 'screen'
                draw()
            end
        end
    end
end

return app
