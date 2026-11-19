
local ATTRIBUTE="__AFMapAudit_20261118"
local removed=0
for _,root in ipairs({workspace,game.ServerStorage}) do
 for i,v in ipairs(root:GetDescendants()) do
  if v:GetAttribute(ATTRIBUTE)~=nil then v:SetAttribute(ATTRIBUTE,nil) removed+=1 end
  if i%1000==0 then task.wait() end
 end
end
for _,name in ipairs({"__AFMapAudit_MainReady","__AFMapAudit_Ready","__AFMapAudit_ReadyAt","__AFMapAudit_Error"}) do workspace:SetAttribute(name,nil) end
local observer=game.ServerScriptService:FindFirstChild("__AFMapAuditObserver")
if observer then assert(observer:IsA("Script") and observer.Source:find('__AFMapAudit_Ready',1,true),"Unexpected observer contents") observer:Destroy() end
local remaining=0
for _,root in ipairs({workspace,game.ServerStorage}) do for i,v in ipairs(root:GetDescendants()) do if v:GetAttribute(ATTRIBUTE)~=nil then remaining+=1 end if i%1000==0 then task.wait() end end end
return game:GetService("HttpService"):JSONEncode({removed=removed,remaining=remaining,observerRemaining=game.ServerScriptService:FindFirstChild("__AFMapAuditObserver")~=nil,workspaceRoots=#workspace:GetChildren()})

