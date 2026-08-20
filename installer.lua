-- TouchOS Setup v3
-- Downloads and validates the complete release before wiping the computer.
-- Then performs a clean install and reboots.

local BASE = 'https://raw.githubusercontent.com/n3xus-unblocker/TouchOS/main/'
local FILES = {
    'startup.lua',
    'os/ui.lua',
    'os/input.lua',
    'os/keyboard.lua',
    'apps/filemanager.lua',
    'apps/settings.lua',
    'apps/shell.lua',
    'apps/printer.lua',
    'apps/disk.lua',
    'apps/monitor.lua'
}

local PROTECTED = {
    disk = true,
    rom = true
}

local W, H = term.getSize()

local function clear(bg)
    term.setBackgroundColor(bg or colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
end

local function writeAt(x, y, text, fg, bg)
    text = tostring(text or ''):sub(1, math.max(0, W - x + 1))
    term.setCursorPos(x, y)
    if bg then term.setBackgroundColor(bg) end
    if fg then term.setTextColor(fg) end
    term.write(text)
end

local function centered(y, text, fg, bg)
    text = tostring(text or '')
    local x = math.max(1, math.floor((W - #text) / 2) + 1)
    writeAt(x, y, text, fg, bg)
end

local function header(title, subtitle)
    clear()
    term.setBackgroundColor(colors.blue)
    for y = 1, math.min(3, H) do
        term.setCursorPos(1, y)
        term.write(string.rep(' ', W))
    end
    centered(1, title, colors.white, colors.blue)
    if subtitle and H >= 2 then
        centered(2, subtitle, colors.lightBlue, colors.blue)
    end
    term.setBackgroundColor(colors.black)
end

local function bar(y, done, total, fg)
    if H < y then return end
    local width = math.max(1, W - 4)
    local filled = math.floor(width * done / math.max(1, total))
    writeAt(3, y, string.rep(' ', width), colors.white, colors.gray)
    if filled > 0 then
        writeAt(3, y, string.rep(' ', filled), colors.white, fg or colors.cyan)
    end
end

header('TouchOS Setup', 'Fresh install')
writeAt(2, 5, 'This installer performs a COMPLETE filesystem wipe.', colors.red)
writeAt(2, 6, 'The virtual /disk and /rom filesystems are protected.', colors.yellow)
writeAt(2, 8, 'Before wiping, TouchOS will download and validate', colors.white)
writeAt(2, 9, 'every release file so a network failure cannot leave', colors.white)
writeAt(2, 10, 'the computer half-installed.', colors.white)

if H >= 13 then
    centered(12, 'Type WIPE to continue', colors.white)
end
term.setCursorPos(2, math.min(H, 14))
term.setTextColor(colors.white)
term.write('> ')

if read() ~= 'WIPE' then
    clear()
    centered(math.max(1, math.floor(H / 2)), 'Installation cancelled', colors.yellow)
    return
end

header('TouchOS Setup', 'Downloading release')
writeAt(2, 5, 'Downloading and validating files before wipe...', colors.cyan)

local bundles = {}
local failed = {}

for i, path in ipairs(FILES) do
    local y = math.min(H - 3, 7 + ((i - 1) % math.max(1, H - 9)))
    writeAt(2, y, 'FETCH  ' .. path, colors.white, colors.black)

    local response, err = http.get(BASE .. path)

    if not response then
        failed[#failed + 1] = path .. ': ' .. tostring(err or 'HTTP error')
        writeAt(math.max(2, W - 7), y, 'FAILED', colors.red)
    else
        local data = response.readAll()
        response.close()

        if type(data) ~= 'string' or #data == 0 then
            failed[#failed + 1] = path .. ': empty response'
            writeAt(math.max(2, W - 7), y, 'FAILED', colors.red)
        else
            bundles[path] = data
            writeAt(math.max(2, W - 7), y, 'OK', colors.lime)
        end
    end

    bar(H - 2, i, #FILES, colors.cyan)
    writeAt(3, H - 1, 'Release check ' .. i .. '/' .. #FILES, colors.lightGray)
end

if #failed > 0 then
    header('TouchOS Setup', 'Download failed')
    writeAt(2, 5, 'Nothing was wiped.', colors.lime)
    writeAt(2, 7, 'Fix the following problems and rerun:', colors.yellow)
    local y = 8
    for _, err in ipairs(failed) do
        if y >= H then break end
        writeAt(2, y, err, colors.red)
        y = y + 1
    end
    return
end

header('TouchOS Setup', 'Reformatting')
writeAt(2, 5, 'Removing user files and old TouchOS files...', colors.red)
writeAt(2, 6, '/disk and /rom will be skipped.', colors.yellow)

local all = fs.list('/')
local deleteFailed = {}
local deleted = 0
local skipped = 0

for i, name in ipairs(all) do
    if PROTECTED[name] then
        skipped = skipped + 1
    else
        local ok, err = pcall(fs.delete, '/' .. name)
        if not ok then
            deleteFailed[#deleteFailed + 1] = '/' .. name .. ': ' .. tostring(err)
        else
            deleted = deleted + 1
        end
    end
    bar(H - 2, i, #all, colors.red)
end

if #deleteFailed > 0 then
    clear(colors.black)
    centered(3, 'WIPE FAILED', colors.red)
    writeAt(2, 5, 'Some files could not be deleted:', colors.yellow)
    local y = 6
    for _, err in ipairs(deleteFailed) do
        if y >= H then break end
        writeAt(2, y, err, colors.red)
        y = y + 1
    end
    return
end

pcall(fs.makeDir, '/os')
pcall(fs.makeDir, '/apps')

header('TouchOS Setup', 'Installing release')
writeAt(2, 5, 'Installing verified files...', colors.cyan)

local installed = 0
local writeFailed = {}

for i, path in ipairs(FILES) do
    local dir = fs.getDir('/' .. path)
    if dir ~= '' and not fs.exists(dir) then
        fs.makeDir(dir)
    end

    local file = fs.open('/' .. path, 'w')

    if not file then
        writeFailed[#writeFailed + 1] = path .. ': cannot open for writing'
    else
        local ok, err = pcall(function()
            file.write(bundles[path])
            file.close()
        end)

        if ok then
            installed = installed + 1
        else
            pcall(file.close)
            writeFailed[#writeFailed + 1] = path .. ': ' .. tostring(err)
        end
    end

    local y = 7 + ((i - 1) % math.max(1, H - 10))
    writeAt(2, y, 'INSTALL ' .. path, colors.white)
    writeAt(math.max(2, W - 2), y, 'OK', colors.lime)
    bar(H - 2, i, #FILES, colors.cyan)
end

if #writeFailed > 0 then
    clear()
    centered(3, 'INSTALL FAILED', colors.red)
    writeAt(2, 5, installed .. '/' .. #FILES .. ' files installed', colors.yellow)
    local y = 7
    for _, err in ipairs(writeFailed) do
        if y >= H then break end
        writeAt(2, y, err, colors.red)
        y = y + 1
    end
    return
end

clear()
centered(math.max(2, math.floor(H / 2) - 2), 'TOUCHOS', colors.cyan)
centered(math.max(3, math.floor(H / 2)), 'INSTALLATION COMPLETE', colors.lime)
centered(math.max(4, math.floor(H / 2) + 2), installed .. ' files installed', colors.white)
centered(math.max(5, math.floor(H / 2) + 4), 'Rebooting...', colors.lightBlue)
sleep(2)
os.reboot()
