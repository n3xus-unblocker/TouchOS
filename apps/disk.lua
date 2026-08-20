local app={name='Disk',icon='Disk'}
function app.run(ctx)
 local d,u,i=ctx.disp,ctx.ui,ctx.input local drive=nil for _,n in ipairs(peripheral.getNames()) do if peripheral.getType(n)=='drive' then drive=peripheral.wrap(n) break end end
 local status=drive and (drive.isDiskPresent() and 'Disk inserted' or 'No disk inserted') or 'No disk drive connected'
 while true do local w,h=d.getSize() u.clear(d) u.center(d,1,1,w,'Disk Drive',u.theme.highlight) u.text(d,2,4,status,u.theme.muted) if drive and drive.isDiskPresent() then local label=drive.getDiskLabel() or 'No label' u.text(d,2,6,'Label: '..label) u.text(d,2,7,'Mount: '..tostring(drive.getMountPath() or 'none')) end local bw=math.floor(w/2) u.button(d,{x=1,y=h-2,w=bw,h=2,label='Refresh'},false) u.button(d,{x=bw+1,y=h-2,w=w-bw,h=2,label='Back'},false)
  local e=i.pull() if e.kind=='back' then return elseif e.kind=='resize' then elseif e.kind=='touch' then if e.y>=h-2 then if e.x>bw then return end status=drive and (drive.isDiskPresent() and 'Disk inserted' or 'No disk inserted') or 'No disk drive connected' end elseif e.kind=='activate' then status=drive and (drive.isDiskPresent() and 'Disk inserted' or 'No disk inserted') or 'No disk drive connected' end
 end
end
return app
