local H=game:GetService('HttpService')
local plr=game.Players.LocalPlayer
local gui=Instance.new('ScreenGui') gui.Name='__AF_TerrainConcept_Viewport' gui.IgnoreGuiInset=true gui.ResetOnSpawn=false gui.DisplayOrder=10000000
local frame=Instance.new('ViewportFrame') frame.Name='TerrainViewport' frame.Size=UDim2.fromScale(1,1) frame.BorderSizePixel=0 frame.BackgroundColor3=Color3.fromRGB(64,73,81)
frame.Ambient=Color3.fromRGB(150,150,150) frame.LightColor=Color3.fromRGB(195,190,180) frame.LightDirection=Vector3.new(-.7,-1,-.4) frame.Parent=gui
local world=Instance.new('WorldModel') world.Parent=frame
local cam=Instance.new('Camera') cam.FieldOfView=42 cam.Parent=frame frame.CurrentCamera=cam
local badge=Instance.new('TextLabel') badge.BackgroundTransparency=.18 badge.BackgroundColor3=Color3.fromRGB(22,28,33) badge.Size=UDim2.new(1,0,0,24) badge.Position=UDim2.new(0,0,1,-24) badge.TextColor3=Color3.fromRGB(230,235,238) badge.Font=Enum.Font.SourceSans badge.TextSize=15 badge.Parent=gui
gui.Parent=plr.PlayerGui
pcall(function()game.StarterGui:SetCore('TopbarEnabled',false)end)
_G.AFTerrainConceptViewer={gui=gui,frame=frame,world=world,cam=cam}
_G.AFTerrainConceptViewer.show=function(id)
 world:ClearAllChildren()
 local source=game.ReplicatedStorage.__AF_TerrainConcept_Run.Samples:FindFirstChild(id)
 assert(source,'Missing sample '..id)
 local info=H:JSONDecode(source:GetAttribute('ShotJSON'))
 local copy=source:Clone() copy.Parent=world
 local focus=Vector3.new(0,info.focusHeight,0)
 local reach=info.mountain and 180 or 100
 cam.CFrame=CFrame.lookAt(focus+Vector3.new(.65,1.03,1.0)*reach,focus)
 cam.Focus=CFrame.new(focus)
 badge.Text=id..'  '..info.title..'  | '..tostring(info.radius*2+1)..'x'..tostring(info.radius*2+1)..'地块样区 | 实生地图副本 · 静态视窗'
 local failures={}
 pcall(function()game.ContentProvider:PreloadAsync({copy},function(asset,status)if status~=Enum.AssetFetchStatus.Success then table.insert(failures,{asset=asset,status=status.Name})end end)end)
 task.wait(.4)
 info.assetFetchFailures=failures
 return H:JSONEncode(info)
end
return 'Generated-terrain ViewportFrame ready'
