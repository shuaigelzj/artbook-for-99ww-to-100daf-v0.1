local S=assert(_G.AFPreviewBulk)
local H=game:GetService('HttpService')
S.prepareViewportPool=function(ids)
    if S.viewportPoolConnection then S.viewportPoolConnection:Disconnect() S.viewportPoolConnection=nil end
    if S.viewportPoolGuis then for _,entry in ipairs(S.viewportPoolGuis) do entry.gui:Destroy() end end
    if S.previewGui then S.previewGui:Destroy() S.previewGui=nil end
    S.viewportPoolGuis={}
    S.stageRoot=S.stageRoot or S.stage
    S.baseOrigin=S.baseOrigin or S.origin
    S.stageRoot:ClearAllChildren()
    S.keepViewportPool=true
    local records={}
    for index,id in ipairs(ids) do
        local cell=Instance.new('Folder') cell.Name=id..'_ViewportCell' cell.Parent=S.stageRoot
        S.stage=cell S.origin=S.baseOrigin+Vector3.new(((index-1)%3)*8000,0,math.floor((index-1)/3)*8000)
        local ok,result=pcall(S.render,id)
        S.stage=S.stageRoot S.origin=S.baseOrigin
        if not ok then S.keepViewportPool=false error(result) end
        local record=H:JSONDecode(result)
        local pos=Vector3.new(record.camera[1],record.camera[2],record.camera[3])
        S.previewGui.Enabled=false
        table.insert(S.viewportPoolGuis,{gui=S.previewGui,position=pos,id=id})
        -- Focus is a point on the same camera look axis; native capture uses this direction.
        record.focus={pos.X-record.camera[6]*20,pos.Y-record.camera[9]*20,pos.Z-record.camera[12]*20}
        record.captureMode='Studio scripted viewport pool'
        table.insert(records,record)
    end
    S.keepViewportPool=false S.previewGui=nil
    local selected=nil
    local function activate()
        local p=S.camera.CFrame.Position
        local best,bestDistance=nil,math.huge
        for _,entry in ipairs(S.viewportPoolGuis) do local d=(entry.position-p).Magnitude if d<bestDistance then best=entry bestDistance=d end end
        if best and best~=selected then
            for _,entry in ipairs(S.viewportPoolGuis) do entry.gui.Enabled=entry==best end
            selected=best
        end
    end
    S.viewportPoolConnection=S.camera:GetPropertyChangedSignal('CFrame'):Connect(activate)
    activate()
    return H:JSONEncode(records)
end
return 'Viewport capture pool ready'
