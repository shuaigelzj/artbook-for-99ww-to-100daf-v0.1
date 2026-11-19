local helper=require(game.ReplicatedStorage.src.Helpers.MapHelper)
local deadline=os.clock()+180
while not helper.isInit and os.clock()<deadline do task.wait(.25) end
workspace:SetAttribute("__AFMapAudit_MainReady",helper.isInit)
if helper.isInit then
 task.wait(5)
 workspace:SetAttribute("__AFMapAudit_Ready",true)
 workspace:SetAttribute("__AFMapAudit_ReadyAt",workspace.DistributedGameTime)
else
 workspace:SetAttribute("__AFMapAudit_Error","Map generation timeout")
end
