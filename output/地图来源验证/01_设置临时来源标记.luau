
local ATTRIBUTE="__AFMapAudit_20261118"
local units={}
local function walk(parent,loc)
 for i,v in ipairs(parent:GetChildren()) do
  local childLoc=loc.."/"..i
  if v:IsA("Folder") then walk(v,childLoc)
  elseif v:IsA("Model") or v:IsA("Tool") or v:IsA("Accessory") or v:IsA("BasePart") then table.insert(units,{obj=v,locator=childLoc}) end
 end
end
walk(workspace,"W")
assert(#units==905,"Inventory changed; stop before marking: "..#units)
local roots={workspace,game.ServerStorage}
for _,root in ipairs(roots) do for _,v in ipairs(root:GetDescendants()) do assert(v:GetAttribute(ATTRIBUTE)==nil,"Existing audit attribute") end end
local marked=0
local function mark(v,value) v:SetAttribute(ATTRIBUTE,value) marked+=1 end
for i,e in ipairs(units) do
 local value=(e.obj:IsDescendantOf(workspace.Prefabs) and "P:" or "L:")..string.format("AF-%04d",i)
 mark(e.obj,value)
 for _,d in ipairs(e.obj:GetDescendants()) do if d:IsA("BasePart") then mark(d,value) end end
 if i%20==0 then task.wait() end
end
local ext=0
for i,d in ipairs(game.ServerStorage:GetDescendants()) do
 if d:IsA("BasePart") then ext+=1 mark(d,"S:"..d:GetFullName()) end
 if i%1000==0 then task.wait() end
end
return game:GetService("HttpService"):JSONEncode({units=#units,marked=marked,serverStorageParts=ext,attribute=ATTRIBUTE})

