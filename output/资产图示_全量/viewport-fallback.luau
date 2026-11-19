-- Render only disposable preview copies through Studio UI when native scene captures are blank.
local S=assert(_G.AFPreviewBulk)
local H=game:GetService('HttpService')
local core=S.render
S.render=function(id)
    if S.previewGui and not S.keepViewportPool then S.previewGui:Destroy() S.previewGui=nil end
    local record=H:JSONDecode(core(id))
    local gui=Instance.new('ScreenGui')
    gui.Name='__AF_CatalogViewportPreview'
    gui.IgnoreGuiInset=true gui.ResetOnSpawn=false gui.DisplayOrder=1000000
    S.previewGui=gui
    local surface=nil
    local effects,solidParts,classes=0,0,{}
    local source=S.sources[id]
    local objects=source:GetDescendants() table.insert(objects,source)
    for _,obj in ipairs(objects) do
        classes[obj.ClassName]=(classes[obj.ClassName] or 0)+1
        if obj:IsA('ParticleEmitter') or obj:IsA('Beam') or obj:IsA('Trail') or obj:IsA('Fire') or obj:IsA('Smoke') or obj:IsA('Sparkles') then effects+=1 end
        if obj:IsA('BasePart') and obj.Transparency<.7 then solidParts+=1 end
    end
    if effects>0 and solidParts==0 then
        local summary={} for name,count in pairs(classes) do table.insert(summary,name..' × '..count) end table.sort(summary)
        surface=Instance.new('SurfaceGui') surface.CanvasSize=Vector2.new(1400,700) surface.Parent=S.stage
        S.label(surface,'AFTER FALL / EFFECT STRUCTURE',45,65,28,Color3.fromRGB(155,182,170))
        S.label(surface,id..'  '..S.rows[id].name,145,120,48)
        S.label(surface,'主要视觉由特效构成，静态视窗不呈现动态效果。\n'..table.concat(summary,'；')..'\n本图保留原对象结构信息。',310,270,30)
        record.method='说明卡'
        record.note='原对象有 '..effects..' 个动态特效组件，缺少不透明的实体主体；ViewportFrame 不完整支持这些效果，因此使用结构说明卡。原对象与特效参数未修改。'
    end
    if record.method=='说明卡' or record.method=='界面演示' then
        for _,obj in ipairs(S.stage:GetDescendants()) do if obj:IsA('SurfaceGui') then surface=obj break end end
    end
    if surface then
        local background=Instance.new('Frame')
        background.Size=UDim2.fromScale(1,1) background.BorderSizePixel=0
        local textCount,darkText=0,0
        if record.method=='界面演示' then
            for _,obj in ipairs(objects) do
                if (obj:IsA('TextLabel') or obj:IsA('TextButton')) and obj.Text~='' then
                    textCount+=1
                    if math.max(obj.TextColor3.R,obj.TextColor3.G,obj.TextColor3.B)<.3 then darkText+=1 end
                end
            end
        end
        local lightBackdrop=textCount>0 and darkText==textCount
        background.BackgroundColor3=lightBackdrop and Color3.fromRGB(220,225,226) or Color3.fromRGB(22,29,32)
        background.Parent=gui
        local canvas=Instance.new('Frame')
        canvas.BackgroundTransparency=1 canvas.AnchorPoint=Vector2.new(.5,.5)
        canvas.Position=UDim2.fromScale(.5,.5) canvas.Size=UDim2.fromOffset(surface.CanvasSize.X,surface.CanvasSize.Y)
        canvas.Parent=background
        local scale=Instance.new('UIScale')
        scale.Scale=math.min(S.camera.ViewportSize.X/surface.CanvasSize.X,S.camera.ViewportSize.Y/surface.CanvasSize.Y)/1.13
        scale.Parent=canvas
        for _,child in ipairs(surface:GetChildren()) do
            local copy=child:Clone()
            if lightBackdrop and copy:IsA('TextLabel') and copy.Position.Y.Offset==15 then copy.TextColor3=Color3.fromRGB(35,44,49) end
            copy.Parent=canvas
        end
        if lightBackdrop then record.note..=' 使用浅色展示底，便于辨认原有深色文字；原控件颜色未变。' end
        record.renderMode='Studio ScreenGui'
        record.note..=' 展示面控件通过临时 ScreenGui 直接排版截图。'
    else
        local frame=Instance.new('ViewportFrame')
        frame.Name='AssetViewport' frame.Size=UDim2.fromScale(1,1) frame.BorderSizePixel=0
        frame.BackgroundColor3=Color3.fromRGB(65,72,78)
        frame.Ambient=Color3.fromRGB(130,130,130)
        frame.LightColor=Color3.fromRGB(180,180,180)
        frame.LightDirection=Vector3.new(-1,-.8,-1)
        frame.Parent=gui
        local camera=Instance.new('Camera')
        camera.FieldOfView=S.camera.FieldOfView camera.CFrame=S.camera.CFrame camera.Focus=S.camera.Focus
        camera.Parent=frame frame.CurrentCamera=camera
        local world=Instance.new('WorldModel') world.Parent=frame
        local effects=0
        for _,obj in ipairs(S.stage:GetDescendants()) do
            if obj:IsA('ParticleEmitter') or obj:IsA('Beam') or obj:IsA('Trail') then effects+=1 end
        end
        local target=world
        local shrink=math.max(record.size[1],record.size[2],record.size[3])>500
        local display=nil
        if shrink then
            display=Instance.new('Model') display.Name='ScaledDisplay' display.Parent=world
            local pivot=Instance.new('Part') pivot.Name='TemporaryScalePivot' pivot.Size=Vector3.one
            pivot.Transparency=1 pivot.Anchored=true pivot.CanCollide=false pivot.CFrame=CFrame.new(S.origin)
            pivot.Parent=display display.PrimaryPart=pivot target=display
        end
        for _,child in ipairs(S.stage:GetChildren()) do S.mount(child,target) end
        if shrink then
            local factor=100/math.max(record.size[1],record.size[2],record.size[3])
            local relative=camera.CFrame-S.origin
            display:ScaleTo(factor) display:PivotTo(CFrame.identity)
            camera.CFrame=CFrame.new(relative.Position*factor)*relative.Rotation
            camera.Focus=CFrame.identity
            record.displayScale=factor
            record.note..=' 大型场景展示副本等比缩小，以适应静态视窗范围；源对象尺寸未变。'
        end
        record.renderMode='Studio ViewportFrame'
        record.nativeMethod=record.method
        if record.method=='原貌截图' then record.method='静态视窗' end
        record.note='Studio ViewportFrame 渲染原对象副本，保留几何、颜色与贴图；无实时阴影，Neon/Glass及反射显示有差异，界面和动态特效未完整呈现。 '..record.note
        record.effectsNotRendered=effects
        local badge=Instance.new('TextLabel')
        badge.BackgroundTransparency=1 badge.Size=UDim2.new(1,-24,0,22)
        badge.Position=UDim2.new(0,12,1,-26) badge.TextXAlignment=Enum.TextXAlignment.Right
        badge.Font=Enum.Font.SourceSans badge.TextSize=14 badge.TextColor3=Color3.fromRGB(205,212,215)
        badge.Text='静态视窗 · 无实时阴影及动态特效' badge.Parent=gui
    end
    gui.Parent=game:GetService('StarterGui')
    local failed={}
    local ok,err=pcall(function()
        game:GetService('ContentProvider'):PreloadAsync({gui},function(asset,status)
            if status~=Enum.AssetFetchStatus.Success then table.insert(failed,{asset=asset,status=status.Name}) end
        end)
    end)
    record.assetFetchFailures=failed
    if not ok then record.preloadError=tostring(err) end
    if #failed>0 then record.note..=' 预加载失败资源 '..#failed..' 项，部分外观可能缺失。' end
    task.wait(1.5)
    return H:JSONEncode(record)
end
return 'ViewportFrame fallback ready'
