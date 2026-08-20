local input={}
local keys=keys

-- Keep keyboard handling self contained so TouchOS can still boot even if
-- the optional keyboard module was not installed correctly.
local keyRows={
 {'q','w','e','r','t','y','u','i','o','p'},
 {'a','s','d','f','g','h','j','k','l'},
 {'z','x','c','v','b','n','m'},
 {'SPACE','BACK'}
}

local function keyboardTouch(m,x,y)
 if not m or y<1 or y>4 then return nil end
 local w=m.getSize()
 local keyW=math.max(3,math.floor(w/10)-1)
 local row=keyRows[y]
 if not row then return nil end
 local x0=1
 for _,label in ipairs(row) do
  local ww=label=='SPACE' and math.min(12,w-x0+1) or keyW
  if x>=x0 and x<x0+ww then
   if label=='SPACE' then return {kind='char',char=' '}
   elseif label=='BACK' then return {kind='back'}
   else return {kind='char',char=label} end
  end
  x0=x0+ww+1
 end
 return nil
end

local function keyboardSide()
 if not fs.exists('/os/settings.cfg') then return nil end
 local f=fs.open('/os/settings.cfg','r')
 if not f then return nil end
 local t=textutils.unserialize(f.readAll())
 f.close()
 return type(t)=='table' and t.keyboardMonitor or nil
end

function input.pull()
 local side=keyboardSide()
 while true do
  local e={os.pullEvent()}
  local ev=e[1]
  if ev=='monitor_touch' then
   if side and e[2]==side then
    local m=peripheral.wrap(side)
    local k=keyboardTouch(m,e[3],e[4])
    if k then return k end
   else
    return {kind='touch',side=e[2],x=e[3],y=e[4]}
   end
  elseif ev=='key' then
   local k=e[2]
   if k==keys.up or k==keys.down or k==keys.left or k==keys.right then
    local dirs={[keys.up]='up',[keys.down]='down',[keys.left]='left',[keys.right]='right'}
    return {kind='move',dir=dirs[k]}
   elseif k==keys.enter or k==keys.space then
    return {kind='activate'}
   elseif k==keys.backspace or k==keys.escape then
    return {kind='back'}
   else
    return {kind='key',key=k}
   end
  elseif ev=='char' then
   return {kind='char',char=e[2]}
  elseif ev=='monitor_resize' or ev=='term_resize' then
   return {kind='resize'}
  end
 end
end

return input
