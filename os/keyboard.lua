local kb={}
kb.rows={{'q','w','e','r','t','y','u','i','o','p'},{'a','s','d','f','g','h','j','k','l'},{'z','x','c','v','b','n','m'},{'SPACE','BACK'}}
function kb.draw(m)
 if not m then return end
 local w,h=m.getSize() m.setBackgroundColor(colors.black) m.setTextColor(colors.white) m.clear()
 local keyW=math.max(3,math.floor(w/10)-1)
 for rowNo,row in ipairs(kb.rows) do local x=1 for _,label in ipairs(row) do local ww=label=='SPACE' and math.min(12,w-x+1) or keyW if x+ww-1<=w and rowNo<=h then m.setBackgroundColor(colors.blue) m.setTextColor(colors.white) m.setCursorPos(x,rowNo) m.write(string.rep(' ',ww)) m.setCursorPos(x+math.max(0,math.floor((ww-#label)/2)),rowNo) m.write(label) end x=x+ww+1 end end
end
function kb.touch(m,x,y)
 if not m or y<1 or y>4 then return nil end local w=m.getSize() local keyW=math.max(3,math.floor(w/10)-1) local row=kb.rows[y] if not row then return nil end local x0=1 for _,label in ipairs(row) do local ww=label=='SPACE' and math.min(12,w-x0+1) or keyW if x>=x0 and x<x0+ww then if label=='SPACE' then return {kind='char',char=' '} elseif label=='BACK' then return {kind='backspace'} else return {kind='char',char=label} end end x0=x0+ww+1 end return nil
end
return kb
