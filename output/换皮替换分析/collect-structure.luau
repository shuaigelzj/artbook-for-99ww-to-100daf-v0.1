local H=game:GetService('HttpService')
assert(game.PlaceId==108983613755535 and not game:GetService('RunService'):IsRunning(),'Expected edit place')
local function safe(s) return utf8.len(s) and s or '[invalid UTF8 name]' end
local function uniqueAdd(list,seen,value,limit)
    value=safe(value)
    if not seen[value] and #list<limit then seen[value]=true table.insert(list,value) end
end
local results={}
for _,row in ipairs(AF_RESKIN_ROWS) do
    local source=workspace
    for index in string.gmatch(row.locator,'/(%d+)') do source=assert(source:GetChildren()[tonumber(index)],row.id) end
    assert(source.ClassName==row.class and (row.rawNameHex or source:GetFullName()==row.path),'Source mismatch '..row.id)
    local info={id=row.id,classes={},attachments={},joints={},interfaces={},values={},rigTypes={},visibleParts=0,solidParts=0,parts=0,topChildren={}}
    local seenA,seenJ,seenI,seenV,seenR={},{},{},{},{}
    for i,child in ipairs(source:GetChildren())do if i<=40 then table.insert(info.topChildren,safe(child.Name)..' ['..child.ClassName..']') end end
    local all=source:GetDescendants() table.insert(all,source)
    for i,obj in ipairs(all) do
        info.classes[obj.ClassName]=(info.classes[obj.ClassName] or 0)+1
        if obj:IsA('BasePart') then
            info.parts+=1
            if obj.Transparency<.98 then info.visibleParts+=1 end
            if obj.Transparency<.7 then info.solidParts+=1 end
            if obj==source then
                info.rootPart={size={obj.Size.X,obj.Size.Y,obj.Size.Z},transparency=obj.Transparency,material=obj.Material.Name,color={math.floor(obj.Color.R*255+.5),math.floor(obj.Color.G*255+.5),math.floor(obj.Color.B*255+.5)},shape=obj:IsA('Part') and obj.Shape.Name or nil}
            end
        elseif obj:IsA('Attachment') then uniqueAdd(info.attachments,seenA,obj.Name,16)
        elseif obj:IsA('Motor6D') or obj:IsA('JointInstance') then uniqueAdd(info.joints,seenJ,obj.Name,16)
        elseif obj:IsA('ValueBase') then uniqueAdd(info.values,seenV,obj.Name..' ['..obj.ClassName..']',18)
        elseif obj:IsA('Humanoid') then uniqueAdd(info.rigTypes,seenR,obj.RigType.Name,4)
        end
        if obj.Name=='RootPart' or obj.Name=='HumanoidRootPart' or obj.Name=='Handle' or obj.Name=='Core' or obj.Name=='Peak' or obj.Name=='RightDoor' or obj.Name=='LeftDoor' or obj.Name=='FireS2C' or obj.Name=='Muzzle' or obj.Name=='Seat' or obj.Name=='VehicleSeat' or obj:IsA('ProximityPrompt') or obj:IsA('ClickDetector') or obj:IsA('Seat') or obj:IsA('RemoteEvent') then uniqueAdd(info.interfaces,seenI,obj.Name..' ['..obj.ClassName..']',20) end
        if i%700==0 then task.wait() end
    end
    assert(info.parts==row.parts,'Part count changed '..row.id)
    table.insert(results,info)
    task.wait()
end
return H:JSONEncode(results)
