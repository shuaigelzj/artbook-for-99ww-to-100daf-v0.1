
local units={}
local folders={}
local function walk(parent,indices)
 for i,v in ipairs(parent:GetChildren()) do
  local loc=indices.."/"..i
  if v:IsA("Folder") then
   table.insert(folders,{name=v.Name,path=v:GetFullName(),locator=loc,children=#v:GetChildren()})
   walk(v,loc)
  elseif v:IsA("Model") or v:IsA("Tool") or v:IsA("Accessory") or v:IsA("BasePart") then
   table.insert(units,{obj=v,locator=loc})
  end
 end
end
walk(workspace,"W")
local function round(n) if n~=n or math.abs(n)==math.huge then return 0 end return math.floor(n*100+0.5)/100 end
local function vec(v) return {round(v.X),round(v.Y),round(v.Z)} end
local function data(entry,index)
 local v=entry.obj
 local ds=v:GetDescendants()
 local r={index=index,name=v.Name,path=v:GetFullName(),parent=v.Parent:GetFullName(),class=v.ClassName,locator=entry.locator,descendants=#ds,parts=0,meshes=0,scripts=0,animations=0,humanoids=0,anchored=0,collidable=0,children={},scriptNames={},tags=v:GetTags(),attrs={}}
 pcall(function() r.uid=tostring(v.UniqueId) end)
 for k,val in pairs(v:GetAttributes()) do r.attrs[k]=tostring(val) end
 for i,c in ipairs(v:GetChildren()) do if i<=14 then table.insert(r.children,c.Name.." ["..c.ClassName.."]") end end
 local geometry={} local meshIds={} local check={v} for _,d in ipairs(ds) do table.insert(check,d) end
 for _,d in ipairs(check) do
  if d:IsA("BasePart") then r.parts+=1 if d.Anchored then r.anchored+=1 end if d.CanCollide then r.collidable+=1 end end
  if d:IsA("MeshPart") or d:IsA("SpecialMesh") then r.meshes+=1 local mid=tostring(d.MeshId) if mid~="" then meshIds[mid]=true end end
  if d:IsA("BasePart") then
   local token=d.ClassName..":"..table.concat(vec(d.Size),",")
   if d:IsA("MeshPart") then token=token..":"..tostring(d.MeshId) end
   local sm=d:FindFirstChildWhichIsA("SpecialMesh") if sm then token=token..":"..tostring(sm.MeshId)..":"..table.concat(vec(sm.Scale),",") end
   table.insert(geometry,token)
  end
  if d:IsA("LuaSourceContainer") then r.scripts+=1 if #r.scriptNames<12 then table.insert(r.scriptNames,d.Name) end end
  if d:IsA("Humanoid") then r.humanoids+=1 end
  if d:IsA("Animation") then r.animations+=1 end
 end
 if v:IsA("Model") then pcall(function() local cf,s=v:GetBoundingBox() r.position=vec(cf.Position) r.size=vec(s) end)
 elseif v:IsA("BasePart") then r.position=vec(v.Position) r.size=vec(v.Size)
 else local h=v:FindFirstChild("Handle") if h and h:IsA("BasePart") then r.position=vec(h.Position) r.size=vec(h.Size) end end
 table.sort(geometry) local g=table.concat(geometry,";") local h=5381 for j=1,#g do h=(h*33+string.byte(g,j))%4294967296 end
 r.geometry=tostring(r.parts)..":"..tostring(h) r.meshIds={} for mid in pairs(meshIds) do table.insert(r.meshIds,mid) end table.sort(r.meshIds)
 local valid=pcall(function() game:GetService("HttpService"):JSONEncode({r.name}) end)
 if not valid then local hex={} for k=1,#r.name do table.insert(hex,string.format("%02X",string.byte(r.name,k))) end r.rawNameHex=table.concat(hex," ") r.name="[名称含无效UTF-8字节]" r.path=r.parent.."."..r.name end
 return r
end

