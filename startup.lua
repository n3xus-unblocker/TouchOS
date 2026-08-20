local ui = dofile('/os/ui.lua')
local input = dofile('/os/input.lua')

local SETTINGS = '/os/settings.cfg'
local APPS = '/apps'

local function loadSettings()
    local defaults = { textScale = 1, screenMonitor = nil, keyboardMonitor = nil }
    if fs.exists(SETTINGS) then
        local f = fs.open(SETTINGS, 'r')
        if f then
            local ok, data = pcall(textutils.unserialize, f.readAll())
            f.close()
            if ok and type(data) == 'table' then
                for k, v in pairs(data) do defaults[k] = v end
            end
        end
    end
    return defaults
end

local settings = loadSettings()

local function saveSettings(s)
    local f = fs.open(SETTINGS, 'w')
    if f then
        f.write(textutils.serialize(s))
        f.close()
    end
end

local function getMonitors()
    local result = {}
    for _, name in ipairs(peripheral.getNames()) do
        if peripheral.getType(name) == 'monitor' then result[#result + 1] = name end
    end
    table.sort(result)
    return result
end

local function validMonitor(name)
    return name and peripheral.isPresent(name) and peripheral.getType(name) == 'monitor'
end

local function getDisplay()
    if validMonitor(settings.screenMonitor) then
        return peripheral.wrap(settings.screenMonitor)
    end
    local list = getMonitors()
    if #list > 0 then
        settings.screenMonitor = list[1]
        if settings.keyboardMonitor == settings.screenMonitor then settings.keyboardMonitor = nil end
        saveSettings(settings)
        return peripheral.wrap(list[1])
    end
    return term
end

local disp = getDisplay()
if disp.setTextScale then pcall(disp.setTextScale, settings.textScale or 1) end

local keyboardModule
pcall(function() keyboardModule = dofile('/os/keyboard.lua') end)

local function setupKeyboardMonitor()
    if not keyboardModule or not validMonitor(settings.keyboardMonitor) then return end
    if settings.keyboardMonitor == settings.screenMonitor then return end
    local m = peripheral.wrap(settings.keyboardMonitor)
    if keyboardModule.isLargeEnough and not keyboardModule.isLargeEnough(m) then return end
    if keyboardModule.draw then pcall(keyboardModule.draw, m) end
end

setupKeyboardMonitor()

local function builtinShell()
    local app = { name = 'Shell', icon = '>_' }
    function app.run(ctx)
        local d, u, inp = ctx.disp, ctx.ui, ctx.input
        local buffer = ''
        local output = { 'TouchOS Shell' }
        local function redraw()
            local w, h = d.getSize()
            u.clear(d)
            u.center(d, 1, 1, w, 'Shell', u.theme.highlight)
            local maxLines = math.max(1, h - 6)
            local first = math.max(1, #output - maxLines + 1)
            for n = first, #output do u.text(d, 1, n - first + 3, output[n]) end
            u.fill(d, 1, math.max(1, h - 3), w, math.min(3, h), u.theme.bgAlt)
            local inputY = math.max(1, h - 3)
            local buttonY = math.max(1, h - 2)
            u.text(d, 1, inputY, '> ' .. buffer)
            local bw = math.max(1, math.floor(w / 2))
            u.button(d, {x=1, y=buttonY, w=bw, h=2, label='Back'}, false)
            u.button(d, {x=bw+1, y=buttonY, w=w-bw, h=2, label='Run'}, false)
        end
        local function execute()
            if buffer == '' then return end
            local cmd = buffer
            buffer = ''
            output[#output + 1] = '> ' .. cmd
            local old = term.redirect(d)
            local ok, err = pcall(shell.run, cmd)
            term.redirect(old)
            if not ok then output[#output + 1] = 'Error: ' .. tostring(err) end
        end
        redraw()
        while true do
            local e = inp.pull()
            if e.kind == 'back' then return
            elseif e.kind == 'backspace' then buffer = buffer:sub(1, -2); redraw()
            elseif e.kind == 'char' then buffer = buffer .. e.char; redraw()
            elseif e.kind == 'paste' then buffer = buffer .. e.text; redraw()
            elseif e.kind == 'activate' then execute(); redraw()
            elseif e.kind == 'touch' then
                local w, h = d.getSize()
                if e.y >= h - 2 then
                    if e.x <= math.floor(w / 2) then return else execute(); redraw() end
                end
            elseif e.kind == 'resize' then redraw() end
        end
    end
    return app
end

local function loadApps()
    local apps = {}
    if not fs.exists(APPS) then fs.makeDir(APPS) end
    for _, file in ipairs(fs.list(APPS)) do
        if file:match('%.lua$') then
            local ok, app = pcall(dofile, fs.combine(APPS, file))
            if ok and type(app) == 'table' and type(app.run) == 'function' then apps[#apps + 1] = app end
        end
    end
    local hasShell = false
    for _, app in ipairs(apps) do if app.name == 'Shell' then hasShell = true break end end
    if not hasShell then apps[#apps + 1] = builtinShell() end
    table.sort(apps, function(a,b) return tostring(a.name) < tostring(b.name) end)
    return apps
end

local apps = loadApps()
local selected = #apps > 0 and 1 or nil

local function context()
    return {
        disp = disp,
        ui = ui,
        input = input,
        settings = settings,
        saveSettings = function(s)
            settings = s
            saveSettings(s)
            setupKeyboardMonitor()
        end
    }
end

local function buildButtons()
    local w, h = disp.getSize()
    local cols = math.max(1, math.min(4, math.floor((w + 1) / 14)))
    local gap = 1
    local cellW = math.max(8, math.floor((w - gap * (cols - 1)) / cols))
    local cellH = 4
    local buttons = {}
    for n, app in ipairs(apps) do
        local row = math.floor((n - 1) / cols)
        local col = (n - 1) % cols
        local y = 3 + row * (cellH + 1)
        if y + cellH - 1 <= h - 1 then
            buttons[#buttons + 1] = {
                x = 1 + col * (cellW + gap),
                y = y,
                w = cellW,
                h = cellH,
                label = tostring(app.name),
                id = n
            }
        end
    end
    return buttons
end

local function drawHome()
    local w = disp.getSize()
    ui.clear(disp)
    ui.center(disp, 1, 1, w, 'TouchOS', ui.theme.highlight)
    local buttons = buildButtons()
    for _, b in ipairs(buttons) do ui.button(disp, b, b.id == selected) end
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
                local w = disp.getSize()
                ui.clear(disp)
                ui.center(disp, 1, 2, w, 'APP ERROR', colors.red)
                ui.text(disp, 1, 4, tostring(err), colors.white)
                os.sleep(2)
            end
            buttons = drawHome()
        end
    elseif e.kind == 'move' and selected then
        local w = disp.getSize()
        local cols = math.max(1, math.min(4, math.floor((w + 1) / 14)))
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
