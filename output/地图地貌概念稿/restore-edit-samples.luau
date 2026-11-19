local S=assert(_G.AFMapConcept)
local H=game:GetService('HttpService')
local holder=Instance.new('Folder') holder.Name='__AF_TerrainConcept_Rebuilt' holder.Parent=game.ReplicatedStorage S.holder=holder
S.restore=function(rows)
 local added=0 local absent={}
 for _,r in ipairs(rows) do
  local p=nil
  if r.class=='UnionOperation' or r.class=='MeshPart' then
   local best,bestScore=nil,math.huge
   for _,candidate in ipairs(S.prototypes[r.class]) do
    local compatible=r.class~='MeshPart' or candidate.part.MeshId==r.mesh
    if compatible then
     local sz=candidate.size local wanted=Vector3.new(unpack(r.prototypeSize))
     local rx,ry,rz=wanted.X/sz.X,wanted.Y/sz.Y,wanted.Z/sz.Z
     local ratio=(rx+ry+rz)/3
     local variance=(math.abs(rx-ratio)+math.abs(ry-ratio)+math.abs(rz-ratio))/ratio
     if variance<.004 then
      local mass=math.abs(candidate.mass*ratio^3-r.prototypeMass)/math.max(r.prototypeMass,.001)
      if mass<.025 or r.class=='MeshPart' then
       local score=variance*100+mass*10+math.abs(math.log(ratio))*.05+(candidate.name==r.name and 0 or .001)
       if score<bestScore then best,bestScore=candidate,score end
      end
     end
    end
   end
   if best then
    p=best.part:Clone()
    local sa=p:FindFirstChildOfClass('SurfaceAppearance') sa=sa and sa:Clone()
    p:ClearAllChildren() if sa then sa.Parent=p end
   else table.insert(absent,{shot=r.shot,class=r.class,name=r.name,size=r.prototypeSize,mass=r.prototypeMass,mesh=r.mesh}) end
  else p=Instance.new(r.class) end
  if p then
   p.Name=r.name p.Size=Vector3.new(unpack(r.size)) p.CFrame=CFrame.new(unpack(r.cf))
   p.Color=Color3.new(unpack(r.color)) p.Material=Enum.Material[r.material] p.Transparency=r.trans p.Reflectance=r.reflect
   p.Anchored=true p.CanCollide=false p.CanTouch=false
   if r.shape and p:IsA('Part') then p.Shape=Enum.PartType[r.shape] end
   if r.texture and p:IsA('MeshPart') then p.TextureID=r.texture end
   if r.usePartColor~=nil and p:IsA('UnionOperation') then p.UsePartColor=r.usePartColor end
   for _,a in ipairs(r.details) do
    local c=Instance.new(a.class)
    if a.class=='SpecialMesh' then
     c.MeshType=Enum.MeshType[a.meshType] c.MeshId=a.mesh c.TextureId=a.texture c.Scale=Vector3.new(unpack(a.scale)) c.Offset=Vector3.new(unpack(a.offset)) c.VertexColor=Vector3.new(unpack(a.vertex))
    else
     c.Texture=a.texture c.Face=Enum.NormalId[a.face] c.Color3=Color3.new(unpack(a.color)) c.Transparency=a.trans
     if a.class=='Texture' then c.StudsPerTileU=a.u c.StudsPerTileV=a.v c.OffsetStudsU=a.ou c.OffsetStudsV=a.ov end
    end
    c.Parent=p
   end
   if not S.samples[r.shot] then local model=Instance.new('Model') model.Name=r.shot model.Parent=holder S.samples[r.shot]=model end
   p.Parent=S.samples[r.shot] added+=1
  end
 end
 S.restoredParts+=added
 for _,a in ipairs(absent) do table.insert(S.unmatched,a) end
 return H:JSONEncode({added=added,total=S.restoredParts,unmatched=absent})
end
local gui=Instance.new('ScreenGui') gui.Name='__AF_TerrainConcept_Viewport' gui.IgnoreGuiInset=true gui.ResetOnSpawn=false gui.DisplayOrder=1000000 S.gui=gui
local frame=Instance.new('ViewportFrame') frame.Name='TerrainViewport' frame.Size=UDim2.fromScale(1,1) frame.BorderSizePixel=0 frame.BackgroundColor3=Color3.fromRGB(64,73,81)
frame.Ambient=Color3.fromRGB(150,150,150) frame.LightColor=Color3.fromRGB(195,190,180) frame.LightDirection=Vector3.new(-.7,-1,-.4) frame.Parent=gui
local world=Instance.new('WorldModel') world.Parent=frame
local cam=Instance.new('Camera') cam.FieldOfView=42 cam.Parent=frame frame.CurrentCamera=cam
local badge=Instance.new('TextLabel') badge.BackgroundTransparency=.18 badge.BackgroundColor3=Color3.fromRGB(22,28,33) badge.Size=UDim2.new(1,0,0,24) badge.Position=UDim2.new(0,0,1,-24) badge.TextColor3=Color3.fromRGB(230,235,238) badge.Font=Enum.Font.SourceSans badge.TextSize=15 badge.Parent=gui
gui.Parent=game.StarterGui
S.show=function(info)
 world:ClearAllChildren()
 local copy=assert(S.samples[info.id],'Missing restored sample'):Clone() copy.Parent=world
 local focus=Vector3.new(0,info.focusHeight,0)
 local reach=info.mountain and 180 or 100
 cam.CFrame=CFrame.lookAt(focus+Vector3.new(.65,1.03,1.0)*reach,focus) cam.Focus=CFrame.new(focus)
 badge.Text=info.id..' '..info.title..' | 实生样区几何还原 · 静态视窗（无实时阴影/动态特效）'
 local failures={}
 pcall(function()game.ContentProvider:PreloadAsync({copy},function(asset,status)if status~=Enum.AssetFetchStatus.Success then table.insert(failures,{asset=asset,status=status.Name})end end)end)
 task.wait(.6)
 return H:JSONEncode({id=info.id,failures=failures,parts=#copy:GetChildren()})
end
return 'Edit-time generated-map reconstruction and screenshot viewer ready'
