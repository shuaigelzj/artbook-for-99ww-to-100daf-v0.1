local state=assert(_G.AFBenchLevels,'No preview session')
for _,m in ipairs(state.models) do m:Destroy() end
if state.previewGui then state.previewGui:Destroy() end
state.stage:Destroy()
local light=game:GetService('Lighting')
for key,value in pairs(state.savedLighting) do light[key]=value end
for obj,value in pairs(state.savedEffects) do if obj.Parent then obj.Enabled=value end end
for obj,value in pairs(state.savedGui) do if obj.Parent then obj.Enabled=value end end
for obj,props in pairs(state.savedAtmospheres) do if obj.Parent then for key,value in pairs(props) do obj[key]=value end end end
for key,value in pairs(state.savedCamera) do state.camera[key]=value end
local intact=0
for level,source in ipairs(state.sources) do
    local original=state.originals[level]
    local good=source.Parent==original.parent and source:GetPivot()==original.pivot
    local actual=0 local expected=0
    for _,d in ipairs(source:GetDescendants()) do if d:IsA('BasePart') then actual+=1 end end
    for part,p in pairs(original.parts) do
        expected+=1
        good=good and part:IsDescendantOf(source) and part.CFrame==p.cframe and part.Transparency==p.transparency and part.Color==p.color and part.Material==p.material and part.Size==p.size
    end
    if good and actual==expected then intact+=1 end
end
local lightingRestored=true local guiRestored=true local cameraRestored=true
for key,value in pairs(state.savedLighting) do lightingRestored=lightingRestored and light[key]==value end
for obj,value in pairs(state.savedGui) do guiRestored=guiRestored and obj.Enabled==value end
for key,value in pairs(state.savedCamera) do cameraRestored=cameraRestored and state.camera[key]==value end
_G.AFBenchLevels=nil
return {cleaned=not workspace:FindFirstChild('__AF_BenchLevelPreview'),sourcesIntact=intact,lightingRestored=lightingRestored,guiRestored=guiRestored,cameraRestored=cameraRestored}
