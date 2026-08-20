local ui={}
ui.theme={bg=colors.black,fg=colors.white,accent=colors.blue,accentText=colors.white,highlight=colors.yellow,muted=colors.gray}
function ui.clear(d) d.setBackgroundColor(ui.theme.bg) d.setTextColor(ui.theme.fg) d.clear() end
function ui.fill(d,x,y,w,h,c) if w<=0 or h<=0 then return end d.setBackgroundColor(c) for r=y,y+h-1 do d.setCursorPos(x,r) d.write(string.rep(' ',w)) end end
function ui.text(d,x,y,s,fg,bg) s=tostring(s or '') if bg then d.setBackgroundColor(bg) end if fg then d.setTextColor(fg) end if y>=1 and y<=d.getSize() then d.setCursorPos(x,y) d.write(s:sub(1,math.max(0,d.getSize()-x+1))) end end
function ui.center(d,x,y,w,s,fg,bg) s=tostring(s or '') local n=math.max(0,math.floor((w-#s)/2)) ui.text(d,x+n,y,s,fg,bg) end
function ui.button(d,b,selected) local bg=selected and ui.theme.highlight or ui.theme.accent local fg=selected and colors.black or ui.theme.accentText ui.fill(d,b.x,b.y,b.w,b.h,bg) local s=tostring(b.label or '') if #s>b.w-2 then s=s:sub(1,math.max(1,b.w-2)) end ui.center(d,b.x,b.y+math.floor((b.h-1)/2),b.w,s,fg,bg) end
function ui.backButton(d,w,h) return {x=1,y=math.max(1,h-2),w=w,h=3,label='Back',id='back'} end
function ui.hit(list,x,y) for n,b in ipairs(list) do if x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h then return b,n end end end
function ui.clamp(n,a,b) if b<a then return a end return math.max(a,math.min(b,n)) end
return ui
