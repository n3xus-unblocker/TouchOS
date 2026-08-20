local ui = dofile('/os/ui.lua')
local input = dofile('/os/input.lua')
local keyboard = dofile('/os/keyboard.lua')

local SETTINGS = '/os/settings.cfg'
local APPS = '/apps'

local function loadSettings()
    local s = { textScale = 1, screenMonitor = nil, keyboardMonitor = nil }
    if fs.exists(SETTINGS) then
        local f = fs.open(SETTINGS, 'r')
        if f then
            local ok, data = pcall(textutils.unserialize, f.readAll())
            f.close()
            if ok and type(data) == 'table' then for k,v in pairs(data) do s[k]=v end end
        end
    end
    return s
end

local settings = loadSettings()
local function saveSettings(s)
    local f = fs.open(SETTINGS, 'w')
    if f then f.write(textutils.serialize(s)); f.close() end
end

local function isMonitor(name)
    return name and peripheral.isPresent(name) and peripheral.getType(name) == 'monitor'
end

local function monitors()
    local t = {}
    for _, name in ipairs(peripheral.getNames()) do if peripheral.getType(name) == 'monitor' then t[#t+1]=name end end
    table.sort(t)
    return t
end

local function chooseDisplay()
    if isMonitor(settings.screenMonitor) then return peripheral.wrap(settings.screenMonitor) end
    local list = monitors()
    if #list > 0 then settings.screenMonitor=list[1]; if settings.keyboardMonitor==settings.screenMonitor then settings.keyboardMonitor=nil end; saveSettings(settings); return peripheral.wrap(list[1]) end
    return term
end

local display = chooseDisplay()
if display.setTextScale then pcall(display.setTextScale, settings.textScale or 1) end

local function keyboardDisplay()
    if not isMonitor(settings.keyboardMonitor) or settings.keyboardMonitor == settings.screenMonitor then return nil end
    local m = peripheral.wrap(settings.keyboardMonitor)
    if keyboard.isLargeEnough(m) then return m end
    return nil
end

local function refreshKeyboard()
    local m = keyboardDisplay()
    if m then keyboard.draw(m) end
end

refreshKeyboard()

local function shellApp()
    return {
        name='Shell', icon='>_',
        run=function(ctx)
            local d,u,inp=ctx.disp,ctx.ui,ctx.input
            local buffer=''
            local lines={'TouchOS Shell','Ready'}
            local function draw()
                local w,h=d.getSize()
                u.clear(d)
                u.header(d,'Shell','Command line')
                local max=math.max(1,h-7)
                local first=math.max(1,#lines-max+1)
                for n=first,#lines do u.text(d,2,n-first+4,lines[n]) end
                u.fill(d,1,h-3,w,1,u.theme.surface)
                u.text(d,2,h-3,'> '..u.truncate(buffer,math.max(0,w-3)),colors.white,u.theme.surface)
                local bw=math.floor(w/2)
                u.button(d,{x=1,y=h-2,w=bw,h=2,label='BACK'},false)
                u.button(d,{x=bw+1,y=h-2,w=w-bw,h=2,label='RUN'},true)
                u.status(d,'Touch keyboard or physical keyboard',settings.keyboardMonitor or 'none')
            end
            local function run()
                if buffer=='' then return end
                local cmd=buffer; buffer=''; lines[#lines+1]='> '..cmd
                local old=term.redirect(d)
                local ok,err=pcall(shell.run,cmd)
                term.redirect(old)
                if not ok then lines[#lines+1]='Error: '..tostring(err) end
            end
            draw(); refreshKeyboard()
            while true do
                local e=inp.pull()
                if e.kind=='back' then return
                elseif e.kind=='backspace' then buffer=buffer:sub(1,-2); draw()
                elseif e.kind=='char' then buffer=buffer..e.char; draw()
                elseif e.kind=='paste' then buffer=buffer..e.text; draw()
                elseif e.kind=='activate' then run(); draw(); refreshKeyboard()
                elseif e.kind=='touch' then local w,h=d.getSize() if e.y>=h-2 then if e.x<=math.floor(w/2) then return else run(); draw() end end
                elseif e.kind=='resize' then draw(); refreshKeyboard() end
            end
        end
    }
end

local function loadApps()
    local apps={}
    if not fs.exists(APPS) then fs.makeDir(APPS) end
    for _,file in ipairs(fs.list(APPS)) do
        if file:match('%.lua$') then
            local ok,app=pcall(dofile,fs.combine(APPS,file))
            if ok and type(app)=='table' and type(app.run)=='function' then apps[#apps+1]=app end
        end
    end
    local hasShell=false
    for _,app in ipairs(apps) do if app.name=='Shell' then hasShell=true break end end
    if not hasShell then apps[#apps+1]=shellApp() end
    table.sort(apps,function(a,b)return tostring(a.name)<tostring(b.name) end)
    return apps
end

local apps=loadApps()
local selected=#apps>0 and 1 or nil
local scroll=0

local function context()
    return {disp=display,ui=ui,input=input,settings=settings,saveSettings=function(s) settings=s; saveSettings(s); refreshKeyboard() end}
end

local function buildButtons()
    local w,h=display.getSize()
    local cols=w>=42 and 3 or (w>=26 and 2 or 1)
    local gap=2
    local cellW=math.max(1,math.floor((w-(cols+1)*gap)/cols))
    local cellH=h>=16 and 4 or 3
    local rows=math.max(1,math.floor((h-6)/(cellH+1)))
    local maxScroll=math.max(0,math.ceil(#apps/cols)-rows)
    scroll=ui.clamp(scroll,0,maxScroll)
    local first=scroll*cols+1
    local buttons={}
    for n=first,math.min(#apps,first+rows*cols-1) do
        local i=n-first
        buttons[#buttons+1]={x=gap+(i%cols)*(cellW+gap),y=5+math.floor(i/cols)*(cellH+1),w=cellW,h=cellH,label=apps[n].name,id=n}
    end
    return buttons,cols,rows,maxScroll
end

local function drawHome()
    local w,h=display.getSize()
    ui.clear(display)
    ui.header(display,'TouchOS',#apps..' apps')
    local buttons,cols,rows,maxScroll=buildButtons()
    for _,b in ipairs(buttons) do ui.button(display,b,b.id==selected) end
    if scroll>0 then ui.center(display,1,4,w,'SWIPE/ARROW UP',ui.theme.muted) end
    if scroll<maxScroll then ui.center(display,1,h-1,w,'SWIPE/ARROW DOWN',ui.theme.muted) end
    ui.status(display,'Tap an app to open','TouchOS')
    return buttons,cols,rows,maxScroll
end

local buttons,cols,rows,maxScroll=drawHome()
while true do
    local e=input.pull()
    if e.kind=='resize' then buttons,cols,rows,maxScroll=drawHome()
    elseif e.kind=='touch' then
        local b=ui.hit(buttons,e.x,e.y)
        if b then
            selected=b.id
            local ok,err=xpcall(function() apps[b.id].run(context()) end,debug.traceback)
            if not ok then
                local w,h=display.getSize(); ui.clear(display); ui.header(display,'App Error','TouchOS recovered')
                ui.text(display,2,5,ui.truncate(tostring(err),w-3),colors.red)
                ui.button(display,{x=1,y=h-2,w=w,h=2,label='BACK TO HOME'},true); input.pull()
            end
            buttons,cols,rows,maxScroll=drawHome()
        end
    elseif e.kind=='move' and selected then
        if e.dir=='left' then selected=math.max(1,selected-1)
        elseif e.dir=='right' then selected=math.min(#apps,selected+1)
        elseif e.dir=='up' then selected=math.max(1,selected-cols); scroll=math.max(0,math.floor((selected-1)/cols)-rows+1)
        elseif e.dir=='down' then selected=math.min(#apps,selected+cols); scroll=math.min(maxScroll,math.floor((selected-1)/cols)) end
        buttons,cols,rows,maxScroll=drawHome()
    elseif e.kind=='activate' and selected and apps[selected] then
        pcall(apps[selected].run,context()); buttons,cols,rows,maxScroll=drawHome()
    end
end
