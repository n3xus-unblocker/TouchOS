local ui=dofile('/os/ui.lua')
local input=dofile('/os/input.lua')
local SETTINGS='/os/settings.cfg'
local function load() if fs.exists(SETTINGS) then local f=fs.open(SETTINGS,'r') local t=textutils.unserialize(f.readAll()) f.close() if type(t)=='table' then return t end end return {textScale=1,screenMonitor=nil,keyboardMonitor=nil} end
local settings=load()
local function save(t) local f=fs.open(SETTINGS,'w') f.write(textutils.serialize(t)) f.close() end
local function monitors() local out={} for _,s in ipairs(peripheral.getNames()) do if peripheral.getType(s)=='monitor' then table.insert(out,s) end end return out end
local mons=monitors()
local monitor=nil
if settings.screenMonitor and peripheral.isPresent(settings.screenMonitor) and peripheral.getType(settings.screenMonitor)=='monitor' then monitor=peripheral.wrap(settings.screenMonitor) elseif #mons>0 then monitor=peripheral.wrap(mons[1]) settings.screenMonitor=mons[1] save(settings) end
local disp=monitor or term
if monitor and disp.setTextScale then pcall(disp.setTextScale,settings.textScale or 1) end
local function apps()
 local a={} if fs.exists('/apps') then for _,n in ipairs(fs.list('/apps')) do if n:match('%.lua$') then local ok,v=pcall(dofile,'/apps/'..n) if ok and type(v)=='table' and v.run then table.insert(a,v) end end end end return a
end
local list=apps()
local function draw(sel)
 local w,h=disp.getSize() ui.clear(disp) ui.center(disp,1,1,w,'TouchOS',ui.theme.highlight)
 local cols=math.max(1,math.floor(w/14)) local bw=12 local bh=3 local gap=1
 for i,a in ipairs(list) do local c=(i-1)%cols local r=math.floor((i-1)/cols) local b={x=1+c*14,y=3+r*4,w=bw,h=bh,label=a.icon or a.name} if b.y+bh-1<h then ui.button(disp,b,i==sel) end end
end
local sel=#list>0 and 1 or nil
draw(sel)
while true do
 local e=input.pull()
 if e.kind=='resize' then draw(sel)
 elseif e.kind=='touch' then
  local w,h=disp.getSize() local cols=math.max(1,math.floor(w/14)) local c=math.floor((e.x-1)/14) local r=math.floor((e.y-3)/4) local i=r*cols+c+1 if list[i] and e.y>=3 then local ok,err=pcall(list[i].run,{disp=disp,ui=ui,input=input,settings=settings,saveSettings=function(t) settings=t save(t) end}) if not ok then ui.clear(disp) ui.text(disp,1,1,'App error',colors.red) ui.text(disp,1,2,tostring(err):sub(1,math.max(1,w))) os.sleep(2) end draw(sel) end
 elseif e.kind=='move' and sel then local w,h=disp.getSize() local cols=math.max(1,math.floor(w/14)) if e.dir=='right' then sel=ui.clamp(sel+1,1,#list) elseif e.dir=='left' then sel=ui.clamp(sel-1,1,#list) elseif e.dir=='down' then sel=ui.clamp(sel+cols,1,#list) elseif e.dir=='up' then sel=ui.clamp(sel-cols,1,#list) end draw(sel)
 elseif e.kind=='activate' and sel then pcall(list[sel].run,{disp=disp,ui=ui,input=input,settings=settings,saveSettings=function(t) settings=t save(t) end}) draw(sel) end
end
