-- Run only in Edit. All source references are cached before adding the temporary stage.
local H = game:GetService('HttpService')
assert(game.PlaceId == 108983613755535, 'Unexpected place')
assert(not game:GetService('RunService'):IsRunning(), 'Edit mode required')
assert(not _G.AFPreview50, 'Preview session already exists')
assert(not workspace:FindFirstChild('__AF_CatalogPreview_50'), 'Temporary stage already exists')
local state = {sources = {}, rows = {}, savedLighting = {}, savedEffects = {}, savedAtmospheres = {}}
local camera = workspace.CurrentCamera
state.camera = camera
state.cameraCFrame = camera.CFrame
state.cameraFocus = camera.Focus
state.cameraType = camera.CameraType
state.cameraFOV = camera.FieldOfView
local function resolve(locator)
    local current = workspace
    for index in string.gmatch(locator, '/(%d+)') do
        current = current:GetChildren()[tonumber(index)]
        assert(current, 'Invalid locator: ' .. locator)
    end
    return current
end
for _, row in ipairs(AF_PREVIEW_ROWS) do
    local source = resolve(row.locator)
    assert(source:GetFullName() == row.path, 'Asset path changed: ' .. row.id)
    local parts, visible = 0, 0
    local all = source:GetDescendants()
    table.insert(all, source)
    for _, part in ipairs(all) do
        if part:IsA('BasePart') then
            parts += 1
            if part.Transparency < 0.98 then visible += 1 end
        end
    end
    assert(parts == row.parts, 'Asset part count changed: ' .. row.id)
    state.sources[row.id] = source
    state.rows[row.id] = row
end
_G.AFPreview50 = state
state.savedGui = {}
for _, obj in ipairs(game:GetService('StarterGui'):GetDescendants()) do
    if obj:IsA('ScreenGui') then state.savedGui[obj] = obj.Enabled obj.Enabled = false end
end
local light = game:GetService('Lighting')
for key, value in pairs({ClockTime=14, Brightness=2, Ambient=Color3.fromRGB(130,130,130), OutdoorAmbient=Color3.fromRGB(145,145,145), FogStart=900000, FogEnd=1000000, GlobalShadows=true, ExposureCompensation=0}) do
    state.savedLighting[key] = light[key]
    light[key] = value
end
for _, obj in ipairs(light:GetChildren()) do
    if obj:IsA('PostEffect') then
        state.savedEffects[obj] = obj.Enabled
        obj.Enabled = false
    elseif obj:IsA('Atmosphere') then
        state.savedAtmospheres[obj] = {Density=obj.Density, Haze=obj.Haze, Glare=obj.Glare}
        obj.Density = 0
        obj.Haze = 0
        obj.Glare = 0
    end
end
local stage = Instance.new('Folder')
stage.Name = '__AF_CatalogPreview_50'
stage.Parent = workspace
state.stage = stage
state.origin = Vector3.new(20000,10000,-20000)
camera.CameraType = Enum.CameraType.Scriptable
camera.FieldOfView = 35
return H:JSONEncode({ready=true,assets=#AF_PREVIEW_ROWS,viewport={camera.ViewportSize.X,camera.ViewportSize.Y}})
