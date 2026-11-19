local H=game:GetService('HttpService')
local C=game:GetService('CollectionService')
local holder=game.ReplicatedStorage.__AF_TerrainConcept_Run
assert(holder:GetAttribute('Ready'),'Snapshot is not ready')
local run=H:JSONDecode(holder.SnapshotJSON.Value)
local rows={}
for _,p in ipairs(holder:GetChildren()) do if string.find(p.Name,'Grounds_',1,true) then for _,r in ipairs(H:JSONDecode(p.Value)) do table.insert(rows,r) end end end
local function choose(test,score)
 local best,value=nil,-math.huge
 for _,r in ipairs(rows) do if test(r) then local q=score and score(r) or 0 if q>value then best,value=r,q end end end
 return best
end
local function set(id,r)
 for _,s in ipairs(run.views) do if s.id==id then
  s.observed=r~=nil
  if r then s.center=r.position s.centerGrid=r.grid s.zone=r.zone s.typeName=r.typeName s.sourceCandidates=r.sources end
  return s
 end end
end
set('M02',choose(function(r)return r.typeName=='land' and r.position[2]>3 end,function(r)return r.position[2] end))
set('M09',choose(function(r)return r.typeName=='Snowfield' and r.position[2]>8 and r.position[2]<40 end,function(r)return -math.abs(r.position[2]-20) end))
set('M11',choose(function(r)return r.typeName=='Railway' end,function(r)return -math.abs(r.grid[1]-28)-math.abs(r.grid[2]-28) end))
local sp=choose(function(r)
 if r.typeName~='Snowfield' then return false end
 local g=workspace.Map:FindFirstChild(r.name)
 return g and g:FindFirstChild('池塘')~=nil
end)
set('M10',sp)
for _,b in ipairs(run.specialBuildings) do if string.find(b.name,'老矿镇',1,true) then
 local s=set('M03',{position={b.position[1],0,b.position[3]},grid={14,11},zone=4,typeName='Special',sources={}})
 s.title='下沉事件区与老矿镇' s.radius=4 s.includeBuilding=b.name
end end
local mountain=workspace:FindFirstChild('雪原') and workspace['雪原']:FindFirstChild('山')
if mountain then
 local cf,sz=mountain:GetBoundingBox()
 table.insert(run.views,{id='M15',title='雪山山体',observed=true,center={cf.X,60,cf.Z},radius=3,mountain=true,focusHeight=cf.Y-60})
end
for _,b in ipairs(run.specialBuildings) do if string.find(b.name,'1级铃铛洞穴',1,true) then
 table.insert(run.views,{id='M16',title='洞穴地表入口',observed=true,center={b.position[1],0,b.position[3]},radius=2,includeBuilding=b.name,trimBelow=-35}) break
end end
if sp then table.insert(run.views,{id='M10D',title='雪原池塘近景',observed=true,center=sp.position,centerGrid=sp.grid,radius=0,detail=true}) end
for _,id in ipairs({'M07','M08'}) do for _,s in ipairs(run.views) do if s.id==id and s.observed then table.insert(run.views,{id=id..'D',title=s.title..'近景',observed=true,center=s.center,centerGrid=s.centerGrid,radius=0,detail=true}) break end end end
local existing=holder:FindFirstChild('Samples') if existing then existing:Destroy() end
local samples=Instance.new('Folder') samples.Name='Samples' samples.Parent=holder
local function scrub(o,trimBelow)
 local list=o:GetDescendants() table.insert(list,o)
 for _,v in ipairs(list) do
  if v:IsA('LuaSourceContainer') or v:IsA('SurfaceGui') or v:IsA('BillboardGui') or v:IsA('Humanoid') then v:Destroy()
  elseif v:IsA('BasePart') then
   v.Anchored=true v.CanCollide=false v.CanTouch=false
   if trimBelow and v.Position.Y+v.Size.Y/2<trimBelow then v.Transparency=1 end
  end
 end
end
local decorations={}
for _,tag in ipairs({'Tree','BigTree','DecorativeStones'}) do for _,o in ipairs(C:GetTagged(tag)) do
 if o:IsDescendantOf(workspace) and not o:IsDescendantOf(workspace.Prefabs) then decorations[o]=true end
end end
for _,o in ipairs(workspace:GetChildren()) do
 if (o:IsA('Model') or o:IsA('BasePart')) and (string.find(o.Name,'草',1,true) or string.find(o.Name,'石块',1,true) or o.Name=='土地') then decorations[o]=true end
end
for _,s in ipairs(run.views) do if s.observed then
 local pos=Vector3.new(s.center[1],s.center[2],s.center[3])
 local span=(s.radius*2+1)*50
 local model=Instance.new('Model') model.Name=s.id
 local count,roots=0,0
 local function mount(o)
  if not o.Archivable then return end
  local cp=o:Clone() if not cp then return end
  scrub(cp,s.trimBelow)
  cp.Parent=model roots+=1
  count+=#cp:GetDescendants()+1
  if count>700 then task.wait() count=0 end
 end
 for _,g in ipairs(workspace.Map:GetChildren()) do if g:IsA('BasePart') then
  if math.abs(g.Position.X-pos.X)<=span/2-1 and math.abs(g.Position.Z-pos.Z)<=span/2-1 then mount(g) end
 end end
 if not s.detail then for o in pairs(decorations) do
  local cf=o:IsA('Model') and o:GetPivot() or o.CFrame
  if math.abs(cf.X-pos.X)<span/2 and math.abs(cf.Z-pos.Z)<span/2 and cf.Y>pos.Y-35 and cf.Y<pos.Y+200 then mount(o) end
 end end
 if s.includeBuilding then local b=workspace.Map:FindFirstChild(s.includeBuilding) if b then mount(b) end end
 if s.mountain and mountain then mount(mountain) end
 model.WorldPivot=CFrame.new(pos) model:PivotTo(CFrame.identity)
 local pivot=Instance.new('Part') pivot.Name='PreviewPivot' pivot.Size=Vector3.one pivot.Transparency=1 pivot.Anchored=true pivot.CanCollide=false pivot.Parent=model model.PrimaryPart=pivot
 s.displayScale=100/span model:ScaleTo(s.displayScale)
 s.span=span s.focusHeight=(s.focusHeight or 7)*s.displayScale s.clonedRoots=roots
 local parts=0 for _,v in ipairs(model:GetDescendants()) do if v:IsA('BasePart') then parts+=1 end end s.previewParts=parts
 model:SetAttribute('ShotJSON',H:JSONEncode(s))
 model.Parent=samples
 task.wait()
end end
run.sampledAt=workspace.DistributedGameTime
run.method='Live generated map -> disposable sampled clones -> Studio ViewportFrame. No realtime shadows, particles or exact Glass/Neon rendering.'
holder.SnapshotJSON.Value=H:JSONEncode(run)
holder:SetAttribute('SamplesReady',true)
return H:JSONEncode({samples=#samples:GetChildren(),views=run.views,types=run.types})
