local ui = dofile('/os/ui.lua')
local input = dofile('/os/input.lua')
local keyboard = dofile('/os/keyboard.lua')

local SETTINGS = '/os/settings.cfg'
local APPS = '/apps'

local function loadSettings()
    local s = { textScale = 1, screenMonitor = nil, keyboardMonitor = nil }
    if fs.exists(SETTINGS) then
        local f = fs.open(SETTINGS, 'r')
        if f then
            local ok, data = pcall(textutils.unserialize, f.readAll())
            f.close()
            if ok and type(data) == 'table' then
                for k, v in pairs(data) do s[k] = v end
            end
        end
    end
    return s
end

local settings = loadSettings()

local function saveSettings(s)
    local f = fs.open(SETTINGS, 'w')
    if f then
        f.write(textutils.serialize(s))
        f.close()
    end
end

local function isMonitor(name)
    return name and peripheral.isPresent(name) and peripheral.getType(name) == 'monitor'
end

local function getMonitors()
    local result = {}
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == 'monitor' then
            result[#result + 1] = name
        end
    end
    table.sort(result)
    return result
end

local function chooseDisplay()
    if isMonitor(settings.screenMonitor) then
        return peripheral.wrap(settings.screenMonitor)
    end

    local list = getMonitors()
    if #list > 0 then
        settings.screenMonitor = list[1]
        if settings.keyboardMonitor == settings.screenMonitor then
            settings.keyboardMonitor = nil
        end
        saveSettings(settings)
        return peripheral.wrap(list[1])
    end

    return term
end

local display = chooseDisplay()

if display.setTextScale then
    pcall(display.setTextScale, settings.textScale or 1)
end

local function keyboardDisplay()
    if not isMonitor(settings.keyboardMonitor)
    or settings.keyboardMonitor == settings.screenMonitor then
        return nil
    end

    local m = peripheral.wrap(settings.keyboardMonitor)
    if m and keyboard.isLargeEnough(m) then
        return m
    end

    return nil
end

local function refreshKeyboard()
    local m = keyboardDisplay()
    if m then
        pcall(keyboard.draw, m)
    end
end

refreshKeyboard()

local function shellApp()
    return {
        name = 'Shell',
        icon = '>_',
        run = function(ctx)
            local d = ctx.disp
            local u = ctx.ui
            local inp = ctx.input
            local buffer = ''
            local lines = { 'TouchOS Shell', 'Ready' }

            local function draw()
                local w, h = d.getSize()
                u.clear(d)
                u.header(d, 'Shell', 'Command line')

                local maxLines = math.max(1, h - 7)
                local first = math.max(1, #lines - maxLines + 1)

                for n = first, #lines do
                    u.text(d, 2, n - first + 4, lines[n])
                end

                u.fill(d, 1, math.max(1, h - 3), w, 1, u.theme.surface)
                u.text(
                    d,
                    2,
                    math.max(1, h - 3),
                    '> ' .. u.truncate(buffer, math.max(0, w - 3)),
                    colors.white,
                    u.theme.surface
                )

                local bw = math.max(1, math.floor(w / 2))
                local y = math.max(1, h - 2)

                u.button(d, { x = 1, y = y, w = bw, h = 2, label = 'BACK' }, false)
                u.button(d, { x = bw + 1, y = y, w = w - bw, h = 2, label = 'RUN' }, true)
                u.status(d, 'Touch keyboard or physical keyboard', settings.keyboardMonitor or 'none')
            end

            local function runCommand()
                if buffer == '' then return end

                local command = buffer
                buffer = ''
                lines[#lines + 1] = '> ' .. command

                local old = term.redirect(d)
                local ok, err = pcall(shell.run, command)
                term.redirect(old)

                if not ok then
                    lines[#lines + 1] = 'Error: ' .. tostring(err)
                end
            end

            draw()
            refreshKeyboard()

            while true do
                local e = inp.pull()

                if e.kind == 'back' then
                    return
                elseif e.kind == 'backspace' then
                    buffer = buffer:sub(1, -2)
                    draw()
                elseif e.kind == 'char' then
                    buffer = buffer .. e.char
                    draw()
                elseif e.kind == 'paste' then
                    buffer = buffer .. e.text
                    draw()
                elseif e.kind == 'clear' then
                    buffer = ''
                    draw()
                elseif e.kind == 'activate' then
                    runCommand()
                    draw()
                    refreshKeyboard()
                elseif e.kind == 'touch' then
                    local w, h = d.getSize()
                    local y = math.max(1, h - 2)

                    if e.y >= y then
                        if e.x <= math.floor(w / 2) then
                            return
                        end

                        runCommand()
                        draw()
                        refreshKeyboard()
                    end
                elseif e.kind == 'resize' then
                    draw()
                    refreshKeyboard()
                end
            end
        end
    }
end

local function loadApps()
    local apps = {}

    if not fs.exists(APPS) then
        fs.makeDir(APPS)
    end

    for _, file in ipairs(fs.list(APPS)) do
        if file:match('%.lua$') then
            local path = fs.combine(APPS, file)
            local ok, app = pcall(dofile, path)

            if ok and type(app) == 'table' and type(app.run) == 'function' then
                apps[#apps + 1] = app
            end
        end
    end

    local hasShell = false
    for _, app in ipairs(apps) do
        if app.name == 'Shell' then
            hasShell = true
            break
        end
    end

    if not hasShell then
        apps[#apps + 1] = shellApp()
    end

    table.sort(apps, function(a, b)
        return tostring(a.name) < tostring(b.name)
    end)

    return apps
end

local apps = loadApps()
local selected = #apps > 0 and 1 or nil
local page = 1

local function context()
    return {
        disp = display,
        ui = ui,
        input = input,
        settings = settings,
        saveSettings = function(s)
            settings = s
            saveSettings(s)
            refreshKeyboard()
        end
    }
end

local function layout()
    local w, h = display.getSize()
    local cols = w >= 42 and 3 or (w >= 26 and 2 or 1)
    local cellH = h >= 16 and 4 or 3
    local gap = 2
    local availableH = math.max(1, h - 8)
    local rows = math.max(1, math.floor(availableH / (cellH + 1)))
    local pageSize = cols * rows
    local pages = math.max(1, math.ceil(#apps / pageSize))
    page = ui.clamp(page, 1, pages)
    selected = ui.clamp(selected or 1, 1, math.max(1, #apps))
    return w, h, cols, rows, cellH, gap, pageSize, pages
end

local function buildButtons()
    local w, h, cols, rows, cellH, gap, pageSize, pages = layout()
    local cellW = math.max(1, math.floor((w - (cols + 1) * gap) / cols))
    local first = (page - 1) * pageSize + 1
    local last = math.min(#apps, first + pageSize - 1)
    local buttons = {}

    for n = first, last do
        local i = n - first
        local col = i % cols
        local row = math.floor(i / cols)

        buttons[#buttons + 1] = {
            x = gap + col * (cellW + gap),
            y = 5 + row * (cellH + 1),
            w = cellW,
            h = cellH,
            label = apps[n].name,
            id = n
        }
    end

    return buttons, pages
end

local function drawHome()
    local w, h = display.getSize()
    local _, _, _, _, _, _, _, pages = layout()

    ui.clear(display)
    ui.header(display, 'TouchOS', tostring(#apps) .. ' apps')

    local buttons = buildButtons()
    for _, b in ipairs(buttons) do
        ui.button(display, b, b.id == selected)
    end

    if pages > 1 then
        local navY = math.max(1, h - 3)
        local half = math.max(1, math.floor(w / 2))

        ui.button(disp, { x = 1, y = navY, w = half, h = 2, label = 'PREV' }, page == 1)
        ui.button(disp, { x = half + 1, y = navY, w = w - half, h = 2, label = 'NEXT' }, page == pages)
        ui.status(display, 'Tap an app', 'Page ' .. page .. '/' .. pages)
    else
        ui.status(display, 'Tap an app', 'TouchOS')
    end

    return buttons, pages
end

local buttons, pages = drawHome()

while true do
    local e = input.pull()

    if e.kind == 'resize' then
        buttons, pages = drawHome()

    elseif e.kind == 'touch' then
        local b = ui.hit(buttons, e.x, e.y)

        if b then
            selected = b.id

            local ok, err = xpcall(function()
                apps[b.id].run(context())
            end, debug.traceback)

            if not ok then
                local w, h = display.getSize()
                ui.clear(display)
                ui.header(display, 'App Error', 'TouchOS recovered')
                ui.text(display, 2, 5, ui.truncate(tostring(err), math.max(1, w - 3)), colors.red)
                ui.button(display, { x = 1, y = math.max(1, h - 2), w = w, h = 2, label = 'BACK TO HOME' }, true)
                input.pull()
            end

            buttons, pages = drawHome()
        else
            local w, h = display.getSize()
            local _, _, _, _, _, _, _, currentPages = layout()

            if currentPages > 1 and e.y >= h - 3 then
                local half = math.max(1, math.floor(w / 2))

                if e.x <= half and page > 1 then
                    page = page - 1
                    selected = (page - 1) * layout() + 1
                    buttons, pages = drawHome()
                elseif e.x > half and page < currentPages then
                    page = page + 1
                    selected = (page - 1) * layout() + 1
                    buttons, pages = drawHome()
                end
            end
        end

    elseif e.kind == 'move' and selected then
        local w, h, cols, rows, cellH, gap, pageSize, currentPages = layout()

        if e.dir == 'left' then
            selected = math.max(1, selected - 1)
        elseif e.dir == 'right' then
            selected = math.min(#apps, selected + 1)
        elseif e.dir == 'up' then
            selected = math.max(1, selected - cols)
        elseif e.dir == 'down' then
            selected = math.min(#apps, selected + cols)
        end

        local selectedPage = math.floor((selected - 1) / pageSize) + 1
        page = ui.clamp(selectedPage, 1, currentPages)
        buttons, pages = drawHome()

    elseif e.kind == 'activate' and selected and apps[selected] then
        pcall(apps[selected].run, context())
        buttons, pages = drawHome()
    end
end
