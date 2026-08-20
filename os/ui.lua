local ui = {}
ui.theme = { bg = colors.black, bgAlt = colors.gray, fg = colors.white, accent = colors.blue, accentText = colors.white, highlight = colors.yellow, muted = colors.lightGray }
function ui.clear(d) d.setBackgroundColor(ui.theme.bg) d.setTextColor(ui.theme.fg) d.clear() d.setCursorPos(1,1) end
function ui.fill(d,x,y,w,h,c) if w <= 0 or h <= 0 then return end d.setBackgroundColor(c or ui.theme.bg) for row=y,y+h-1 do d.setCursorPos(x,row) d.write(string.rep(' ',w)) end end
function ui.text(d,x,y,s,fg,bg) s=tostring(s or '') local w,h=d.getSize() if y<1 or y>h or x>w then return end if bg then d.setBackgroundColor(bg) end if fg then d.setTextColor(fg) end d.setCursorPos(x,y) d.write(s:sub(1,w-x+1)) end
function ui.center(d,x,y,w,s,fg,bg) s=tostring(s or '') if #s>w then s=s:sub(1,w) end local tx=x+math.max(0,math.floor((w-#s)/2)) ui.text(d,tx,y,s,fg,bg) end
function ui.button(d,b,selected) local bg=selected and ui.theme.highlight or ui.theme.accent local fg=selected and colors.black or ui.theme.accentText ui.fill(d,b.x,b.y,b.w,b.h,bg) local s=tostring(b.label or '') if #s>b.w-2 then s=s:sub(1,math.max(1,b.w-2)) end ui.center(d,b.x,b.y+math.floor((b.h-1)/2),b.w,s,fg,bg) end
function ui.hit(list,x,y) for n,b in ipairs(list) do if x>=b.x and x<b.x+b.w and y>=b.y and y<b.y+b.h then return b,n end end end
function ui.clamp(n,a,b) if b<a then return a end return math.max(a,math.min(b,n)) end
return ui
