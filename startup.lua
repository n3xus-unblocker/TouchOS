local ui=dofile('/os/ui.lua')
local input=dofile('/os/input.lua')
local keyboard=dofile('/os/keyboard.lua')
local SETTINGS='/os/settings.cfg'
local function load() if fs.exists(SETTINGS) then local f=fs.open(SETTINGS,'r') local t=textutils.unserialize(f.readAll()) f.close() if type(t)=='table' then return t end end return {textScale=1,screenMonitor=nil,keyboardMonitor=nil} end
local settings=load()
local function save(t) local f=fs.open(SETTINGS,'w') f.write(textutils.serialize(t)) f.close() end
local mons={} for _,s in ipairs(peripheral.getNames()) do if peripheral.getType(s)=='monitor' then mons[#mons+1]=s end end
local monitor=nil if settings.screenMonitor and peripheral.isPresent(settings.screenMonitor) and peripheral.getType(settings.screenMonitor)=='monitor' then monitor=peripheral.wrap(settings.screenMonitor) elseif #mons>0 then settings.screenMonitor=mons[1] monitor=peripheral.wrap(mons[1]) save(settings) end
local disp=monitor or term
if monitor and disp.setTextScale then pcall(disp.setTextScale,settings.textScale or 1) end
local keyboardMonitor=nil if settings.keyboardMonitor and peripheral.isPresent(settings.keyboardMonitor) and peripheral.getType(settings.keyboardMonitor)=='monitor' then keyboardMonitor=peripheral.wrap(settings.keyboardMonitor) end
if keyboardMonitor then local kw,kh=keyboardMonitor.getSize() if kw>=10 and kh>=4 then keyboard.draw(keyboardMonitor) else keyboardMonitor.setBackgroundColor(colors.black) keyboardMonitor.clear() end end
local function apps() local a={} if fs.exists('/apps') then for _,n in ipairs(fs.list('/apps')) do if n:match('%.lua$') then local ok,v=pcall(dofile,'/apps/'..n) if ok and type(v)=='table' and v.run then a[#a+1]=v end end end end return a end
local list=apps()
local function context() return {disp=disp,ui=ui,input=input,settings=settings,saveSettings=function(t) settings=t save(t) if keyboardMonitor then keyboard.draw(keyboardMonitor) end end} end
local function draw(sel) local w,h=disp.getSize() ui.clear(disp) ui.center(disp,1,1,w,'TouchOS',ui.theme.highlight) local cols=math.max(1,math.floor(w/14)) for n,a in ipairs(list) do local c=(n-1)%cols local r=math.floor((n-1)/cols) local y=3+r*4 if y+2<h then ui.button(disp,{x=1+c*14,y=y,w=12,h=3,label=a.icon or a.name},n==sel) end end end
local sel=#list>0 and 1 or nil
draw(sel)
while true do local e=input.pull() if e.kind=='resize' then draw(sel) elseif e.kind=='touch' then local w,h=disp.getSize() local cols=math.max(1,math.floor(w/14)) local c=math.floor((e.x-1)/14) local r=math.floor((e.y-3)/4) local n=r*cols+c+1 if list[n] and e.y>=3 then local ok,err=pcall(list[n].run,context()) if not ok then ui.clear(disp) ui.text(disp,1,1,'App error',colors.red) ui.text(disp,1,2,tostring(err):sub(1,math.max(1,w))) os.sleep(2) end draw(sel) end elseif e.kind=='move' and sel then local w=disp.getSize() local cols=math.max(1,math.floor(w/14)) if e.dir=='right' then sel=ui.clamp(sel+1,1,#list) elseif e.dir=='left' then sel=ui.clamp(sel-1,1,#list) elseif e.dir=='down' then sel=ui.clamp(sel+cols,1,#list) elseif e.dir=='up' then sel=ui.clamp(sel-cols,1,#list) end draw(sel) elseif e.kind=='activate' and sel then pcall(list[sel].run,context()) draw(sel) end end
