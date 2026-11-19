-- Edit-time simulation of CraftingBenchService.onLevelChanged.
-- Clone source components only; do not run gameplay scripts or change originals.
assert(game.PlaceId == 108983613755535, 'Unexpected place')
assert(not game:GetService('RunService'):IsRunning(), 'Edit mode required')
assert(not _G.AFBenchLevels, 'Preview session already exists')
assert(not workspace:FindFirstChild('__AF_BenchLevelPreview'), 'Preview stage already exists')
local root = workspace.Prefabs.Map:FindFirstChild('制造台')
local state = {sources={}, originals={}, models={}, savedGui={}, savedLighting={}, savedEffects={}, savedAtmospheres={}}
for level=1,5 do
    local source=assert(root:FindFirstChild(tostring(level)))
    state.sources[level]=source
    local parts={}
    for _,d in ipairs(source:GetDescendants()) do
        if d:IsA('BasePart') then
            parts[d]={cframe=d.CFrame, transparency=d.Transparency, color=d.Color, material=d.Material, size=d.Size}
        end
    end
    state.originals[level]={pivot=source:GetPivot(), parent=source.Parent, parts=parts}
end
local camera=workspace.CurrentCamera
state.camera=camera
state.savedCamera={CFrame=camera.CFrame,Focus=camera.Focus,CameraType=camera.CameraType,FieldOfView=camera.FieldOfView}
_G.AFBenchLevels=state
for _,obj in ipairs(game.StarterGui:GetDescendants()) do
    if obj:IsA('ScreenGui') then state.savedGui[obj]=obj.Enabled obj.Enabled=false end
end
local light=game:GetService('Lighting')
for key,value in pairs({ClockTime=14,Brightness=2,Ambient=Color3.fromRGB(130,130,130),OutdoorAmbient=Color3.fromRGB(145,145,145),FogStart=900000,FogEnd=1000000,GlobalShadows=true,ExposureCompensation=0}) do
    state.savedLighting[key]=light[key] light[key]=value
end
for _,obj in ipairs(light:GetChildren()) do
    if obj:IsA('PostEffect') then state.savedEffects[obj]=obj.Enabled obj.Enabled=false
    elseif obj:IsA('Atmosphere') then
        state.savedAtmospheres[obj]={Density=obj.Density,Haze=obj.Haze,Glare=obj.Glare}
        obj.Density=0 obj.Haze=0 obj.Glare=0
    end
end
local stage=Instance.new('Folder') stage.Name='__AF_BenchLevelPreview' stage.Parent=workspace state.stage=stage
local assembly=Instance.new('Folder') assembly.Name='CumulativeComponents' assembly.Parent=stage state.assembly=assembly
state.origin=Vector3.new(20000,10000,-20000)
state.targetPivot=CFrame.new(state.origin)
local low=Vector3.new(math.huge,math.huge,math.huge)
local high=Vector3.new(-math.huge,-math.huge,-math.huge)
for level=1,5 do
    local clone=state.sources[level]:Clone()
    clone.Name=tostring(level)
    for _,obj in ipairs(clone:GetDescendants()) do
        if obj:IsA('LuaSourceContainer') then obj:Destroy()
        elseif obj:IsA('BasePart') then obj.Anchored=true obj.CanCollide=false obj.CanTouch=false obj.CanQuery=false
        elseif obj:IsA('Sound') then obj.Playing=false
        elseif obj:IsA('ParticleEmitter') or obj:IsA('Trail') or obj:IsA('Beam') then obj.Enabled=false
        elseif obj:IsA('Humanoid') then obj.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None end
    end
    if level==1 then
        -- Match init()/refreshDisplay() with Wood/Iron/Gold/Crystal = 0.
        for _,name in ipairs({'木块','铁块','金条'}) do
            local part=assert(clone:FindFirstChild(name,true)) part.Transparency=1
        end
        local crystal=assert(clone:FindFirstChild('紫水晶',true)) crystal:Destroy()
        for name,text in pairs({Iron='🔩：0',Log='🌲：0'}) do
            local holder=clone:FindFirstChild(name)
            local label=holder and holder:FindFirstChildWhichIsA('TextLabel',true)
            if label then label.Text=text end
        end
    end
    clone:PivotTo(state.targetPivot)
    state.models[level]=clone
    clone.Parent=assembly
    for _,part in ipairs(clone:GetDescendants()) do
        if part:IsA('BasePart') and part.Transparency<0.98 then
            for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
                local p=part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)*0.5)
                low=Vector3.new(math.min(low.X,p.X),math.min(low.Y,p.Y),math.min(low.Z,p.Z))
                high=Vector3.new(math.max(high.X,p.X),math.max(high.Y,p.Y),math.max(high.Z,p.Z))
            end end end
        end
    end
end
state.center=(low+high)*0.5 state.size=high-low
local floor=Instance.new('Part') floor.Name='NeutralFloor' floor.Size=Vector3.new(2000,1,2000)
floor.Anchored=true floor.CanCollide=false floor.Material=Enum.Material.SmoothPlastic floor.Color=Color3.fromRGB(65,72,78)
floor.CFrame=CFrame.new(state.center.X,low.Y-0.55,state.center.Z) floor.Parent=stage
camera.CameraType=Enum.CameraType.Scriptable camera.FieldOfView=35
local direction=Vector3.new(1,0.8,-1).Unit
local rotation=CFrame.lookAt(Vector3.zero,-direction)
local tangent=math.tan(math.rad(camera.FieldOfView*0.5))
local aspect=camera.ViewportSize.X/math.max(camera.ViewportSize.Y,1)
local distance=1
for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
    local p=rotation:PointToObjectSpace(state.size*Vector3.new(x,y,z)*0.5)
    distance=math.max(distance,math.abs(p.X)/(tangent*aspect)+p.Z,math.abs(p.Y)/tangent+p.Z)
end end end
distance=distance*1.12+0.4
state.captureCFrame=CFrame.lookAt(state.center+direction*distance,state.center)
state.render=function(level)
    assert(level>=1 and level<=5 and level%1==0)
    local components={} local count=0
    for i=1,5 do
        local clone=state.models[i]
        clone.Parent=i<=level and state.assembly or nil
        if i<=level then
            clone:PivotTo(state.targetPivot)
            table.insert(components,i)
            for _,d in ipairs(clone:GetDescendants()) do if d:IsA('BasePart') then count+=1 end end
        end
    end
    camera.CFrame=state.captureCFrame camera.Focus=CFrame.new(state.center)
    task.wait(0.5)
    return {level=level,components=components,parts=count,zeroMaterialStock=true,method='Edit-time cumulative component simulation',camera={camera.CFrame:GetComponents()},fieldOfView=camera.FieldOfView,viewport={camera.ViewportSize.X,camera.ViewportSize.Y}}
end
return state.render(1)
