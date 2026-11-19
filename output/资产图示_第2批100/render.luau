-- Define the renderer once; call _G.AFPreviewBatch2.render('AF-0001') afterwards.
local state = assert(_G.AFPreviewBatch2)
local H = game:GetService('HttpService')
local function bounds(parts)
    local low = Vector3.new(math.huge,math.huge,math.huge)
    local high = Vector3.new(-math.huge,-math.huge,-math.huge)
    for _, part in ipairs(parts) do
        for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
            local p = part.CFrame:PointToWorldSpace(part.Size * Vector3.new(x,y,z) * 0.5)
            low = Vector3.new(math.min(low.X,p.X),math.min(low.Y,p.Y),math.min(low.Z,p.Z))
            high = Vector3.new(math.max(high.X,p.X),math.max(high.Y,p.Y),math.max(high.Z,p.Z))
        end end end
    end
    return (low+high)*0.5, high-low
end
local function label(gui,text,y,height,size,color)
    local t=Instance.new('TextLabel')
    t.BackgroundTransparency=1
    t.Size=UDim2.new(0.9,0,0,height)
    t.Position=UDim2.new(0.05,0,0,y)
    t.Text=text
    t.TextSize=size
    t.TextColor3=color or Color3.fromRGB(235,237,239)
    t.Font=Enum.Font.SourceSans
    t.TextWrapped=true
    t.Parent=gui
