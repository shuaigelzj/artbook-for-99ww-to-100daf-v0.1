local state=assert(_G.AFPreview50,'No preview session')
state.stage:Destroy()
local light=game:GetService('Lighting')
for key,value in pairs(state.savedLighting) do light[key]=value end
for obj,enabled in pairs(state.savedEffects) do if obj.Parent then obj.Enabled=enabled end end
for obj,enabled in pairs(state.savedGui) do if obj.Parent then obj.Enabled=enabled end end
for obj,props in pairs(state.savedAtmospheres) do if obj.Parent then for key,value in pairs(props) do obj[key]=value end end end
local cam=state.camera
cam.CameraType=state.cameraType
cam.FieldOfView=state.cameraFOV
cam.CFrame=state.cameraCFrame
cam.Focus=state.cameraFocus
local sourcesIntact=0
for id,obj in pairs(state.sources) do
    local parts=obj:IsA('BasePart') and 1 or 0
    for _,child in ipairs(obj:GetDescendants()) do if child:IsA('BasePart') then parts+=1 end end
    if obj:IsDescendantOf(workspace) and obj:GetFullName()==state.rows[id].path and parts==state.rows[id].parts then sourcesIntact+=1 end
end
local lightingRestored=true
for key,value in pairs(state.savedLighting) do if light[key]~=value then lightingRestored=false end end
local guiRestored=true
for obj,enabled in pairs(state.savedGui) do if obj.Enabled~=enabled then guiRestored=false end end
local cameraRestored=cam.CFrame==state.cameraCFrame and cam.FieldOfView==state.cameraFOV and cam.CameraType==state.cameraType
_G.AFPreview50=nil
return game:GetService('HttpService'):JSONEncode({cleaned=not workspace:FindFirstChild('__AF_CatalogPreview_50'),sourcesIntact=sourcesIntact,cameraRestored=cameraRestored,lightingRestored=lightingRestored,guiRestored=guiRestored})
