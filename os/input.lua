local input={}
local kb=pcall(dofile,'/os/keyboard.lua') and dofile('/os/keyboard.lua') or nil
local function keyboardSide()
 if not fs.exists('/os/settings.cfg') then return nil end local f=fs.open('/os/settings.cfg','r') if not f then return nil end local t=textutils.unserialize(f.readAll()) f.close() return type(t)=='table' and t.keyboardMonitor or nil
end
function input.pull()
 while true do
  local e={os.pullEvent()} local ev=e[1]
  if ev=='monitor_touch' then
   local side=keyboardSide()
   if side and e[2]==side and kb then local m=peripheral.wrap(side) local k=kb.touch(m,e[3],e[4]) if k then return k end
   else return {kind='touch',side=e[2],x=e[3],y=e[4]} end
  elseif ev=='key' then
   local k=e[2]
   if k==keys.up then return {kind='move',dir='up'} elseif k==keys.down then return {kind='move',dir='down'} elseif k==keys.left then return {kind='move',dir='left'} elseif k==keys.right then return {kind='move',dir='right'} elseif k==keys.enter or k==keys.space then return {kind='activate'} elseif k==keys.escape then return {kind='back'} elseif k==keys.backspace then return {kind='backspace'} else return {kind='key',key=k} end
  elseif ev=='char' then return {kind='char',char=e[2]}
  elseif ev=='paste' then return {kind='paste',text=e[2]}
  elseif ev=='monitor_resize' or ev=='term_resize' then return {kind='resize'}
  end
 end
end
return input
