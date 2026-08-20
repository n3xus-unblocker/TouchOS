-- TouchOS installer
local BASE = "https://raw.githubusercontent.com/n3xus-unblocker/TouchOS/main/"
local files = {"startup.lua","os/ui.lua","os/input.lua","os/keyboard.lua","apps/filemanager.lua","apps/settings.lua","apps/shell.lua","apps/printer.lua","apps/disk.lua","apps/monitor.lua"}
local function ensureDir(path) local dir=fs.getDir(path) if dir~="" and not fs.exists(dir) then fs.makeDir(dir) end end
local function install(path)
 local r,err=http.get(BASE..path) if not r then return false,tostring(err or "HTTP request failed") end
 local data=r.readAll() r.close() local dst="/"..path ensureDir(dst)
 if fs.exists(dst) then fs.delete(dst..".bak") fs.copy(dst,dst..".bak") end
 local f=fs.open(dst,"w") if not f then return false,"cannot write "..dst end f.write(data) f.close() return true
end
term.clear() term.setCursorPos(1,1) print("TouchOS Installer") print("GitHub: n3xus-unblocker/TouchOS") print("")
write("Continue? [y/n] ") if read():lower()~="y" then print("Cancelled") return end
local count=0
for _,path in ipairs(files) do write("Downloading "..path.."... ") local ok,err=install(path) if ok then print("OK") count=count+1 else print("FAILED: "..err) end end
print("") print(count.."/"..#files.." files installed")
if count==#files then write("Reboot now? [y/n] ") if read():lower()=="y" then os.reboot() end else print("Some files failed. Run the installer again.") end
