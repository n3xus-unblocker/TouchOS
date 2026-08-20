local input={}
local keys=keys
local kb=dofile('/os/keyboard.lua')
local function keyboardSide() if not fs.exists('/os/settings.cfg') then return nil end local f=fs.open('/os/settings.cfg','r') local t=textutils.unserialize(f.readAll()) f.close() return type(t)=='table' and t.keyboardMonitor or nil end
function input.pull()
 local side=keyboardSide()
 while true do local e={os.pullEvent()} local ev=e[1]
  if ev=='monitor_touch' then
   if side and e[2]==side then local m=peripheral.wrap(side) local k=kb.touch(m,e[3],e[4]) if k then return k end else return {kind='touch',side=e[2],x=e[3],y=e[4]} end
  elseif ev=='key' then local k=e[2] if k==keys.up or k==keys.down or k==keys.left or k==keys.right then return {kind='move',dir=k} elseif k==keys.enter or k==keys.space then return {kind='activate'} elseif k==keys.backspace or k==keys.escape then return {kind='back'} else return {kind='key',key=k} end
  elseif ev=='char' then return {kind='char',char=e[2]} elseif ev=='monitor_resize' or ev=='term_resize' then return {kind='resize'} end
 end
end
return input
