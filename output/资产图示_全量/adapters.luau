-- Additional preview adapters. They operate only on disposable display copies.
local S=assert(_G.AFPreviewBulk)
local H=game:GetService('HttpService')
local core=S.render
local function finish(record)
    local camera=S.camera
    record.camera={camera.CFrame:GetComponents()}
    record.fieldOfView=camera.FieldOfView
    record.viewport={camera.ViewportSize.X,camera.ViewportSize.Y}
    S.currentId=record.id
    task.wait(0.3)
    return H:JSONEncode(record)
end
local function flatCamera(size)
    local c=S.camera
    c.FieldOfView=35
    local tangent=math.tan(math.rad(17.5))
    local aspect=c.ViewportSize.X/math.max(c.ViewportSize.Y,1)
    local distance=math.max(size.Y/(2*tangent),size.X/(2*tangent*aspect))*1.13+0.5
    c.CFrame=CFrame.lookAt(S.origin+Vector3.new(0,0,-distance),S.origin)
    c.Focus=CFrame.new(S.origin)
end
local function panel(width,height)
    local board=Instance.new('Part')
    board.Name='PreviewBoard'
    board.Size=Vector3.new(24,24*height/width,0.1)
    board.CFrame=CFrame.new(S.origin)
    board.Anchored=true board.CanCollide=false board.CanTouch=false board.CanQuery=false
    board.Color=Color3.fromRGB(35,44,49)
    board.Parent=S.stage
    local backdrop=board:Clone()
    backdrop.Name='NeutralBackdrop'
    backdrop.Size=Vector3.new(1500,1500,0.1)
    backdrop.CFrame=board.CFrame+Vector3.new(0,0,0.2)
    backdrop.Parent=S.stage
    local gui=Instance.new('SurfaceGui')
    gui.Face=Enum.NormalId.Front gui.CanvasSize=Vector2.new(width,height)
    gui.LightInfluence=0 gui.AlwaysOnTop=false gui.Adornee=board gui.Enabled=true gui.Parent=board
    flatCamera(board.Size)
    return gui
end
local function recordFor(row)
    return {id=row.id,name=row.name,path=row.path,parts=row.parts,visibleParts=0,scriptsRemoved=0,size={0,0,0}}
end
local function card(row,record,body)
    S.stage:ClearAllChildren()
    local gui=panel(1400,700)
    S.label(gui,'AFTER FALL / ASSET INFORMATION',45,65,28,Color3.fromRGB(155,182,170))
    S.label(gui,row.id..'  '..row.name,150,125,50)
    for _,obj in ipairs(gui:GetChildren()) do if obj:IsA('TextLabel') and obj.Position.Y.Offset==150 then obj.TextScaled=true end end
    S.label(gui,body,315,260,30,Color3.fromRGB(205,213,215))
    record.method='说明卡' record.note=body
    return finish(record)
end
local function stats(source)
    local summary={}
    for _,obj in ipairs(source:GetDescendants()) do summary[obj.ClassName]=(summary[obj.ClassName] or 0)+1 end
    local list={}
    for class,count in pairs(summary) do table.insert(list,class..' × '..count) end
    table.sort(list)
    return table.concat(list,'；')
end
local function strip(copy)
    local count=0
    local objects=copy:GetDescendants()
    table.insert(objects,copy)
    for i,obj in ipairs(objects) do
        if obj:IsA('BaseScript') or obj:IsA('ModuleScript') then obj:Destroy() count+=1
        elseif obj:IsA('BasePart') then obj.Anchored=true obj.CanCollide=false obj.CanTouch=false obj.CanQuery=false
        elseif obj:IsA('Sound') then obj.Playing=false end
        if i%700==0 then task.wait() end
    end
    return count
end
local function guiSize(gui)
    if gui:IsA('SurfaceGui') then return math.max(1,gui.CanvasSize.X),math.max(1,gui.CanvasSize.Y) end
    if gui:IsA('BillboardGui') then
        local size=gui.Size
        if size.X.Offset>0 and size.Y.Offset>0 then return size.X.Offset,size.Y.Offset end
        if size.X.Scale>0 and size.Y.Scale>0 then return 500,500*size.Y.Scale/size.X.Scale end
    end
    return 600,300
