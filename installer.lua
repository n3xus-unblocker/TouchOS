-- TouchOS Fresh Installer
-- WARNING: wipes the computer before installing TouchOS.
local BASE = 'https://raw.githubusercontent.com/n3xus-unblocker/TouchOS/main/'
local FILES = {'startup.lua','os/ui.lua','os/input.lua','os/keyboard.lua','apps/filemanager.lua','apps/settings.lua','apps/shell.lua','apps/printer.lua','apps/disk.lua','apps/monitor.lua'}
term.clear(); term.setCursorPos(1,1)
print('TouchOS Fresh Installer')
print('')
print('THIS WILL DELETE ALL FILES ON THIS COMPUTER')
print('All old TouchOS files will be removed.')
print('')
print('Type WIPE to continue')
write('> ')
if read() ~= 'WIPE' then print('Cancelled'); return end
print(''); print('Wiping filesystem...')
for _, name in ipairs(fs.list('/')) do
  local ok, err = pcall(fs.delete, '/' .. name)
  if ok then print('Deleted /' .. name) else print('Could not delete /' .. name .. ': ' .. tostring(err)) end
end
fs.makeDir('/os'); fs.makeDir('/apps')
print(''); print('Installing fresh TouchOS...'); print('')
local installed, failed = 0, {}
for _, path in ipairs(FILES) do
  write('  ' .. path .. ' ... ')
  local response, err = http.get(BASE .. path)
  if not response then
    print('FAILED'); failed[#failed+1] = path .. ': ' .. tostring(err or 'HTTP error')
  else
    local data = response.readAll(); response.close()
    local f = fs.open('/' .. path, 'w')
    if not f then print('FAILED'); failed[#failed+1] = path .. ': cannot write'
    else f.write(data); f.close(); print('OK'); installed = installed + 1 end
  end
end
print(''); print(installed .. '/' .. #FILES .. ' files installed')
if #failed > 0 then
  print('INSTALL FAILED')
  for _, err in ipairs(failed) do print('  ' .. err) end
  return
end
print(''); print('TouchOS installed successfully'); print('Rebooting...'); sleep(1); os.reboot()
