local app={name='Printer',icon='Print'}
function app.run(ctx)
 local d,u,i=ctx.disp,ctx.ui,ctx.input local printers={}
 for _,s in ipairs(peripheral.getNames()) do if peripheral.getType(s)=='printer' then printers[#printers+1]=s end end
 local sel=1 local text=''
 local function draw() local w,h=d.getSize() u.clear(d) u.center(d,1,1,w,'Printer',u.theme.highlight) if #printers==0 then u.center(d,1,4,w,'No printer found',colors.red) return end u.text(d,2,3,'Printer: '..printers[sel]) u.text(d,2,5,'Text: '..text) u.button(d,{x=2,y=7,w=math.min(16,w-3),h=2,label='Print'},false) u.button(d,{x=20,y=7,w=math.min(16,math.max(1,w-19)),h=2,label='Clear'},false) end
 draw()
 while true do local e=i.pull() if e.kind=='back' then return elseif e.kind=='char' then text=text..e.char draw() elseif e.kind=='touch' then local w,h=d.getSize() if e.y>=7 and e.y<9 then if e.x<19 then local p=peripheral.wrap(printers[sel]) if p and p.newPage then p.newPage() p.setPageTitle('TouchOS') p.write(text) p.endPage() text='' else text='' end draw() elseif e.x>=19 then text='' draw() end elseif e.kind=='move' then if e.dir=='up' then sel=math.max(1,sel-1) elseif e.dir=='down' then sel=math.min(#printers,sel+1) end draw() end end
end
return app
