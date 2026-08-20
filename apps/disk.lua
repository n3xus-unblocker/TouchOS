local app={name='Disks',icon='Disk'}
function app.run(ctx)
 local d,u,i=ctx.disp,ctx.ui,ctx.input local drives={}
 local function scan() drives={} for _,s in ipairs(peripheral.getNames()) do if peripheral.getType(s)=='drive' then drives[#drives+1]=s end end end
 scan() local sel=1
 while true do local w,h=d.getSize() u.clear(d) u.center(d,1,1,w,'Disk Drives',u.theme.highlight) if #drives==0 then u.center(d,1,4,w,'No disk drives found',colors.red) else for n,s in ipairs(drives) do local p=peripheral.wrap(s) local has=p and p.isDisk and p.isDisk() local label=has and (p.getDiskLabel() or 'Unnamed disk') or 'Empty' local b={x=2,y=3+(n-1)*3,w=math.max(1,w-3),h=2,label=s..'  '..label} u.button(d,b,n==sel) end end local e=i.pull() if e.kind=='back' then return elseif e.kind=='move' then if e.dir=='up' then sel=u.clamp(sel-1,1,math.max(1,#drives)) elseif e.dir=='down' then sel=u.clamp(sel+1,1,math.max(1,#drives)) end elseif e.kind=='touch' then local n=math.floor((e.y-3)/3)+1 if drives[n] then sel=n e={kind='activate'} end end if e.kind=='activate' and drives[sel] then local p=peripheral.wrap(drives[sel]) if p and p.isDisk and p.isDisk() then if p.hasData() and p.getMountPath() then shell.run('ls',p.getMountPath()) else if p.eject then p.eject() end end else if p and p.insert then end end end end
end
return app
