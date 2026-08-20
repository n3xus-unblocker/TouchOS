local app={name='Monitors',icon='Monitor'}
function app.run(ctx)
 local d,u,i=ctx.disp,ctx.ui,ctx.input local s=ctx.settings local mons={}
 local function scan() mons={} for _,side in ipairs(peripheral.getNames()) do if peripheral.getType(side)=='monitor' then local m=peripheral.wrap(side) local w,h=m.getSize() mons[#mons+1]={side=side,w=w,h=h} end end end
 local function save() ctx.saveSettings(s) end
 scan() local mode='screen' local sel=1
 while true do local w,h=d.getSize() u.clear(d) u.center(d,1,1,w,'Monitor Setup',u.theme.highlight) u.text(d,2,3,'Select: '..mode) local toggle={x=2,y=5,w=12,h=2,label=mode=='screen' and 'Screen' or 'Keyboard'} u.button(d,toggle,false)
 for n,m in ipairs(mons) do local y=8+(n-1)*3 if y+1<=h then local valid=m.h>=4 and m.w>=10 local mark=(mode=='screen' and s.screenMonitor==m.side) or (mode=='keyboard' and s.keyboardMonitor==m.side) local label=m.side..' '..m.w..'x'..m.h if mode=='keyboard' and not valid then label=label..' too small' end u.button(d,{x=2,y=y,w=math.max(1,w-3),h=2,label=(mark and '* ' or '')..label},n==sel) end end
 local e=i.pull() if e.kind=='back' then return elseif e.kind=='move' then if e.dir=='up' then sel=u.clamp(sel-1,1,#mons) elseif e.dir=='down' then sel=u.clamp(sel+1,1,#mons) end elseif e.kind=='touch' then if e.y>=5 and e.y<7 then mode=mode=='screen' and 'keyboard' or 'screen' else local n=math.floor((e.y-8)/3)+1 if mons[n] then sel=n e={kind='activate'} end end end if e.kind=='activate' and mons[sel] then local m=mons[sel] if mode=='screen' then s.screenMonitor=m.side save() elseif m.w>=10 and m.h>=4 then s.keyboardMonitor=m.side save() end end end
end
return app
