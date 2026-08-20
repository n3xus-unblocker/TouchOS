local app={name='Settings',icon='Settings'}
function app.run(ctx)
 local d,u,i=ctx.disp,ctx.ui,ctx.input local s=ctx.settings local sel=1
 local function buttons() local w,h=d.getSize() local bw=math.min(28,w-2) local x=math.max(1,math.floor((w-bw)/2)+1) return {{x=x,y=7,w=bw,h=2,label='Monitor Setup',id='monitor'},{x=x,y=10,w=bw,h=2,label='Scale +',id='up'},{x=x,y=13,w=bw,h=2,label='Scale -',id='down'},{x=1,y=math.max(1,h-2),w=w,h=2,label='Back',id='back'}} end
 local bs
 local function draw() local w,h=d.getSize() u.clear(d) u.center(d,1,1,w,'Settings',u.theme.highlight) u.text(d,2,3,'Screen: '..tostring(s.screenMonitor or 'auto')) u.text(d,2,4,'Keyboard: '..tostring(s.keyboardMonitor or 'off')) u.text(d,2,5,'Scale: '..tostring(s.textScale or 1)) bs=buttons() for n,b in ipairs(bs) do u.button(d,b,n==sel) end end
 draw()
 while true do local e=i.pull() if e.kind=='back' then return elseif e.kind=='resize' then draw() elseif e.kind=='move' then if e.dir=='down' or e.dir=='right' then sel=u.clamp(sel+1,1,#bs) elseif e.dir=='up' or e.dir=='left' then sel=u.clamp(sel-1,1,#bs) end draw() elseif e.kind=='touch' then local _,n=u.hit(bs,e.x,e.y) if n then sel=n e={kind='activate'} end end if e.kind=='activate' then local b=bs[sel] if b.id=='back' then return elseif b.id=='monitor' then local ok,a=pcall(dofile,'/apps/monitor.lua') if ok and a and a.run then a.run(ctx) end draw() elseif b.id=='up' then s.textScale=math.min(5,(s.textScale or 1)+.5) if d.setTextScale then d.setTextScale(s.textScale) end ctx.saveSettings(s) draw() elseif b.id=='down' then s.textScale=math.max(.5,(s.textScale or 1)-.5) if d.setTextScale then d.setTextScale(s.textScale) end ctx.saveSettings(s) draw() end end end
end
return app
