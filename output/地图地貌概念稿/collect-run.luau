local H=game:GetService('HttpService')
local C=game:GetService('CollectionService')
local M=require(game.ReplicatedStorage.src.Helpers.MapHelper)
assert(M.isInit,'Actual server map is not initialized')
local old=game.ReplicatedStorage:FindFirstChild('__AF_TerrainConcept_Run') if old then old:Destroy() end
local holder=Instance.new('Folder') holder.Name='__AF_TerrainConcept_Run' holder.Parent=game.ReplicatedStorage
local run={id='terrain-one-run-20261119',readyAt=workspace:GetAttribute('__AFTerrainConcept_ReadyAt'),sampleAt=workspace.DistributedGameTime,grid=55,cell=50,types={},sources={},grounds={},views={},folders={}}
local map=workspace:FindFirstChild('Map')
local templates=workspace.Prefabs.Map:FindFirstChild('地块')
local function fingerprint(root)
 local a={}
 local all=root:GetDescendants() table.insert(all,root)
 for _,o in ipairs(all) do if o:IsA('BasePart') and o.Transparency<.99 then
  local p=root.CFrame:PointToObjectSpace(o.Position)
  table.insert(a,string.format('%s:%.2f,%.2f,%.2f:%.2f,%.2f,%.2f:%s:%d,%d,%d:%s',o.ClassName,o.Size.X,o.Size.Y,o.Size.Z,p.X,p.Y,p.Z,o.Material.Name,math.floor(o.Color.R*255+.5),math.floor(o.Color.G*255+.5),math.floor(o.Color.B*255+.5),o:IsA('MeshPart') and o.MeshId or ''))
 end end
 table.sort(a) return table.concat(a,'|')
end
local fps={}
for _,t in ipairs(templates:GetChildren()) do if t:IsA('BasePart') then local k=fingerprint(t) fps[k]=fps[k] or {} table.insert(fps[k],t.Name) end end
local typeNames={}for k,v in pairs(M.GridType) do typeNames[v]=k end
local byGrid={}
for i,g in ipairs(C:GetTagged('Ground')) do
 if g:IsA('BasePart') and g:IsDescendantOf(map) then
  local x,z=string.match(g.Name,'^(%d+),(%d+)$') x=tonumber(x) z=tonumber(z)
  if x and z then
   local t=M:GetMapGridType(x,z)
   local matches=fps[fingerprint(g)] or {}
   local r={name=g.Name,grid={x,z},position={g.Position.X,g.Position.Y,g.Position.Z},top=g.Position.Y+g.Size.Y/2,type=t,typeName=typeNames[t],zone=M:GetZoneLevelByGrid1(x,z),sources=matches,tags=g:GetTags()}
   table.insert(run.grounds,r) byGrid[g.Name]={part=g,row=r}
   run.types[r.typeName or tostring(t)]=(run.types[r.typeName or tostring(t)] or 0)+1
   for _,n in ipairs(matches) do run.sources[n]=(run.sources[n] or 0)+1 end
  end
 end
 if i%300==0 then task.wait() end
end
local specs={
 {id='M01',title='普通草原',source='Grassland',radius=2,zoneMin=2,zoneMax=4},
 {id='M02',title='高原山丘',source='高原地区地块',radius=3,height='max'},
 {id='M03',title='低位盆地',source='低位地区地块',radius=3,height='min'},
 {id='M04',title='普通池塘',source='池塘',radius=1},
 {id='M05',title='沼泽地表',source='沼泽地块',radius=2},
 {id='M06',title='沼泽水地',source='沼泽水地块',radius=2},
 {id='M07',title='毒沼泽',source='沼泽地块-毒沼泽',radius=1},
 {id='M08',title='泥沼泽',source='沼泽地块-泥沼泽',radius=1},
 {id='M09',title='雪原地表',source='雪原地块',radius=2},
 {id='M10',title='雪原池塘',source='雪原池塘',radius=1},
 {id='M11',title='铁路路基',source='铁轨路',radius=2},
 {id='M12',title='5级区域地表',source='5级地块',radius=2},
 {id='M13',title='6级区域地表',source='6级地块',radius=2},
 {id='M14',title='雷神锤事件坑',source='雷神锤子专属地块',radius=3}
}
local function has(r,n) return table.find(r.sources,n)~=nil end
for _,s in ipairs(specs) do
 local best,score=nil,-math.huge
 for _,r in ipairs(run.grounds) do if has(r,s.source) and (not s.zoneMin or r.zone>=s.zoneMin) and (not s.zoneMax or r.zone<=s.zoneMax) then
  local n=0
  for dx=-s.radius,s.radius do for dz=-s.radius,s.radius do local b=byGrid[(r.grid[1]+dx)..','..(r.grid[2]+dz)] if b and has(b.row,s.source) then n+=1 end end end
  local q=s.height=='max' and r.position[2]*100+n or s.height=='min' and -r.position[2]*100+n or n
  if q>score then best=r score=q end
 end end
 if best then
  s.center=best.position s.centerGrid=best.grid s.zone=best.zone s.observed=true s.sourceCandidates=best.sources
 else s.observed=false end
 table.insert(run.views,s)
end
for _,name in ipairs({'雪原','沼泽','火车大劫案'}) do
 local f=workspace:FindFirstChild(name) local a={}
 if f then for _,o in ipairs(f:GetChildren()) do
  if o:IsA('Model') then local cf,sz=o:GetBoundingBox() table.insert(a,{name=o.Name,class=o.ClassName,position={cf.X,cf.Y,cf.Z},size={sz.X,sz.Y,sz.Z}}) end
 end end
 run.folders[name]=a
end
local buildings={}
for _,o in ipairs(map:GetChildren()) do if o:IsA('Model') and (string.find(o.Name,'洞穴',1,true) or string.find(o.Name,'老矿镇',1,true)) then
 local cf,sz=o:GetBoundingBox() table.insert(buildings,{name=o.Name,position={cf.X,cf.Y,cf.Z},size={sz.X,sz.Y,sz.Z}})
end end
run.specialBuildings=buildings
local grounds=run.grounds run.grounds=nil run.groundCount=#grounds
local f=Instance.new('StringValue') f.Name='SnapshotJSON' f.Value=H:JSONEncode(run) f.Parent=holder
for first=1,#grounds,150 do
 local rows={} for i=first,math.min(first+149,#grounds) do table.insert(rows,grounds[i]) end
 local v=Instance.new('StringValue') v.Name=string.format('Grounds_%03d',math.ceil(first/150)) v.Value=H:JSONEncode(rows) v.Parent=holder
 task.wait()
end
holder:SetAttribute('Ready',true)
print('AF terrain snapshot ready',#grounds,#f.Value)
