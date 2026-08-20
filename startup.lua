local ui=dofile('/os/ui.lua')
local input=dofile('/os/input.lua')
local keyboard=dofile('/os/keyboard.lua')
local SETTINGS='/os/settings.cfg'
local function loadSettings()
 if fs.exists(SETTINGS) then local f=fs.open(SETTINGS,'r') local t=textutils.unserialize(f.readAll()) f.close() if type(t)=='table' then return t end end
 return {textScale=1,screenMonitor=nil,keyboardMonitor=nil}
end
local settings=loadSettings()
local function saveSettings(t) local f=fs.open(SETTINGS,'w') f.write(textutils.serialize(t)) f.close() end
local function getMonitors() local out={} for _,name in ipairs(peripheral.getNames()) do if peripheral.getType(name)=='monitor' then out[#out+1]=name end end table.sort(out) return out end
local mons=getMonitors()
local function validMonitor(name) return name and peripheral.isPresent(name) and peripheral.getType(name)=='monitor' end
local monitor=validMonitor(settings.screenMonitor) and peripheral.wrap(settings.screenMonitor) or nil
if not monitor and #mons>0 then settings.screenMonitor=mons[1] monitor=peripheral.wrap(mons[1]) saveSettings(settings) end
local disp=monitor or term
if monitor and disp.setTextScale then pcall(disp.setTextScale,settings.textScale or 1) end
local keyboardMonitor=nil
if validMonitor(settings.keyboardMonitor) and settings.keyboardMonitor~=settings.screenMonitor then keyboardMonitor=peripheral.wrap(settings.keyboardMonitor) end
if keyboardMonitor and keyboard.isLargeEnough(keyboardMonitor) then keyboard.draw(keyboardMonitor) else keyboardMonitor=nil end
local function builtinShell(ctx)
 local app={name='Shell',icon='>_'}
 function app.run(c)
  local d,u,i=c.disp,c.ui,c.input local buf='' local lines={'TouchOS Shell'}
  local function draw() local w,h=d.getSize() u.clear(d) u.text(d,1,1,'Shell',u.theme.highlight) local max=math.max(1,h-5) local start=math.max(1,#lines-max+1) for n=start,#lines do u.text(d,1,n-start+3,tostring(lines[n]):sub(1,w)) end local back={x=1,y=h-2,w=math.max(1,math.floor(w/3)),h=2,label='Back'} local run={x=math.floor(w/3)+1,y=h-2,w=math.floor(w/3),h=2,label='Run'} u.button(d,back,false) u.button(d,run,false) u.fill(d,1,h,w,1,u.theme.bg) u.text(d,1,h,'> '..buf:sub(1,math.max(0,w-2))) end
  local function run() local cmd=buf buf='' if cmd~='' then lines[#lines+1]='> '..cmd local old=term.redirect(d) local ok,err=pcall(shell.run,cmd) term.redirect(old) if not ok then lines[#lines+1]='Error: '..tostring(err) end end draw()
  while true do local e=i.pull() if e.kind=='back' then return elseif e.kind=='backspace' then buf=buf:sub(1,-2) draw() elseif e.kind=='char' then buf=buf..e.char draw() elseif e.kind=='paste' then buf=buf..e.text draw() elseif e.kind=='activate' then run() draw() elseif e.kind=='touch' then local w,h=d.getSize() if e.y>=h-2 and e.x<=math.floor(w/3) then return elseif e.y>=h-2 then run() draw() end elseif e.kind=='resize' then draw() end end
 end
 return app
end
local function loadApps()
 local apps={}
 if fs.exists('/apps') and fs.isDir('/apps') then
  for _,name in ipairs(fs.list('/apps')) do
   if name:match('%.lua$') then local ok,app=pcall(dofile,'/apps/'..name) if ok and type(app)=='table' and type(app.run)=='function' then apps[#apps+1]=app end end
  end
 end
 local hasShell=false for _,a in ipairs(apps) do if a.name=='Shell' then hasShell=true end end if not hasShell then apps[#apps+1]=builtinShell({}) end
 table.sort(apps,function(a,b) return tostring(a.name)<tostring(b.name) end) return apps
end
local apps=loadApps()
local function context() return {disp=disp,ui=ui,input=input,settings=settings,saveSettings=function(t) settings=t saveSettings(t) if keyboardMonitor and keyboard.isLargeEnough(keyboardMonitor) then keyboard.draw(keyboardMonitor) end end} end
local function draw(selected)
 local w,h=disp.getSize() ui.clear(disp) ui.center(disp,1,1,w,'TouchOS',ui.theme.highlight)
 local cols=math.max(1,math.floor(w/18)) local cellW=math.max(12,math.floor((w-(cols-1)*2)/cols)) local cellH=3 local gap=2
 local maxRows=math.max(1,math.floor((h-3)/4))
 for n,a in ipairs(apps) do local c=(n-1)%cols local r=math.floor((n-1)/cols) if r<maxRows then local x=1+c*(cellW+gap) local y=3+r*4 if x+cellW-1<=w then ui.button(d,{x=x,y=y,w=cellW,h=cellH,label=tostring(a.icon or a.name)},n==selected) end end end
end
local selected=#apps>0 and 1 or nil
draw(selected)
while true do
 local e=input.pull()
 if e.kind=='resize' then draw(selected)
 elseif e.kind=='touch' and selected then local w,h=disp.getSize() local cols=math.max(1,math.floor(w/18)) local cellW=math.max(12,math.floor((w-(cols-1)*2)/cols)) local gap=2 local row=math.floor((e.y-3)/4) local col=math.floor((e.x-1)/(cellW+gap)) local n=row*cols+col+1 if e.y>=3 and n>=1 and n<=#apps then selected=n local ok,err=pcall(apps[n].run,context()) if not ok then ui.clear(disp) ui.center(disp,1,2,w,'App error',colors.red) ui.text(disp,1,4,tostring(err):sub(1,w)) os.sleep(2) end draw(selected) end
 elseif e.kind=='move' and selected then local w=disp.getSize() local cols=math.max(1,math.floor(w/18)) if e.dir=='right' then selected=ui.clamp(selected+1,1,#apps) elseif e.dir=='left' then selected=ui.clamp(selected-1,1,#apps) elseif e.dir=='down' then selected=ui.clamp(selected+cols,1,#apps) elseif e.dir=='up' then selected=ui.clamp(selected-cols,1,#apps) end draw(selected)
 elseif e.kind=='activate' and selected then pcall(apps[selected].run,context()) draw(selected)
 end
end
