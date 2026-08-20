local app={name='Shell',icon='>_'}
function app.run(ctx)
 local d,u,i=ctx.disp,ctx.ui,ctx.input local buf='' local lines={'TouchOS Shell'}
 local function draw()
  local w,h=d.getSize() u.clear(d) u.text(d,1,1,'Shell',u.theme.highlight)
  local max=math.max(1,h-6) local start=math.max(1,#lines-max+1)
  for n=start,#lines do u.text(d,1,n-start+3,tostring(lines[n]):sub(1,w)) end
  u.fill(d,1,h-3,w,1,u.theme.bg) u.text(d,1,h-3,'> '..buf:sub(1,math.max(0,w-2)))
  local bw=math.floor(w/2) u.button(d,{x=1,y=h-2,w=bw,h=2,label='Back'},false) u.button(d,{x=bw+1,y=h-2,w=w-bw,h=2,label='Run'},false)
 end
 local function runCommand()
  local cmd=buf buf='' if cmd=='' then return end lines[#lines+1]='> '..cmd
  local old=term.redirect(d) local ok,err=pcall(shell.run,cmd) term.redirect(old) if not ok then lines[#lines+1]='Error: '..tostring(err) end
 end
 draw()
 while true do
  local e=i.pull()
  if e.kind=='back' then return elseif e.kind=='backspace' then buf=buf:sub(1,-2) draw() elseif e.kind=='char' then buf=buf..e.char draw() elseif e.kind=='paste' then buf=buf..e.text draw() elseif e.kind=='activate' then runCommand() draw() elseif e.kind=='touch' then local w,h=d.getSize() if e.y>=h-2 then if e.x<=math.floor(w/2) then return else runCommand() draw() end end elseif e.kind=='resize' then draw() end
 end
end
return app
