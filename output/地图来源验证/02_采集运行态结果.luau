
local ATTRIBUTE="__AFMapAudit_20261118"
local HttpService=game:GetService("HttpService")
if not workspace:GetAttribute("__AFMapAudit_Ready") then return HttpService:JSONEncode({ready=false,time=workspace.DistributedGameTime,error=workspace:GetAttribute("__AFMapAudit_Error")}) end
local map=workspace:FindFirstChild("Map")
local function summarize(root)
 local out={parts=0,prefabParts=0,looseParts=0,externalParts=0,unmarkedParts=0,sources={},unmarked={},outside={}}
 if not root then return out end
 local signature=5381
 for i,d in ipairs(root:GetDescendants()) do
  if d:IsA("BasePart") then
   out.parts+=1
   local origin=d:GetAttribute(ATTRIBUTE)
   if origin then
    out.sources[origin]=(out.sources[origin] or 0)+1
    local kind=origin:sub(1,2)
    if kind=="P:" then out.prefabParts+=1 elseif kind=="L:" then out.looseParts+=1 if #out.outside<30 then table.insert(out.outside,{origin=origin,path=d:GetFullName()}) end else out.externalParts+=1 end
   else
    out.unmarkedParts+=1
    if #out.unmarked<50 then table.insert(out.unmarked,{path=d:GetFullName(),class=d.ClassName,size=tostring(d.Size)}) end
   end
   local token=d.Name..":"..tostring(d.Position)..":"..tostring(origin)
   for k=1,#token do signature=(signature*33+string.byte(token,k))%4294967296 end
  end
  if i%1000==0 then task.wait() end
 end
 out.signature=tostring(signature)
 return out
end
local result={ready=true,time=workspace.DistributedGameTime,map=summarize(map),retainedLoose={},runtimeRoots={}}
local function safeName(v) local ok=pcall(function() HttpService:JSONEncode({v.Name}) end) return ok and v.Name or "[invalid UTF-8 name]" end
local function walk(parent)
 for _,v in ipairs(parent:GetChildren()) do
  if v:IsA("Folder") then if v~=workspace:FindFirstChild("Prefabs") then walk(v) end
  elseif v:IsA("Model") or v:IsA("Tool") or v:IsA("Accessory") or v:IsA("BasePart") then
   local origin=v:GetAttribute(ATTRIBUTE)
   if origin and origin:sub(1,2)=="L:" then table.insert(result.retainedLoose,{origin=origin,name=safeName(v),parent=v.Parent:GetFullName(),class=v.ClassName}) end
  end
 end
end
walk(workspace)
for _,v in ipairs(workspace:GetChildren()) do
 if v~=map and v~=workspace:FindFirstChild("Prefabs") and (v:IsA("Folder") or v:IsA("Model")) and not v:GetAttribute(ATTRIBUTE) then
  local summary=summarize(v)
  if summary.parts>0 then table.insert(result.runtimeRoots,{name=v.Name,summary=summary}) end
 end
end
return HttpService:JSONEncode(result)

