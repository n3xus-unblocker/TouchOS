local kb = {}

kb.rows = {
    {'Q','W','E','R','T','Y','U','I','O','P'},
    {'A','S','D','F','G','H','J','K','L'},
    {'Z','X','C','V','B','N','M'},
    {'SPACE','BACK','ENTER','CLEAR'}
}

local function metrics(m)
    local w,h = m.getSize()
    local gap = 1
    local top = 4
    local bottom = 1
    local availableH = math.max(1, h - top - bottom + 1)
    local rowH = math.max(1, math.floor((availableH - gap * (#kb.rows - 1)) / #kb.rows))
    return w,h,gap,rowH,top,bottom
end

function kb.isLargeEnough(m)
    if not m then return false end
    local w,h = m.getSize()
    return w >= 30 and h >= 12
end

function kb.draw(m)
    if not m or not kb.isLargeEnough(m) then return end

    local w,h,gap,rowH,startY,bottom = metrics(m)

    m.setBackgroundColor(colors.black)
    m.setTextColor(colors.white)
    m.clear()

    m.setBackgroundColor(colors.blue)
    m.setCursorPos(1,1)
    m.write(string.rep(' ', w))
    m.setCursorPos(1,2)
    m.write(string.rep(' ', w))
    m.setTextColor(colors.white)
    local title = 'TOUCH KEYBOARD'
    m.setCursorPos(math.max(1, math.floor((w - #title) / 2) + 1), 1)
    m.write(title)

    for r,row in ipairs(kb.rows) do
        local count = #row
        local keyW = math.max(3, math.floor((w - (count + 1) * gap) / count))
        local y = startY + (r - 1) * (rowH + gap)

        if y + rowH - 1 <= h - bottom then
            for c,label in ipairs(row) do
                local x = gap + (c - 1) * (keyW + gap)
                local ww = math.min(keyW, w - x + 1)

                if ww > 0 then
                    local bg = label == 'ENTER' and colors.cyan or colors.blue
                    m.setBackgroundColor(bg)
                    for yy = y, y + rowH - 1 do
                        m.setCursorPos(x, yy)
                        m.write(string.rep(' ', ww))
                    end

                    m.setTextColor(colors.white)
                    local shown = label
                    if #shown > ww then
                        shown = shown:sub(1, ww)
                    end
                    local tx = x + math.max(0, math.floor((ww - #shown) / 2))
                    local ty = y + math.floor((rowH - 1) / 2)
                    m.setCursorPos(tx, ty)
                    m.write(shown)
                end
            end
        end
    end
end

function kb.touch(m,x,y)
    if not m or not kb.isLargeEnough(m) then return nil end

    local w,h,gap,rowH,startY,bottom = metrics(m)
    if y < startY or y > h - bottom then return nil end

    local step = rowH + gap
    local rowNo = math.floor((y - startY) / step) + 1
    local row = kb.rows[rowNo]
    if not row then return nil end

    local rowY = startY + (rowNo - 1) * step
    if y < rowY or y >= rowY + rowH then return nil end

    local count = #row
    local keyW = math.max(3, math.floor((w - (count + 1) * gap) / count))
    local col = math.floor((x - gap) / (keyW + gap)) + 1
    local label = row[col]
    if not label then return nil end

    local keyX = gap + (col - 1) * (keyW + gap)
    if x < keyX or x >= keyX + keyW then return nil end

    if label == 'SPACE' then
        return {kind='char', char=' '}
    elseif label == 'BACK' then
        return {kind='backspace'}
    elseif label == 'ENTER' then
        return {kind='activate'}
    elseif label == 'CLEAR' then
        return {kind='clear'}
    else
        return {kind='char', char=label:lower()}
    end
end

return kb
