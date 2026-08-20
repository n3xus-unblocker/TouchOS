local app={name='Files',icon='Files'}
function app.run(ctx)
 local d,u,i=ctx.disp,ctx.ui,ctx.input local path='/' local sel=1 local scroll=0
 local function getItems() local t={} if path~='/' then t[#t+1]={label='..',id='..',dir=true} end for _,n in ipairs(fs.list(path)) do local full=fs.combine(path,n) t[#t+1]={label=fs.isDir(full) and '['..n..']' or n,id=n,dir=fs.isDir(full)} end table.sort(t,function(a,b) if a.id=='..' then return true elseif b.id=='..' then return false end return a.id<b.id end) return t end
 local items=getItems()
 local function refresh() items=getItems() sel=u.clamp(sel,1,math.max(1,#items)) local h=d.getSize() local rows=math.max(1,h-6) if sel-scroll>rows then scroll=sel-rows elseif sel-scroll<1 then scroll=sel-1 end end
 local function openSelected() local x=items[sel] if not x then return end if x.dir then if x.id=='..' then path=fs.getDir(path) if path=='' then path='/' end else path=fs.combine(path,x.id) end refresh() else shell.run(fs.combine(path,x.id)) end end
 while true do local w,h=d.getSize() u.clear(d) u.center(d,1,1,w,'Files',u.theme.highlight) u.text(d,1,2,path,u.theme.muted) local rows=math.max(1,h-6) for n=1,rows do local idx=n+scroll local x=items[idx] if x then u.fill(d,1,n+3,w,1,idx==sel and u.theme.highlight or u.theme.bg) u.text(d,2,n+3,x.label,idx==sel and colors.black or colors.white) end end local bw=math.floor(w/3) u.button(d,{x=1,y=h-2,w=bw,h=2,label='Open'},false) u.button(d,{x=bw+1,y=h-2,w=bw,h=2,label='Delete'},false) u.button(d,{x=bw*2+1,y=h-2,w=w-bw*2,h=2,label='Back'},false)
  local e=i.pull() if e.kind=='back' then return elseif e.kind=='resize' then refresh() elseif e.kind=='move' then if e.dir=='down' then sel=u.clamp(sel+1,1,#items) elseif e.dir=='up' then sel=u.clamp(sel-1,1,#items) end refresh() elseif e.kind=='activate' then openSelected() elseif e.kind=='touch' then if e.y>=3 and e.y<h-2 then local idx=e.y-3+1+scroll if items[idx] then sel=idx end elseif e.y>=h-2 then if e.x<=bw then openSelected() elseif e.x<=bw*2 then local x=items[sel] if x and x.id~='..' then fs.delete(fs.combine(path,x.id)) refresh() end else return end end end
 end
end
return app
