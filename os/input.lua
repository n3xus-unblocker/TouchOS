local input={}
local keys={up='up',down='down',left='left',right='right'}
local function settingsPath() return '/os/settings.cfg' end
local function keyboardSide()
 if not fs.exists(settingsPath()) then return nil end
 local f=fs.open(settingsPath(),'r') local t=textutils.unserialize(f.readAll()) f.close()
 return type(t)=='table' and t.keyboardMonitor or nil
end
function input.pull()
 local kside=keyboardSide()
 while true do
  local e={os.pullEvent()}
  if e[1]=='monitor_touch' then
   if kside and e[2]==kside then return {kind='keyboardTouch',x=e[3],y=e[4]} end
   return {kind='touch',side=e[2],x=e[3],y=e[4]}
  elseif e[1]=='key' then
   local k=e[2]
   if k==keys.up or k==keys.down or k==keys.left or k==keys.right then return {kind='move',dir=k}
   elseif k==keys.enter or k==keys.space then return {kind='activate'}
   elseif k==keys.backspace or k==keys.escape then return {kind='back'}
   else return {kind='key',key=k} end
  elseif e[1]=='char' then return {kind='char',char=e[2]}
  elseif e[1]=='monitor_resize' or e[1]=='term_resize' then return {kind='resize'}
  end
 end
end
return input
