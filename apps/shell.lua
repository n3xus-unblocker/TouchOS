local app={name='Shell',icon='Shell'}
function app.run(ctx)
 local d,u,i=ctx.disp,ctx.ui,ctx.input local w,h=d.getSize() local buf='' local lines={'TouchOS Shell'}
 local function draw() w,h=d.getSize() u.clear(d) local max=math.max(1,h-3) local start=math.max(1,#lines-max+1) for n=start,#lines do u.text(d,1,n-start+1,tostring(lines[n]):sub(1,w)) end u.fill(d,1,h,w,3,u.theme.bg) u.text(d,1,h-1,'Command: '..buf:sub(1,math.max(0,w-10))) u.button(d,{x=1,y=h,w=math.max(1,math.floor(w/2)-1),h=1,label='Run'},false) u.button(d,{x=math.floor(w/2)+1,y=h,w=math.max(1,w-math.floor(w/2)),h=1,label='Back'},false) end
 local function run() local cmd=buf buf='' if cmd~='' then lines[#lines+1]='> '..cmd local old=term.redirect(d) local ok,err=pcall(shell.run,cmd) term.redirect(old) if not ok then lines[#lines+1]='Error: '..tostring(err) end end draw() end
 draw()
 while true do local e=i.pull() if e.kind=='back' then return elseif e.kind=='char' then buf=buf..e.char draw() elseif e.kind=='key' then if e.key==keys.backspace then buf=buf:sub(1,-2) draw() elseif e.key==keys.enter then run() end elseif e.kind=='touch' then if e.y==h and e.x<=math.floor(w/2) then run() elseif e.y==h then return end elseif e.kind=='activate' then run() elseif e.kind=='resize' then draw() end end
end
return app
