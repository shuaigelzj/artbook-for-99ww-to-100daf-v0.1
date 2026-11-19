local S=assert(_G.AFPreviewBulk)
S.baseOrigin=S.baseOrigin or S.origin
S.stageRoot=S.stageRoot or S.stage
S.preparePool=function(ids)
    local root=S.stageRoot
    root:ClearAllChildren()
    local records={}
    for index,id in ipairs(ids) do
        local cell=Instance.new('Folder')
        cell.Name=id..'_PreviewCell'
        cell.Parent=root
        S.stage=cell
        S.origin=S.baseOrigin+Vector3.new(((index-1)%3)*8000,0,math.floor((index-1)/3)*8000)
        local ok,result=pcall(S.render,id)
        S.stage=root
        S.origin=S.baseOrigin
        if not ok then error(result) end
        local record=game:GetService('HttpService'):JSONDecode(result)
        local p=S.camera.Focus.Position
        record.focus={p.X,p.Y,p.Z}
        record.captureMode='Studio scripted preview'
        assert(record.fieldOfView==35,'Pool requires a consistent field of view')
        table.insert(records,record)
        task.wait()
    end
    return game:GetService('HttpService'):JSONEncode(records)
end
return 'Preview pool ready'
