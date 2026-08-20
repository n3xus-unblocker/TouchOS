-- TouchOS Installer
-- WARNING: this performs a full filesystem wipe before installing TouchOS.
-- The installer itself may be deleted during the wipe, but it is already loaded
-- in memory by CC:Tweaked and can continue installing afterward.

local BASE = "https://raw.githubusercontent.com/n3xus-unblocker/TouchOS/main/"

local files = {
    "startup.lua",
    "os/ui.lua",
    "os/input.lua",
    "os/keyboard.lua",
    "apps/filemanager.lua",
    "apps/settings.lua",
    "apps/shell.lua",
    "apps/printer.lua",
    "apps/disk.lua",
    "apps/monitor.lua"
}

term.clear()
term.setCursorPos(1, 1)

print("TouchOS Installer")
print("")
print("WARNING: this will DELETE ALL FILES on this computer.")
print("This is a full reformat so old TouchOS files cannot interfere.")
print("")
print("Type WIPE to continue.")
write("> ")

if read() ~= "WIPE" then
    print("Cancelled")
    return
end

print("")
print("Reformatting filesystem...")

local all = fs.list("/")
for i = 1, #all do
    local path = "/" .. all[i]
    local ok, err = pcall(fs.delete, path)

    if ok then
        print("Deleted " .. path)
    else
        print("Could not delete " .. path .. ": " .. tostring(err))
    end
end

print("")
print("Filesystem cleared")
print("Installing fresh TouchOS files...")
print("")

local function ensureDir(path)
    local dir = fs.getDir(path)

    if dir ~= "" and not fs.exists(dir) then
        fs.makeDir(dir)
    end
end

local function install(path)
    local response, err = http.get(BASE .. path)

    if not response then
        return false, tostring(err or "HTTP request failed")
    end

    local data = response.readAll()
    response.close()

    local destination = "/" .. path
    ensureDir(destination)

    local file = fs.open(destination, "w")

    if not file then
        return false, "cannot write " .. destination
    end

    file.write(data)
    file.close()

    return true
end

local installed = 0

for _, path in ipairs(files) do
    write("Installing " .. path .. "... ")

    local ok, err = install(path)

    if ok then
        print("OK")
        installed = installed + 1
    else
        print("FAILED: " .. tostring(err))
    end
end

print("")
print(installed .. "/" .. #files .. " files installed")

if installed == #files then
    print("")
    print("TouchOS installation complete")
    print("The old filesystem was fully wiped before installation.")
    print("")
    print("Rebooting into TouchOS...")
    sleep(1)
    os.reboot()
else
    print("")
    print("Installation incomplete.")
    print("Fix the failed downloads and run the installer again.")
end