end
state.render = function(id)
    local row=assert(state.rows[id], 'Outside batch 2')
    local source=assert(state.sources[id])
    state.stage:ClearAllChildren()
    local model=Instance.new('Model')
    model.Name=id..'_DisplayCopy'
    local clone=source:Clone()
    assert(clone, 'Clone unavailable')
    local scriptsRemoved=0
    local all=clone:GetDescendants()
    table.insert(all,clone)
    for _, obj in ipairs(all) do
        if obj:IsA('BaseScript') or obj:IsA('ModuleScript') then
            scriptsRemoved+=1
            obj:Destroy()
        elseif obj:IsA('BasePart') then
            obj.Anchored=true
            obj.CanCollide=false
            obj.CanTouch=false
            obj.CanQuery=false
        elseif obj:IsA('Sound') then
            obj.Playing=false
        elseif obj:IsA('Humanoid') then
            obj.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
        end
    end
    clone.Parent=model
    local parts,visible={},{}
    for _, obj in ipairs(model:GetDescendants()) do
        if obj:IsA('BasePart') then
            table.insert(parts,obj)
            if obj.Transparency<0.98 then table.insert(visible,obj) end
        end
    end
    local record={id=id,name=row.name,path=row.path,parts=#parts,visibleParts=#visible,scriptsRemoved=scriptsRemoved}
    local cam=state.camera
    cam.FieldOfView=35
    if #parts==0 then
        model:Destroy()
        local board=Instance.new('Part')
        board.Name='EmptyAssetInformationCard'
        board.Size=Vector3.new(20,10,0.1)
        board.Anchored=true
        board.CanCollide=false
        board.Color=Color3.fromRGB(42,51,57)
        board.Material=Enum.Material.SmoothPlastic
        board.CFrame=CFrame.new(state.origin)
        board.Parent=state.stage
        local gui=Instance.new('SurfaceGui')
        gui.Face=Enum.NormalId.Front
        gui.CanvasSize=Vector2.new(1400,700)
        gui.LightInfluence=0
        gui.Parent=board
        label(gui,'AFTER FALL  /  ASSET PREVIEW',50,70,30,Color3.fromRGB(159,184,173))
        label(gui,id..'  '..row.name,165,105,64)
        label(gui,'无可渲染内容',310,80,48)
        label(gui,'此对象未含 BasePart；仅含空 Accessory。\n这是结构说明卡，不是模型外观。',410,130,32,Color3.fromRGB(183,193,200))
        cam.CFrame=CFrame.lookAt(state.origin+Vector3.new(0,0,-18),state.origin)
        cam.Focus=CFrame.new(state.origin)
        record.method='说明卡'
        record.note='空 Model 内仅有空 Accessory；未含 BasePart。说明卡由 Studio SurfaceGui 渲染。'
        record.size={0,0,0}
    else
        if #visible==0 then
            for _, part in ipairs(parts) do part.Transparency=0.45 part.Color=Color3.fromRGB(76,178,203) end
            visible=parts
            record.method='辅助可视化'
            record.note='原部件均为全透明或近全透明；仅在展示副本上调整透明度及颜色。'
        else
            record.method='原貌截图'
            record.note='Studio 编辑态副本静态外观；保留原部件材质、颜色、透明度与朝向；未演示玩法交互。'
        end
        local front=nil
        local doorSum=Vector3.zero
        local doorCount=0
        local preferredSum=Vector3.zero
        local preferredCount=0
        local sourcePivot=clone:GetPivot().Position
        for _,obj in ipairs(clone:GetDescendants()) do
            local name=string.lower(obj.Name)
            if obj:IsA('Model') and (string.match(name,'door$') or obj.Name=='门' or obj.Name=='右门' or obj.Name=='左门') then
                doorSum+=obj:GetPivot().Position
                doorCount+=1
                if name=='rightdoor' or obj.Name=='右门' then preferredSum+=obj:GetPivot().Position preferredCount+=1 end
            end
        end
        if preferredCount>0 then doorSum=preferredSum doorCount=preferredCount end
        if doorCount>0 then
            local delta=doorSum/doorCount-sourcePivot
            if math.max(math.abs(delta.X),math.abs(delta.Z))>0.5 then
                front=math.abs(delta.X)>math.abs(delta.Z) and Vector3.new(delta.X>0 and 1 or -1,0.8,1).Unit or Vector3.new(1,0.8,delta.Z>0 and 1 or -1).Unit
                record.note..=' 依门组件方位选择斜视角。'
            end
        end
        local center,size=bounds(visible)
        model:PivotTo(CFrame.new(state.origin-center)*model:GetPivot())
        model.Parent=state.stage
        local floor=Instance.new('Part')
        floor.Name='NeutralPreviewFloor'
        floor.Anchored=true
        floor.CanCollide=false
        floor.CastShadow=false
        floor.Material=Enum.Material.SmoothPlastic
        floor.Color=Color3.fromRGB(65,72,78)
        local span=math.max(size.X,size.Y,size.Z,10)*200
        floor.Size=Vector3.new(math.min(span,2000),1,math.min(span,2000))
        floor.CFrame=CFrame.new(state.origin-Vector3.new(0,size.Y*0.5+0.55,0))
        floor.Parent=state.stage
        if span>2000 then
            for x=-1,1 do for z=-1,1 do
                if x~=0 or z~=0 then
                    local tile=floor:Clone()
                    tile.CFrame=floor.CFrame+Vector3.new(x*2000,0,z*2000)
                    tile.Parent=state.stage
                end
            end end
        end
        local number=tonumber(string.sub(id,4))
        local direction=front or Vector3.new(1,0.8,1).Unit
        if id=='AF-0093' then direction=Vector3.new(1,0.8,-1).Unit end
        if id=='AF-0096' then direction=Vector3.new(1,2.6,1).Unit record.note..=' 深底座场景采用高位斜视，展示顶面内容。' end
        if number>=27 and number<=48 then record.note..=' 地块使用高位斜视，兼顾顶面与底座。' end
        local rotation=CFrame.lookAt(Vector3.zero,-direction)
        local tangent=math.tan(math.rad(cam.FieldOfView*0.5))
        local aspect=cam.ViewportSize.X/math.max(cam.ViewportSize.Y,1)
        local distance=1
        for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
            local p=rotation:PointToObjectSpace(size*Vector3.new(x,y,z)*0.5)
            distance=math.max(distance, math.abs(p.X)/(tangent*aspect)+p.Z, math.abs(p.Y)/tangent+p.Z)
        end end end
        distance=distance*1.16+0.4
        if id=='AF-0024' then distance=distance/1.65 record.note..=' 联合体包围盒含较多空白，主图已收紧取景。' end
        cam.CFrame=CFrame.lookAt(state.origin+direction*distance,state.origin)
        cam.Focus=CFrame.new(state.origin)
        if state.captureInterior and (id=='AF-0133' or id=='AF-0137') then
            local base=assert(clone:FindFirstChild('底座',true),'Missing cave floor')
            local floorTop=base.Position+Vector3.new(0,base.Size.Y*0.5,0)
            local cameraPoint=floorTop+Vector3.new(base.Size.X*0.22,18,base.Size.Z*0.25)
            local target=floorTop+Vector3.new(0,6,0)
            cam.FieldOfView=70
            cam.CFrame=CFrame.lookAt(cameraPoint,target)
            cam.Focus=CFrame.new(target)
            for _,position in ipairs({cameraPoint,target+Vector3.new(0,10,0)}) do
                local carrier=Instance.new('Part')
                carrier.Name='TemporaryInteriorFillLight'
                carrier.Anchored=true carrier.CanCollide=false carrier.Transparency=1
                carrier.Position=position
                carrier.Parent=state.stage
                local light=Instance.new('PointLight')
                light.Brightness=1.5 light.Range=60 light.Shadows=false
                light.Parent=carrier
            end
            record.note..=' 主图采用洞穴内部视角及临时补光；未剖切或改动原模型，另保留整体外观。'
            record.additionalViews={{file='images/'..id..'-exterior.jpg',label='整体外观',note='未剖切的封闭外壳整体图。'}}
        end
        record.size={size.X,size.Y,size.Z}
    end
    record.camera={cam.CFrame:GetComponents()}
    record.fieldOfView=cam.FieldOfView
    record.viewport={cam.ViewportSize.X,cam.ViewportSize.Y}
    state.currentId=id
    task.wait(0.35)
    return H:JSONEncode(record)
end
return 'Renderer ready'
