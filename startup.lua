local ui = dofile('/os/ui.lua')
local input = dofile('/os/input.lua')

local SETTINGS = '/os/settings.cfg'
local APPS = '/apps'

local function loadSettings()
    if fs.exists(SETTINGS) then
        local f = fs.open(SETTINGS, 'r')
        local ok, data = pcall(textutils.unserialize, f.readAll())
        f.close()
        if ok and type(data) == 'table' then return data end
    end
    return { textScale = 1, screenMonitor = nil, keyboardMonitor = nil }
end

local settings = loadSettings()
local function saveSettings(s)
    local f = fs.open(SETTINGS, 'w')
    f.write(textutils.serialize(s))
    f.close()
end

local function monitors()
    local result = {}
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == 'monitor' then table.insert(result, name) end
    end
    table.sort(result)
    return result
end

local function validMonitor(name)
    return name and peripheral.isPresent(name) and peripheral.getType(name) == 'monitor'
end

local function getDisplay()
    if validMonitor(settings.screenMonitor) then return peripheral.wrap(settings.screenMonitor) end
    local list = monitors()
    if #list > 0 then
        settings.screenMonitor = list[1]
        saveSettings(settings)
        return peripheral.wrap(list[1])
    end
    return term
end

local disp = getDisplay()
if disp.setTextScale then pcall(disp.setTextScale, settings.textScale or 1) end

local function builtinShell()
    return {
        name = 'Shell', icon = 'Shell',
        run = function(ctx)
            local d, u, inp = ctx.disp, ctx.ui, ctx.input
            local buffer = ''
            local output = { 'TouchOS Shell' }
            local function redraw()
                local w, h = d.getSize()
                u.clear(d)
                u.center(d, 1, 1, w, 'Shell', u.theme.highlight)
                local maxLines = math.max(1, h - 5)
                local first = math.max(1, #output - maxLines + 1)
                for n = first, #output do
                    u.text(d, 1, n - first + 3, output[n])
                end
                u.fill(d, 1, h - 2, w, 3, u.theme.bgAlt)
                local back = { x = 1, y = h - 2, w = math.floor(w / 2), h = 2, label = 'Back' }
                local run = { x = back.w + 1, y = h - 2, w = w - back.w, h = 2, label = 'Run' }
                u.button(d, back, false)
                u.button(d, run, false)
                u.text(d, 1, h, '> ' .. buffer)
            end
            local function execute()
                if buffer == '' then return end
                local cmd = buffer
                buffer = ''
                table.insert(output, '> ' .. cmd)
                local old = term.redirect(d)
                local ok, err = pcall(shell.run, cmd)
                term.redirect(old)
                if not ok then table.insert(output, 'Error: ' .. tostring(err)) end
            end
            redraw()
            while true do
                local e = inp.pull()
                if e.kind == 'back' then return end
                if e.kind == 'char' then buffer = buffer .. e.char; redraw()
                elseif e.kind == 'key' and e.key == keys.backspace then buffer = buffer:sub(1, -2); redraw()
                elseif e.kind == 'activate' then execute(); redraw()
                elseif e.kind == 'touch' then
                    local w, h = d.getSize()
                    if e.y >= h - 2 and e.x <= math.floor(w / 2) then return end
                    if e.y >= h - 2 then execute(); redraw() end
                elseif e.kind == 'resize' then redraw() end
            end
        end
    }
end

local function loadApps()
    local apps = {}
    if fs.exists(APPS) and fs.isDir(APPS) then
        for _, file in ipairs(fs.list(APPS)) do
            if file:match('%.lua$') then
                local ok, app = pcall(dofile, fs.combine(APPS, file))
                if ok and type(app) == 'table' and type(app.run) == 'function' then
                    table.insert(apps, app)
                end
            end
        end
    end
    local hasShell = false
    for _, app in ipairs(apps) do if app.name == 'Shell' then hasShell = true end end
    if not hasShell then table.insert(apps, builtinShell()) end
    table.sort(apps, function(a, b) return tostring(a.name) < tostring(b.name) end)
    return apps
end

local apps = loadApps()
local selected = #apps > 0 and 1 or nil

local function context()
    return {
        disp = disp, ui = ui, input = input, settings = settings,
        saveSettings = function(s)
            settings = s
            saveSettings(s)
        end
    }
end

local function buildButtons()
    local w, h = disp.getSize()
    local cols = math.max(1, math.floor(w / 16))
    local gap = 1
    local cellW = math.max(8, math.floor((w - gap * (cols - 1)) / cols))
    local cellH = 3
    local buttons = {}
    for n, app in ipairs(apps) do
        local row = math.floor((n - 1) / cols)
        local col = (n - 1) % cols
        local y = 3 + row * (cellH + 1)
        if y + cellH - 1 <= h - 1 then
            table.insert(buttons, { x = 1 + col * (cellW + gap), y = y, w = cellW, h = cellH, label = app.icon or app.name, id = n })
        end
    end
    return buttons
end

local function drawHome()
    local w, h = disp.getSize()
    ui.clear(disp)
    ui.center(disp, 1, 1, w, 'TouchOS', ui.theme.highlight)
    local buttons = buildButtons()
    for i, b in ipairs(buttons) do ui.button(disp, b, b.id == selected) end
    return buttons
end

local buttons = drawHome()
while true do
    local e = input.pull()
    if e.kind == 'resize' then
        buttons = drawHome()
    elseif e.kind == 'touch' then
        local b = ui.hit(buttons, e.x, e.y)
        if b then
            selected = b.id
            local ok, err = pcall(apps[b.id].run, context())
            if not ok then
                ui.clear(disp)
                local w = disp.getSize()
                ui.center(disp, 1, 2, w, 'App error', colors.red)
                ui.text(disp, 1, 4, tostring(err))
                os.sleep(2)
            end
            buttons = drawHome()
        end
    elseif e.kind == 'move' and selected then
        local w = disp.getSize()
        local cols = math.max(1, math.floor(w / 16))
        if e.dir == 'left' then selected = math.max(1, selected - 1)
        elseif e.dir == 'right' then selected = math.min(#apps, selected + 1)
        elseif e.dir == 'up' then selected = math.max(1, selected - cols)
        elseif e.dir == 'down' then selected = math.min(#apps, selected + cols) end
        buttons = drawHome()
    elseif e.kind == 'activate' and selected and apps[selected] then
        pcall(apps[selected].run, context())
        buttons = drawHome()
    end
end
