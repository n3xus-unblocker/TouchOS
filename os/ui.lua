local ui = {}

ui.theme = {
    bg = colors.black,
    surface = colors.gray,
    surface2 = colors.lightGray,
    fg = colors.white,
    muted = colors.lightGray,
    accent = colors.blue,
    accent2 = colors.cyan,
    selected = colors.cyan,
    danger = colors.red,
    success = colors.lime,
    warning = colors.yellow
}

function ui.clear(d, bg)
    d.setBackgroundColor(bg or ui.theme.bg)
    d.setTextColor(ui.theme.fg)
    d.clear()
    d.setCursorPos(1, 1)
end

function ui.fill(d, x, y, w, h, bg)
    if w <= 0 or h <= 0 then return end
    d.setBackgroundColor(bg or ui.theme.bg)
    for row = y, y + h - 1 do
        d.setCursorPos(x, row)
        d.write(string.rep(' ', w))
    end
end

function ui.text(d, x, y, text, fg, bg)
    local w, h = d.getSize()
    if y < 1 or y > h or x > w then return end
    text = tostring(text or '')
    if bg then d.setBackgroundColor(bg) end
    if fg then d.setTextColor(fg) end
    d.setCursorPos(math.max(1, x), y)
    d.write(text:sub(1, math.max(0, w - x + 1)))
end

function ui.truncate(text, width)
    text = tostring(text or '')
    if width <= 0 then return '' end
    if #text <= width then return text end
    if width == 1 then return '~' end
    return text:sub(1, width - 1) .. '~'
end

function ui.center(d, x, y, w, text, fg, bg)
    text = ui.truncate(text, w)
    local px = x + math.max(0, math.floor((w - #text) / 2))
    ui.text(d, px, y, text, fg, bg)
end

function ui.header(d, title, subtitle)
    local w = d.getSize()
    ui.fill(d, 1, 1, w, 3, ui.theme.accent)
    ui.center(d, 1, 1, w, title, colors.white, ui.theme.accent)
    if subtitle then
        ui.center(d, 1, 2, w, subtitle, colors.lightBlue, ui.theme.accent)
    end
end

function ui.panel(d, x, y, w, h, bg)
    ui.fill(d, x, y, w, h, bg or ui.theme.surface)
end

function ui.button(d, b, selected, disabled)
    local bg
    local fg
    if disabled then
        bg = colors.gray
        fg = ui.theme.muted
    elseif selected then
        bg = ui.theme.selected
        fg = colors.black
    else
        bg = ui.theme.surface
        fg = colors.white
    end
    ui.fill(d, b.x, b.y, b.w, b.h, bg)
    local label = ui.truncate(b.label or '', b.w)
    ui.center(d, b.x, b.y + math.floor((b.h - 1) / 2), b.w, label, fg, bg)
end

function ui.hit(buttons, x, y)
    for i, b in ipairs(buttons) do
        if x >= b.x and x < b.x + b.w and y >= b.y and y < b.y + b.h then
            return b, i
        end
    end
    return nil
end

function ui.status(d, left, right)
    local w, h = d.getSize()
    if h < 1 then return end
    ui.fill(d, 1, h, w, 1, ui.theme.surface)
    right = right or ''
    local available = math.max(0, w - #right - 1)
    ui.text(d, 1, h, ui.truncate(left or '', available), ui.theme.fg, ui.theme.surface)
    if #right > 0 and #right <= w then
        ui.text(d, w - #right + 1, h, right, ui.theme.muted, ui.theme.surface)
    end
end

function ui.backButton(d, y)
    local w = d.getSize()
    return { x = 1, y = y, w = w, h = 2, label = 'BACK', id = 'back' }
end

function ui.listRow(d, x, y, w, label, selected)
    local bg = selected and ui.theme.selected or ui.theme.bg
    local fg = selected and colors.black or ui.theme.fg
    ui.fill(d, x, y, w, 1, bg)
    ui.text(d, x + 1, y, ui.truncate(label, math.max(0, w - 2)), fg, bg)
end

function ui.clamp(n, lo, hi)
    if hi < lo then return lo end
    return math.max(lo, math.min(hi, n))
end

return ui
