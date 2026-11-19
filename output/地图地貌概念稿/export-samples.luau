local H=game:GetService('HttpService')
local holder=game.ReplicatedStorage.__AF_TerrainConcept_Run
local records={}
local function vec(v)return {v.X,v.Y,v.Z}end
local function rgb(v)return {v.R,v.G,v.B}end
for _,model in ipairs(holder.Samples:GetChildren()) do
 local info=H:JSONDecode(model:GetAttribute('ShotJSON'))
 for _,p in ipairs(model:GetDescendants()) do if p:IsA('BasePart') and p.Name~='PreviewPivot' then
  local details={}
  for _,c in ipairs(p:GetChildren()) do
   if c:IsA('SpecialMesh') then table.insert(details,{class='SpecialMesh',mesh=c.MeshId,texture=c.TextureId,meshType=c.MeshType.Name,scale=vec(c.Scale),offset=vec(c.Offset),vertex=vec(c.VertexColor)})
   elseif c:IsA('Texture') then table.insert(details,{class='Texture',texture=c.Texture,face=c.Face.Name,u=c.StudsPerTileU,v=c.StudsPerTileV,ou=c.OffsetStudsU,ov=c.OffsetStudsV,color=rgb(c.Color3),trans=c.Transparency})
   elseif c:IsA('Decal') then table.insert(details,{class='Decal',texture=c.Texture,face=c.Face.Name,color=rgb(c.Color3),trans=c.Transparency})
   end
  end
  table.insert(records,{shot=info.id,class=p.ClassName,name=p.Name,size=vec(p.Size),cf={p.CFrame:GetComponents()},color=rgb(p.Color),material=p.Material.Name,trans=p.Transparency,reflect=p.Reflectance,
   mesh=p:IsA('MeshPart') and p.MeshId or nil,texture=p:IsA('MeshPart') and p.TextureID or nil,
   prototypeSize=vec(p.Size/info.displayScale),prototypeMass=p:GetMass()/info.displayScale^3,
   shape=p:IsA('Part') and p.Shape.Name or nil,usePartColor=p:IsA('UnionOperation') and p.UsePartColor or nil,details=details})
 end end
end
_G.AFTerrainExport={records=records,summary=H:JSONDecode(holder.SnapshotJSON.Value)}
return H:JSONEncode({parts=#records,summary=_G.AFTerrainExport.summary})
