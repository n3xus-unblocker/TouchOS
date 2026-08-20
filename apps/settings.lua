local app={name='Settings',icon='Set'}
function app.run(ctx)
 local d,u,i=ctx.disp,ctx.ui,ctx.input local s=ctx.settings local sel=1
 local function makeButtons()
  local w,h=d.getSize(); local bw=math.min(30,w-2); local x=math.floor((w-bw)/2)+1
  return {{x=x,y=7,w=bw,h=2,label='MONITOR SETUP',id='monitor'},{x=x,y=10,w=bw,h=2,label='SCALE +',id='up'},{x=x,y=13,w=bw,h=2,label='SCALE -',id='down'},{x=1,y=h-2,w=w,h=2,label='BACK',id='back'}}
 end
 local buttons
 local function draw()
  local w,h=d.getSize(); u.clear(d); u.header(d,'Settings','TouchOS configuration')
  u.text(d,2,4,'Screen: '..tostring(s.screenMonitor or 'auto'))
  u.text(d,2,5,'Keyboard: '..tostring(s.keyboardMonitor or 'off'))
  u.text(d,2,6,'Text scale: '..tostring(s.textScale or 1))
  buttons=makeButtons(); for n,b in ipairs(buttons) do u.button(d,b,n==sel) end
  u.status(d,'Tap a setting','SETTINGS')
 end
 draw()
 while true do
  local e=i.pull()
  if e.kind=='back' then return
  elseif e.kind=='resize' then draw()
  elseif e.kind=='move' then if e.dir=='down' or e.dir=='right' then sel=u.clamp(sel+1,1,#buttons) else sel=u.clamp(sel-1,1,#buttons) end; draw()
  elseif e.kind=='touch' then local _,n=u.hit(buttons,e.x,e.y); if n then sel=n; e={kind='activate'} end
  end
  if e.kind=='activate' then
   local id=buttons[sel].id
   if id=='back' then return
   elseif id=='monitor' then local ok,m=pcall(dofile,'/apps/monitor.lua'); if ok and m and m.run then m.run(ctx) end; draw()
   elseif id=='up' then s.textScale=math.min(5,(s.textScale or 1)+0.5); if d.setTextScale then pcall(d.setTextScale,s.textScale) end; ctx.saveSettings(s); draw()
   elseif id=='down' then s.textScale=math.max(0.5,(s.textScale or 1)-0.5); if d.setTextScale then pcall(d.setTextScale,s.textScale) end; ctx.saveSettings(s); draw() end
  end
 end
end
return app
