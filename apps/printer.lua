local app={name='Printer',icon='Printer'}
function app.run(ctx)
 local d,u,i=ctx.disp,ctx.ui,ctx.input local printers={} local sel=1 local text=''
 local function scan() printers={} for _,s in ipairs(peripheral.getNames()) do if peripheral.getType(s)=='printer' then printers[#printers+1]=s end end end
 local function draw()
  scan() local w,h=d.getSize() u.clear(d) u.center(d,1,1,w,'Printer',u.theme.highlight)
  if #printers==0 then u.center(d,1,5,w,'No printer found',colors.red) u.center(d,1,7,w,'Attach a CC printer',u.theme.muted) return end
  u.text(d,2,3,'Printer: '..printers[sel]) u.text(d,2,5,'Text: '..(text=='' and '(empty)' or text))
  local bw=math.max(10,math.floor((w-6)/2)) u.button(d,{x=2,y=8,w=bw,h=2,label='Print'},false) u.button(d,{x=4+bw,y=8,w=bw,h=2,label='Clear'},false)
  u.text(d,2,11,'Type using the physical or touch keyboard',u.theme.muted)
 end
 local function printPage() local p=peripheral.wrap(printers[sel]) if not p then return end if p.newPage and p.endPage and p.write then p.newPage() if p.setPageTitle then p.setPageTitle('TouchOS') end p.write(text) p.endPage() end text='' end
 draw()
 while true do
  local e=i.pull()
  if e.kind=='back' then return
  elseif e.kind=='resize' then draw()
  elseif e.kind=='char' then text=text..e.char draw()
  elseif e.kind=='key' then if e.key==keys.backspace then text=text:sub(1,-2) draw() end
  elseif e.kind=='touch' then
   local w,h=d.getSize() if #printers>0 and e.y>=8 and e.y<10 then local bw=math.max(10,math.floor((w-6)/2)) if e.x>=2 and e.x<2+bw then printPage() elseif e.x>=4+bw then text='' end draw() end
  end
 end
end
return app
