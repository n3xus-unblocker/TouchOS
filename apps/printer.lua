local app = { name = 'Printer', icon = 'Print' }

function app.run(ctx)
    local d, u, input = ctx.disp, ctx.ui, ctx.input
    local printer = peripheral.find('printer')
    local text = ''
    local status = printer and 'Printer ready' or 'No printer connected'

    local function draw()
        local w, h = d.getSize()
        u.clear(d)
        u.header(d, 'Printer', 'Print text to paper')

        local panelH = math.max(3, h - 10)
        u.panel(d, 2, 5, math.max(1, w - 2), panelH, u.theme.surface)
        u.text(d, 2, 4, u.truncate(status, math.max(1, w - 2)),
            status:find('No printer') and u.theme.danger or u.theme.success)

        local line = 1
        for s in (text .. '\n'):gmatch('(.-)\n') do
            if line > panelH then break end
            u.text(d, 3, 4 + line, u.truncate(s, math.max(1, w - 5)), u.theme.fg, u.theme.surface)
            line = line + 1
        end

        local y = math.max(1, h - 3)
        local bw = math.max(1, math.floor(w / 3))
        u.button(d, { x = 1, y = y, w = bw, h = 2, label = 'PRINT' }, false)
        u.button(d, { x = bw + 1, y = y, w = bw, h = 2, label = 'CLEAR' }, false)
        u.button(d, { x = bw * 2 + 1, y = y, w = w - bw * 2, h = 2, label = 'BACK' }, false)
        u.status(d, 'Type or paste text', 'PRINTER')
    end

    local function printText()
        if not printer then
            status = 'No printer connected'
            return
        end
        if text == '' then
            status = 'Nothing to print'
            return
        end

        local ok, err = pcall(function()
            printer.newPage()
            printer.setPageTitle('TouchOS')
            for line in (text .. '\n'):gmatch('(.-)\n') do
                printer.write(line)
            end
            printer.endPage()
        end)

        if ok then
            text = ''
            status = 'Printed successfully'
        else
            status = 'Print failed: ' .. tostring(err)
        end
    end

    draw()

    while true do
        local e = input.pull()

        if e.kind == 'back' then
            return
        elseif e.kind == 'backspace' then
            text = text:sub(1, -2)
            draw()
        elseif e.kind == 'char' then
            text = text .. e.char
            draw()
        elseif e.kind == 'paste' then
            text = text .. e.text
            draw()
        elseif e.kind == 'resize' then
            draw()
        elseif e.kind == 'touch' then
            local w, h = d.getSize()
            local y = math.max(1, h - 3)
            local bw = math.max(1, math.floor(w / 3))

            if e.y >= y then
                if e.x <= bw then
                    printText()
                elseif e.x <= bw * 2 then
                    text = ''
                    status = 'Cleared'
                else
                    return
                end
                draw()
            end
        elseif e.kind == 'activate' then
            printText()
            draw()
        end
    end
end

return app
