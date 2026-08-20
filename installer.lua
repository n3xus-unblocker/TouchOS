-- TouchOS Setup v2
-- Full wipe + fresh install

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

local W, H = term.getSize()

local function clear()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1, 1)
end

local function title()
    clear()
    term.setBackgroundColor(colors.blue)
    term.setTextColor(colors.white)
    for y = 1, math.min(3, H) do
        term.setCursorPos(1, y)
        term.write(string.rep(' ', W))
    end
    term.setCursorPos(1, 1)
    local name = 'TouchOS Setup'
    term.setCursorPos(math.max(1, math.floor((W - #name) / 2) + 1), 1)
    term.write(name)
    term.setCursorPos(1, 2)
    term.write(string.rep(' ', W))
    term.setCursorPos(math.max(1, math.floor((W - 14) / 2) + 1), 2)
    term.write('Fresh Install')
    term.setBackgroundColor(colors.black)
    term.setCursorPos(1, 5)
end

local function line(text, color)
    term.setTextColor(color or colors.white)
    term.write(tostring(text):sub(1, W))
    term.setCursorPos(1, math.min(H, select(2, term.getCursorPos()) + 1))
end

local function progress(done, total)
    local width = math.max(10, W - 4)
    local filled = math.floor(width * done / math.max(1, total))
    term.setBackgroundColor(colors.gray)
    term.setCursorPos(3, H - 2)
    term.write(string.rep(' ', width))
    term.setBackgroundColor(colors.cyan)
    term.setCursorPos(3, H - 2)
    term.write(string.rep(' ', filled))
    term.setBackgroundColor(colors.black)
    term.setCursorPos(3, H - 1)
    term.setTextColor(colors.lightGray)
    term.write(done .. ' / ' .. total .. ' files')
end

title()
line('This will permanently delete every file on this computer.', colors.red)
line('Old TouchOS files will be removed before installation.', colors.yellow)
line('')
line('Type WIPE to continue.', colors.white)
term.write('> ')
if read() ~= 'WIPE' then
    line('Cancelled.', colors.yellow)
    return
end

clear()
line('Reformatting filesystem...', colors.cyan)
local all = fs.list('/')
for _, name in ipairs(all) do
    pcall(fs.delete, '/' .. name)
end

fs.makeDir('/os')
fs.makeDir('/apps')

clear()
line('Installing TouchOS', colors.cyan)
line('')

local installed = 0
local failed = {}

for i, path in ipairs(FILES) do
    term.setTextColor(colors.white)
    term.write('[' .. string.rep(' ', math.max(0, 12 - #path)) .. '] ' .. path)
    term.setCursorPos(1, math.min(H - 3, select(2, term.getCursorPos()) + 1))

    local response, err = http.get(BASE .. path)
    if not response then
        failed[#failed + 1] = path .. ': ' .. tostring(err or 'HTTP error')
        term.setTextColor(colors.red)
        term.write('FAILED')
    else
        local data = response.readAll()
        response.close()
        local file = fs.open('/' .. path, 'w')
        if not file then
            failed[#failed + 1] = path .. ': cannot write'
            term.setTextColor(colors.red)
            term.write('FAILED')
        else
            file.write(data)
            file.close()
            installed = installed + 1
            term.setTextColor(colors.lime)
            term.write('OK')
        end
    end

    progress(i, #FILES)
end

term.setBackgroundColor(colors.black)
term.setCursorPos(1, math.max(1, H - 6))
term.setTextColor(colors.white)

if #failed > 0 then
    line('')
    line('Installation failed.', colors.red)
    for _, err in ipairs(failed) do
        line(err, colors.red)
    end
    line('Fix networking or storage and rerun the installer.', colors.yellow)
    return
end

line('')
line('TouchOS installed successfully.', colors.lime)
line('10 core files installed.', colors.white)
line('Rebooting into TouchOS...', colors.cyan)
sleep(2)
os.reboot()
