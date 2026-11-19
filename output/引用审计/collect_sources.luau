
local HttpService=game:GetService("HttpService")
local roots={workspace,game.ServerScriptService,game.ReplicatedStorage,game.ReplicatedFirst,game.ServerStorage,game.StarterGui,game.StarterPlayer,game.StarterPack}
local units={}
local owner={}
local function walk(p,loc)
 for i,v in ipairs(p:GetChildren()) do local l=loc.."/"..i
  if v:IsA("Folder") then walk(v,l)
  elseif v:IsA("Model") or v:IsA("Tool") or v:IsA("Accessory") or v:IsA("BasePart") then table.insert(units,{obj=v,locator=l}) owner[v]=string.format("AF-%04d",#units) end
 end
end
walk(workspace,"W")
assert(#units==905,"Asset snapshot changed")
local function safe(s) local ok=pcall(function() HttpService:JSONEncode({s}) end) return ok and s or "[invalid UTF-8]" end
local function segments(v) local t={} while v and v~=game do table.insert(t,1,safe(v.Name)) v=v.Parent end return t end
local function assetOf(v) while v and v~=game do if owner[v] then return owner[v] end v=v.Parent end end
local out={version=game.PlaceVersion,assets={},scripts={},sources={},properties={},unreadable={},sourceEncodingErrors={}}
for _,e in ipairs(units) do table.insert(out.assets,{id=owner[e.obj],segments=segments(e.obj),locator=e.locator}) end
local sourceIds={}
local propertyKeys={"Value","PrimaryPart","Part0","Part1","Attachment0","Attachment1","Adornee","CameraSubject"}
local scanned=0
for _,root in ipairs(roots) do
 for _,v in ipairs(root:GetDescendants()) do
  scanned+=1
  if v:IsA("LuaSourceContainer") then
   local ok,src=pcall(function() return v.Source end)
   if ok then
    local valid=pcall(function() HttpService:JSONEncode({src}) end)
    if valid then
     local id=sourceIds[src]
     if not id then id=#out.sources+1 sourceIds[src]=id table.insert(out.sources,{id=id,text=src}) end
     local meta={path=safe(v:GetFullName()),segments=segments(v),class=v.ClassName,sourceId=id,owner=assetOf(v)}
     if v:IsA("BaseScript") then meta.enabled=v.Enabled end
     table.insert(out.scripts,meta)
    else table.insert(out.sourceEncodingErrors,safe(v:GetFullName())) end
   else table.insert(out.unreadable,safe(v:GetFullName())) end
  end
  if v:IsA("ObjectValue") or v:IsA("Model") or v:IsA("JointInstance") or v:IsA("WeldConstraint") or v:IsA("Constraint") or v:IsA("Beam") or v:IsA("Trail") or v:IsA("BillboardGui") or v:IsA("SurfaceGui") or v:IsA("Camera") then
   for _,key in ipairs(propertyKeys) do
    local ok,target=pcall(function() return v[key] end)
    if ok and typeof(target)=="Instance" then local targetOwner=assetOf(target) local fromOwner=assetOf(v)
     if targetOwner and targetOwner~=fromOwner then table.insert(out.properties,{path=safe(v:GetFullName()),property=key,fromOwner=fromOwner,target=targetOwner,targetPath=safe(target:GetFullName())}) end
    end
   end
  end
  if scanned%1500==0 then task.wait() end
 end
end
_G.__AFReferenceAudit=HttpService:JSONEncode(out)
return HttpService:JSONEncode({bytes=#_G.__AFReferenceAudit,scripts=#out.scripts,uniqueSources=#out.sources,properties=#out.properties,unreadable=#out.unreadable,encodingErrors=#out.sourceEncodingErrors,version=out.version})

