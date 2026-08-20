-- TouchOS Setup v5
local BASE='https://raw.githubusercontent.com/n3xus-unblocker/TouchOS/main/'
local FILES={'startup.lua','os/ui.lua','os/input.lua','os/keyboard.lua','apps/filemanager.lua','apps/settings.lua','apps/shell.lua','apps/printer.lua','apps/disk.lua','apps/monitor.lua'}
local PROTECTED={disk=true,rom=true,['installer.lua']=true}
local W,H=term.getSize()
local function clear(bg) term.setBackgroundColor(bg or colors.black) term.setTextColor(colors.white) term.clear() term.setCursorPos(1,1) end
local function text(x,y,s,fg,bg) if y<1 or y>H or x>W then return end s=tostring(s or ''):sub(1,math.max(0,W-x+1)) term.setCursorPos(x,y) if bg then term.setBackgroundColor(bg) end if fg then term.setTextColor(fg) end term.write(s) end
local function center(y,s,fg,bg) s=tostring(s or '') text(math.max(1,math.floor((W-#s)/2)+1),y,s,fg,bg) end
local function header(a,b) clear() term.setBackgroundColor(colors.blue) for y=1,math.min(3,H) do term.setCursorPos(1,y) term.write(string.rep(' ',W)) end center(1,a,colors.white,colors.blue) if b then center(2,b,colors.lightBlue,colors.blue) end term.setBackgroundColor(colors.black) end
local function bar(y,n,total,c) if y<=H then local w=math.max(1,W-4) local f=math.floor(w*n/math.max(1,total)) text(3,y,string.rep(' ',w),colors.white,colors.gray) if f>0 then text(3,y,string.rep(' ',f),colors.white,c or colors.cyan) end end end

header('TouchOS Setup','Fresh install')
text(2,5,'COMPLETE filesystem wipe',colors.red)
text(2,6,'Protected: /disk /rom /installer.lua',colors.yellow)
text(2,8,'The complete release is downloaded first',colors.white)
text(2,9,'so network failure cannot leave a half install',colors.white)
center(12,'Type WIPE to continue',colors.white)
term.setCursorPos(2,14) term.write('> ')
if read()~='WIPE' then clear() center(math.floor(H/2),'Installation cancelled',colors.yellow) return end

header('TouchOS Setup','Downloading')
local bundles={} local failed={}
for i,path in ipairs(FILES) do
 local y=math.min(H-3,7+((i-1)%math.max(1,H-9))) text(2,y,'FETCH '..path,colors.white)
 local r,e=http.get(BASE..path)
 if not r then failed[#failed+1]=path..': '..tostring(e or 'HTTP error') else local d=r.readAll() r.close() if type(d)~='string' or #d==0 then failed[#failed+1]=path..': empty response' else bundles[path]=d text(math.max(2,W-2),y,'OK',colors.lime) end end
 bar(H-2,i,#FILES) text(3,H-1,'Release '..i..'/'..#FILES,colors.lightGray)
end
if #failed>0 then header('TouchOS Setup','Download failed') text(2,5,'Nothing was wiped',colors.lime) local y=7 for _,e in ipairs(failed) do if y>=H then break end text(2,y,e,colors.red) y=y+1 end return end

header('TouchOS Setup','Reformatting')
text(2,5,'Removing old files...',colors.red)
local deletable={} local all=fs.list('/')
for _,name in ipairs(all) do if not PROTECTED[tostring(name):lower()] then deletable[#deletable+1]=name end end
local failures={}
for i,name in ipairs(deletable) do local ok,res=pcall(fs.delete,'/'..name) if not ok then failures[#failures+1]='/'..name..': '..tostring(res) elseif res==false then failures[#failures+1]='/'..name..': delete failed' end bar(H-2,i,#deletable,colors.red) end
if #failures>0 then clear() center(3,'WIPE FAILED',colors.red) text(2,5,'Non protected files failed to delete',colors.yellow) local y=7 for _,e in ipairs(failures) do if y>=H then break end text(2,y,e,colors.red) y=y+1 end return end

fs.makeDir('/os') fs.makeDir('/apps')
header('TouchOS Setup','Installing')
local installed=0 local writeFailures={}
for i,path in ipairs(FILES) do local dir=fs.getDir('/'..path) if dir~='' and not fs.exists(dir) then fs.makeDir(dir) end local f=fs.open('/'..path,'w') if not f then writeFailures[#writeFailures+1]=path..': cannot write' else local ok,e=pcall(function() f.write(bundles[path]) f.close() end) if ok then installed=installed+1 else pcall(f.close) writeFailures[#writeFailures+1]=path..': '..tostring(e) end end bar(H-2,i,#FILES) end
if #writeFailures>0 then clear() center(3,'INSTALL FAILED',colors.red) text(2,5,installed..'/'..#FILES..' installed',colors.yellow) return end
clear() center(math.max(2,math.floor(H/2)-1),'TOUCHOS',colors.cyan) center(math.max(3,math.floor(H/2)+1),'INSTALLATION COMPLETE',colors.lime) center(math.max(4,math.floor(H/2)+3),installed..' files installed',colors.white) sleep(2) os.reboot()
