-- Studio's native scene capture returned white; use a temporary ViewportFrame.
local s=assert(_G.AFBenchLevels)
local gui=Instance.new('ScreenGui') gui.Name='__AF_BenchLevelViewport'
gui.IgnoreGuiInset=true gui.ResetOnSpawn=false gui.DisplayOrder=1000000
local frame=Instance.new('ViewportFrame') frame.Size=UDim2.fromScale(1,1) frame.BorderSizePixel=0
frame.BackgroundColor3=Color3.fromRGB(65,72,78)
frame.Ambient=Color3.fromRGB(130,130,130) frame.LightColor=Color3.fromRGB(180,180,180)
frame.LightDirection=Vector3.new(-1,-0.8,-1) frame.Parent=gui
local cam=Instance.new('Camera') cam.FieldOfView=s.camera.FieldOfView cam.CFrame=s.captureCFrame
cam.Focus=CFrame.new(s.center) cam.Parent=frame frame.CurrentCamera=cam
local world=Instance.new('WorldModel') world.Parent=frame
s.assembly.Parent=world
s.stage.NeutralFloor:Destroy()
local title=Instance.new('TextLabel') title.BackgroundTransparency=1 title.Position=UDim2.fromOffset(22,14)
title.Size=UDim2.new(1,-44,0,30) title.TextXAlignment=Enum.TextXAlignment.Left
title.TextColor3=Color3.fromRGB(240,243,240) title.TextSize=24 title.Font=Enum.Font.SourceSansBold title.Parent=gui
local note=Instance.new('TextLabel') note.BackgroundTransparency=1 note.Position=UDim2.new(0,22,1,-30)
note.Size=UDim2.new(1,-44,0,22) note.TextXAlignment=Enum.TextXAlignment.Right
note.TextColor3=Color3.fromRGB(205,212,215) note.TextSize=14 note.Font=Enum.Font.SourceSans
note.Text='组件叠加模拟 · 库存为 0 · 静态视窗 / 无实时阴影' note.Parent=gui
s.previewGui=gui
gui.Parent=game.StarterGui
local render=s.render
s.render=function(level)
    local record=render(level)
    title.Text='制造台 / LEVEL '..level
    record.method='Studio ViewportFrame cumulative component simulation'
    record.note='Static geometry, zero material stock; no real-time shadows or dynamic effects.'
    task.wait(0.4)
    return record
end
local assets={}
for _,m in ipairs(s.models) do for _,d in ipairs(m:GetDescendants()) do if d:IsA('MeshPart') or d:IsA('SpecialMesh') or d:IsA('Decal') or d:IsA('Texture') then table.insert(assets,d) end end end
pcall(function() game:GetService('ContentProvider'):PreloadAsync(assets) end)
return s.render(1)
