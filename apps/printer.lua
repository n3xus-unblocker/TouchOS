local app={name='Printer',icon='Print'}
function app.run(ctx)
 local d,u,i=ctx.disp,ctx.ui,ctx.input
 local printer=peripheral.find('printer')
 local text=''; local status=printer and 'Printer ready' or 'No printer connected'
 local function draw()
  local w,h=d.getSize(); u.clear(d); u.header(d,'Printer','Print text on paper')
  u.panel(d,2,5,w-2,math.max(3,h-9),u.theme.surface)
  local line=1
  for s in (text..'\n'):gmatch('(.-)\n') do if line>h-9 then break end u.text(d,3,4+line,u.truncate(s,w-5),colors.white,u.theme.surface); line=line+1 end end
  u.text(d,2,4,u.truncate(status,w-3),status:find('No printer') and colors.red or colors.lime)
  local bw=math.floor(w/3)
  u.button(d,{x=1,y=h-2,w=bw,h=2,label='PRINT'},false)
  u.button(d,{x=bw+1,y=h-2,w=bw,h=2,label='CLEAR'},false)
  u.button(d,{x=bw*2+1,y=h-2,w=w-bw*2,h=2,label='BACK'},false)
  u.status(d,'Type or paste text','PRINTER')
 end
 local function printText()
  if not printer then status='No printer connected'; return end
  if text=='' then status='Nothing to print'; return end
  local ok,err=pcall(function()
   printer.newPage(); printer.setPageTitle('TouchOS')
   for line in (text..'\n'):gmatch('(.-)\n') do printer.write(line) end
   printer.endPage()
  end)
  status=ok and 'Printed successfully' or ('Print failed: '..tostring(err))
  if ok then text='' end
 end
 draw()
 while true do
  local e=i.pull()
  if e.kind=='back' then return
  elseif e.kind=='backspace' then text=text:sub(1,-2); draw()
  elseif e.kind=='char' then text=text..e.char; draw()
  elseif e.kind=='paste' then text=text..e.text; draw()
  elseif e.kind=='resize' then draw()
  elseif e.kind=='touch' then
   local w,h=d.getSize(); local bw=math.floor(w/3)
   if e.y>=h-2 then if e.x<=bw then printText() elseif e.x<=bw*2 then text=''; status='Cleared' else return end; draw() end
  elseif e.kind=='activate' then printText(); draw() end
 end
end
return app
