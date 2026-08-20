local app={name='Shell',icon='>_'}
function app.run(ctx)
 local d,u,i=ctx.disp,ctx.ui,ctx.input local buf='' local lines={'TouchOS Shell','Ready'}
 local function draw()
  local w,h=d.getSize(); u.clear(d); u.header(d,'Shell','Command line')
  local max=math.max(1,h-7); local first=math.max(1,#lines-max+1)
  for n=first,#lines do u.text(d,2,n-first+4,lines[n]) end
  u.fill(d,1,h-3,w,1,u.theme.surface); u.text(d,2,h-3,'> '..u.truncate(buf,math.max(0,w-3)),colors.white,u.theme.surface)
  local bw=math.floor(w/2); u.button(d,{x=1,y=h-2,w=bw,h=2,label='BACK'},false); u.button(d,{x=bw+1,y=h-2,w=w-bw,h=2,label='RUN'},true)
  u.status(d,'Touch keyboard or physical keyboard',ctx.settings.keyboardMonitor or 'none')
 end
 local function drawKeyboard()
  local name=ctx.settings.keyboardMonitor
  if not name or name==ctx.settings.screenMonitor then return end
  local m=peripheral.wrap(name)
  if m then local kb=dofile('/os/keyboard.lua'); if kb.isLargeEnough(m) then kb.draw(m) end end
 end
 local function run()
  if buf=='' then return end
  local cmd=buf; buf=''; lines[#lines+1]='> '..cmd
  local old=term.redirect(d); local ok,err=pcall(shell.run,cmd); term.redirect(old)
  if not ok then lines[#lines+1]='Error: '..tostring(err) end
 end
 draw(); drawKeyboard()
 while true do
  local e=i.pull()
  if e.kind=='back' then return
  elseif e.kind=='backspace' then buf=buf:sub(1,-2); draw()
  elseif e.kind=='char' then buf=buf..e.char; draw()
  elseif e.kind=='paste' then buf=buf..e.text; draw()
  elseif e.kind=='clear' then buf=''; draw()
  elseif e.kind=='activate' then run(); draw(); drawKeyboard()
  elseif e.kind=='touch' then local w,h=d.getSize(); if e.y>=h-2 then if e.x<=math.floor(w/2) then return else run(); draw() end end
  elseif e.kind=='resize' then draw(); drawKeyboard() end
 end
end
return app