end
local function guiPreview(row,source,roots,record)
    local widgets,content=0,0
    for _,root in ipairs(roots) do for _,obj in ipairs(root:GetDescendants()) do
        if obj:IsA('GuiObject') then
            widgets+=1
            if obj.BackgroundTransparency<0.99 then content+=1 end
            if (obj:IsA('TextLabel') or obj:IsA('TextButton')) and obj.Text~='' then content+=1 end
            if (obj:IsA('ImageLabel') or obj:IsA('ImageButton')) and obj.Image~='' then content+=1 end
        end
    end end
    if widgets==0 then return card(row,record,'包含界面容器，但当前没有可显示的界面控件。\n本图为结构说明，不代表运行时界面。\n'..stats(source)) end
    if content==0 then return card(row,record,'包含界面控件，但默认文本、图案和背景均为空或透明。\n本图保留模板结构，未虚构运行内容。\n'..stats(source)) end
    local descriptions={}
    local cellW,cellH=0,0
    for _,root in ipairs(roots) do
        local width,height=guiSize(root)
        local scale=math.min(4,600/width,420/height)
        local entry={root=root,width=width,height=height,scale=scale}
        table.insert(descriptions,entry)
        cellW=math.max(cellW,width*scale) cellH=math.max(cellH,height*scale)
    end
    local columns=math.min(3,#descriptions)
    local rows=math.ceil(#descriptions/columns)
    S.stage:ClearAllChildren()
    local totalW=columns*(cellW+35)+35
    local totalH=rows*(cellH+55)+110
    local gui=panel(totalW,totalH)
    S.label(gui,row.id..'  '..row.name..' / 界面模板',15,55,28)
    for index,entry in ipairs(descriptions) do
        local x=35+((index-1)%columns)*(cellW+35)
        local y=90+math.floor((index-1)/columns)*(cellH+55)
        local outer=Instance.new('Frame')
        outer.BackgroundTransparency=1 outer.Position=UDim2.fromOffset(x,y)
        outer.Size=UDim2.fromOffset(cellW,cellH) outer.Parent=gui
        local inner=Instance.new('Frame')
        inner.BackgroundTransparency=1 inner.Size=UDim2.fromOffset(entry.width,entry.height)
        inner.Parent=outer
        local scale=Instance.new('UIScale') scale.Scale=entry.scale scale.Parent=inner
        for _,child in ipairs(entry.root:GetChildren()) do
            local copy=S.cloneAll(child)
            if copy then
                record.scriptsRemoved+=strip(copy)
                if copy:IsA('GuiObject') then copy.Visible=true end
                if copy:IsA('CanvasGroup') then copy.GroupTransparency=0 end
                copy.Parent=inner
            end
        end
    end
    record.method='界面演示'
    record.note='从原界面容器提取控件到临时展示面，启用根层默认布局；没有填写虚构运行数据，也未运行交互脚本。'
    record.guiRoots=#roots record.guiWidgets=widgets
    return finish(record)
end
local function highlightPreview(row,source,record)
    S.stage:ClearAllChildren()
    local model=Instance.new('Model') model.Name='HighlightDemo'
    local copy=S.cloneAll(source) record.scriptsRemoved=strip(copy) copy.Parent=model
    local block=Instance.new('Part') block.Name='DemonstrationWood'
    block.Size=Vector3.new(4,4,4) block.CFrame=CFrame.new(S.origin)
    block.Anchored=true block.CanCollide=false block.Material=Enum.Material.Wood
    block.Color=Color3.fromRGB(135,88,49) block.Parent=model
    for _,obj in ipairs(copy:GetDescendants()) do if obj:IsA('Highlight') then obj.Enabled=true obj.Adornee=model end end
    S.mount(model,S.stage)
    local floor=Instance.new('Part') floor.Size=Vector3.new(500,1,500)
    floor.CFrame=CFrame.new(S.origin-Vector3.new(0,2.55,0)) floor.Anchored=true floor.CanCollide=false floor.CastShadow=false
    floor.Color=Color3.fromRGB(65,72,78) floor.Parent=S.stage
    S.camera.FieldOfView=35 S.camera.CFrame=CFrame.lookAt(S.origin+Vector3.new(9,7,9),S.origin) S.camera.Focus=CFrame.new(S.origin)
    record.method='效果演示'
    record.note='使用临时木块承载原 Highlight，启用克隆效果，保留其颜色及透明度参数；木块是演示载体，不属于原资产。'
    return finish(record)
end
local function effectLibrary(row,source)
    local demo=S.cloneAll(source)
    strip(demo)
    local children=demo:GetChildren()
    local index=0
    for _,child in ipairs(children) do
        if child:IsA('BasePart') or child:IsA('Model') or child:IsA('Attachment') then
            index+=1
            local point=Vector3.new(((index-1)%6)*22,0,math.floor((index-1)/6)*22)
            if child:IsA('Attachment') then
                local carrier=Instance.new('Part') carrier.Name='EffectDemoCarrier'
                carrier.Transparency=1 carrier.Size=Vector3.new(4,4,4) carrier.Anchored=true carrier.CFrame=CFrame.new(point)
                carrier.Parent=demo child.Parent=carrier child.CFrame=CFrame.identity
            else child:PivotTo(CFrame.new(point)*child:GetPivot().Rotation) end
        end
    end
    local emitters,beams,trails=0,0,0
    for _,obj in ipairs(demo:GetDescendants()) do
        if obj:IsA('ParticleEmitter') then
            emitters+=1 obj.Enabled=true obj.Rate=math.clamp(obj.Rate,8,20) obj.Lifetime=NumberRange.new(1.5,2.5)
        elseif obj:IsA('Beam') then beams+=1 obj.Enabled=true
        elseif obj:IsA('Trail') then trails+=1
        elseif obj:IsA('Fire') or obj:IsA('Smoke') or obj:IsA('Sparkles') then obj.Enabled=true
        elseif obj:IsA('BasePart') and obj.Transparency>=0.98 then obj.Size=Vector3.new(math.min(6,obj.Size.X),math.min(6,obj.Size.Y),math.min(6,obj.Size.Z)) end
    end
    S.sources[row.id]=demo
    local ok,result=pcall(core,row.id)
    S.sources[row.id]=source demo:Destroy()
    assert(ok,result)
    local record=H:JSONDecode(result)
    record.renderedParts=record.parts record.parts=row.parts record.method='效果演示'
    record.note='特效库临时分格陈列，启用部分效果并限制发射密度以便截图；含 '..emitters..' 个粒子发射器、'..beams..' 个 Beam、'..trails..' 个 Trail。静态帧不代表全部触发时序，Trail 运动效果未完整演示。'
    return finish(record)
end
S.render=function(id)
    local row=assert(S.rows[id])
    local source=assert(S.sources[id])
    local record=recordFor(row)
    if source:IsA('Terrain') then
        local ok,count=pcall(function()return source:CountCells()end)
        record.terrainCellCount=ok and count or nil
        return card(row,record,ok and ('全局 Terrain 容器\n编辑态体素单元：'..count..'\n'..(count==0 and '当前没有体素地形可拍摄，保留容器说明。' or '本图展示容器信息，未将全局体素范围视为单个模型。')) or '全局 Terrain 容器；本图展示容器信息。')
    end
    if id=='AF-0598' then return effectLibrary(row,source) end
    local roots,hasHighlight,visible={},false,0
    if source:IsA('LayerCollector') then table.insert(roots,source) end
    if row.parts==0 or row.parts<=3 or string.find(row.path,'Workspace.Prefabs.UI.',1,true)==1 then
        for _,obj in ipairs(source:GetDescendants()) do
            if obj:IsA('LayerCollector') then table.insert(roots,obj)
            elseif obj:IsA('Highlight') then hasHighlight=true
            elseif obj:IsA('BasePart') and obj.Transparency<0.98 then visible+=1 end
        end
        if #roots>0 and (row.parts==0 or visible==0 or string.find(row.path,'Workspace.Prefabs.UI.',1,true)==1) then return guiPreview(row,source,roots,record) end
        if row.parts==0 and hasHighlight then return highlightPreview(row,source,record) end
        if row.parts==0 then return card(row,record,'当前未含 BasePart，无法拍摄模型外观。\n'..stats(source)..'\n本图保留对象结构信息，不表示该对象没有用途。') end
    end
    return core(id)
end
return 'Additional preview adapters ready'
