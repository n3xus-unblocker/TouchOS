local app={name='Shell',icon='Shell'}
function app.run(ctx)
 local d,u,i=ctx.disp,ctx.ui,ctx.input local w,h=d.getSize() local lines={'TouchOS shell','Type commands with the physical keyboard'} local buf=''
 local function draw() w,h=d.getSize() u.clear(d) for n,s in ipairs(lines) do if n<h then u.text(d,1,n,s:sub(1,w)) end end u.fill(d,1,h,w,1,u.theme.bg) u.text(d,1,h,'> '..buf) end
 draw()
 while true do local e=i.pull() if e.kind=='back' then return elseif e.kind=='char' then buf=buf..e.char draw() elseif e.kind=='key' then if e.key==keys.backspace then buf=buf:sub(1,-2) draw() end elseif e.kind=='activate' then local cmd=buf buf='' if cmd~='' then local old=term.redirect(d) local ok,err=pcall(shell.run,cmd) term.redirect(old) if not ok then lines[#lines+1]='Error: '..tostring(err) end end lines[#lines+1]='> '..cmd draw() end elseif e.kind=='resize' then draw() end end
end
return app
