local app={name='Monitor Setup',icon='Monitor'}
function app.run(ctx)
 local d,u,i=ctx.disp,ctx.ui,ctx.input local s=ctx.settings local mons={} local mode='screen' local sel=1
 local function scan() mons={} for _,side in ipairs(peripheral.getNames()) do if peripheral.getType(side)=='monitor' then local m=peripheral.wrap(side) local w,h=m.getSize() mons[#mons+1]={side=side,w=w,h=h} end end end
 local function draw()
  scan() local w,h=d.getSize() u.clear(d) u.center(d,1,1,w,'Monitor Setup',u.theme.highlight)
  local tw=math.max(10,math.min(20,w-4))
  u.button(d,{x=2,y=3,w=tw,h=2,label=mode=='screen' and 'Choose Screen' or 'Choose Keyboard'},false)
  u.text(d,2,6,'Touch a monitor below',u.theme.muted)
  for n,m in ipairs(mons) do local y=8+(n-1)*3 if y+1<=h then local valid=m.w>=10 and m.h>=4 local same=(m.side==s.screenMonitor) local mark=(mode=='screen' and s.screenMonitor==m.side) or (mode=='keyboard' and s.keyboardMonitor==m.side) local label=m.side..' '..m.w..'x'..m.h if mode=='keyboard' and (not valid or same) then label=label..' unavailable' end u.button(d,{x=2,y=y,w=tw,h=2,label=(mark and '[X] ' or '[ ] ')..label},n==sel) end end
 end
 draw()
 while true do
  local e=i.pull()
  if e.kind=='back' then return
  elseif e.kind=='resize' then draw()
  elseif e.kind=='move' then if e.dir=='up' then sel=u.clamp(sel-1,1,#mons) elseif e.dir=='down' then sel=u.clamp(sel+1,1,#mons) end draw()
  elseif e.kind=='touch' then
   if e.y>=3 and e.y<5 then mode=mode=='screen' and 'keyboard' or 'screen' draw()
   else local n=math.floor((e.y-8)/3)+1 if mons[n] then sel=n local m=mons[n] if mode=='screen' then s.screenMonitor=m.side ctx.saveSettings(s) elseif m.w>=10 and m.h>=4 and m.side~=s.screenMonitor then s.keyboardMonitor=m.side ctx.saveSettings(s) end draw() end end
  end
 end
end
return app
