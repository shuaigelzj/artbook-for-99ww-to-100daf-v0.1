local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local CommonFunc = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("framework"):WaitForChild("CommonFunc"))
local GameEnum = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("GameEnum"))
local GameType = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("GameType"))
local MapHelper = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("Helpers"):WaitForChild("MapHelper"))
local ValueHelper = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("Helpers"):WaitForChild("ValueHelper"))
local GameHelper = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("Helpers"):WaitForChild("GameHelper"))
local ResourcesItemHelper = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("Helpers"):WaitForChild("ResourcesItemHelper"))
local EnemyHelper = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("Helpers"):WaitForChild("EnemyHelper"))
local CampfireSetting = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("ExcelConfig"):WaitForChild("CampfireSetting"))
local WantedSetting = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("ExcelConfig"):WaitForChild("WantedSetting"))

local GroundValue = ValueHelper.ValueModel.GroundValue
local BuildingValue = ValueHelper.ValueModel.BuildingValue
local StrongholdValue = ValueHelper.ValueModel.StrongholdValue

local GridType = MapHelper.GridType

local _mapParent = MapHelper:GetMapParent()

local _animalParent = Instance.new("Folder")
_animalParent.Name = "Animals"
_animalParent.Parent = workspace

local _specialHouse:Folder = workspace:FindFirstChild("Prefabs"):FindFirstChild("Map"):FindFirstChild("特殊房子")

local _resPointSizeMap:{Vector2} = {}

math.randomseed(tick())
function initAreaSide()
    local parent = Instance.new("Model")
    parent.Name = "边界"
    parent.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
    parent:PivotTo(CFrame.new(Vector3.zero))
    parent.Parent = workspace

    local prefab:Part = workspace.Prefabs.Map:FindFirstChild("区域格挡空气墙")
    local wallCount = math.ceil(MapHelper.mapSize_1 * MapHelper.gridSize_1 / prefab.Size.X)
    local wallStartPos = Vector3.new(-(prefab.Size.X * wallCount / 2) + prefab.Size.X / 2,0,0)
            -- print(wallCount)
    local _walls = {}
    for i=1,4 do
        local rootPart:Part = Instance.new("Part")
        rootPart.Name = string.format("空气墙%d", i)
        rootPart.Size = Vector3.one
        rootPart.Transparency = 1
        rootPart.CastShadow = false
        rootPart.Anchored = true
        rootPart.CanCollide = false
        rootPart.CanTouch = false
        rootPart.CanQuery = false
        rootPart:PivotTo(CFrame.new())
        rootPart.Parent = parent
        table.insert(_walls, rootPart)

        for j = 1,wallCount do
            local wall = prefab:Clone()
            wall.Anchored = false
            wall.Transparency = 1
            wall:PivotTo(CFrame.new(wallStartPos + Vector3.new((j-1) * prefab.Size.X,0,0)))
            CommonFunc:WeldConstraint(rootPart,wall)
            wall.Parent = rootPart
        end
    end

    local wallT = _walls[1]
    local wallB = _walls[2]
    local wallL = _walls[3]
    local wallR = _walls[4]

    local maxLv = #CampfireSetting.data
    local gridSize = MapHelper.gridSize_1 * MapHelper.gridSize_2
    local distance = gridSize / 2 + (maxLv-1) * gridSize
    local originPosition = Vector3.zero
    -- 上
    wallT:PivotTo(CFrame.new(Vector3.new(0,0,-distance) + originPosition,originPosition))
    -- 下
    wallB:PivotTo(CFrame.new(Vector3.new(0,0,distance) + originPosition,originPosition))
    -- 左
    wallL:PivotTo(CFrame.new(Vector3.new(-distance,0,0) + originPosition,originPosition))
    -- 右
    wallR:PivotTo(CFrame.new(Vector3.new(distance,0,0) + originPosition,originPosition))
end

function createNormalLand(grid1X:number,grid1Z:number,posY:number,prefabName:string?)
    if not prefabName then
        -- prefabName = string.format("%d级地块",zoneLv)
        local zoneLv = MapHelper:GetZoneLevelByGrid1(grid1X,grid1Z)
        if zoneLv == 5 then
            prefabName = "5级地块"
        elseif zoneLv == 6 then
            prefabName = "6级地块"
        else
            prefabName = "Grassland"
        end
    end
    local groundFolder = workspace:WaitForChild("Prefabs"):WaitForChild("Map"):WaitForChild("地块")
    local groundPrefab = groundFolder:FindFirstChild(prefabName)
    if not groundPrefab then
        groundPrefab = groundFolder:FindFirstChild("Grassland")
    end
    local ground:Part = groundPrefab:Clone()
    local posX,posZ = MapHelper:GetGridPos(grid1X,grid1Z)
    -- if MapHelper:FindGroundPart(grid1X,grid1Z) then
    --     error("重复创建了")
    -- end

    ValueHelper:InitByModel(ground,GroundValue)
    ValueHelper:SetValue(ground,GroundValue.grid,Vector3.new(grid1X,0,grid1Z))

    ground.Name = string.format("%d,%d",grid1X,grid1Z)
    -- ground.Size = Vector3.new(MapHelper.gridSize_1,ground.Size.Y,MapHelper.gridSize_1)
    ground:PivotTo(CFrame.Angles(0,math.rad(math.random(0,3) * 90),0) + Vector3.new(posX,posY or 0,posZ))
    ground.CollisionGroup = GameEnum.CollisionGroup.Ground
    ground:AddTag(GameEnum.Tag.Ground)
    
    ground.Parent = _mapParent

    local surface:SurfaceGui = ground:FindFirstChildWhichIsA("SurfaceGui",true)
    if surface then
        if RunService:IsStudio() and GameHelper.GridInfoEnable then
            surface.Enabled = true
            -- local grid2X = math.ceil(grid1X / MapHelper.gridSize_2)
            -- local grid2Z = math.ceil(grid1Z / MapHelper.gridSize_2)
            local grid2X,grid2Z = MapHelper:Grid1ToGrid2(grid1X,grid1Z)
            local c1 = grid2X / MapHelper.gridSize_2
            local c2 = grid2Z / MapHelper.gridSize_2
            -- ground.Color = Color3.new(c1,c2,(c1+c2)/(MapHelper.gridSize_2*2))

            local t_index:TextLabel = surface:FindFirstChildWhichIsA("TextLabel")
            if t_index then
                t_index.Text = string.format("%s\nlv:%d",ground.Name,MapHelper:GetZoneLevelByGrid2Pos(grid2X,grid2Z))
            end
        else
            surface.Enabled = false
        end
    end

    return ground
end

-- 初始化默认建筑
function initDefaultBuilding()
    local SpawnLocation:SpawnLocation = workspace:WaitForChild("SpawnLocation")
    local centerGrid = MapHelper.centerGrid1

    local groundY:number
    for offsetX =-2,2 do
        for offsetZ=-2, 2 do
            local grid1X = offsetX + centerGrid
            local grid1Z = offsetZ + centerGrid

            local ground = MapHelper:FindGroundPart(grid1X,grid1Z)
            -- 如果是树池，删掉重新创建
            if ground and MapHelper:GetMapGridType(grid1X,grid1Z) == GridType.pond then
                groundY = ground.Position.Y
                ground:Destroy()
                ground = nil
            end
            if not ground then
                ground = createNormalLand(grid1X,grid1Z,groundY)
            end
            if groundY then
                local pos = ground.Position
                ground:PivotTo(ground.CFrame.Rotation + Vector3.new(pos.X,groundY,pos.Z))
                -- ground.Position = Vector3.new(pos.X,groundY,pos.Z)
            else
                groundY = ground.Position.Y
            end
            ground:AddTag(GameEnum.Tag.ClearFog)
            MapHelper:SetMapGridType(grid1X,grid1Z,GridType.campfireLand)
        end
    end
    local centerGround:Part = MapHelper:FindGroundPart(centerGrid,centerGrid)
    local posY = centerGround.Position.Y + centerGround.Size.Y / 2
    -- ground.Size = Vector3.new(MapHelper.gridSize_1,ground.Size.Y,MapHelper.gridSize_1)

    local posX,posZ = MapHelper:GetGridPos(centerGrid,centerGrid)
    local campfireCFrame = CFrame.new(posX,posY,posZ)

    -- 创建营火
    local campfire:Model = MapHelper:CreateCampfire()
    campfire:PivotTo(campfireCFrame)
    SpawnLocation.CFrame = campfireCFrame

    -- 创建制作台
    local craftingBench:Model = MapHelper:CreateCraftingBench()
    local craftCFrame = craftingBench:GetPivot()
    craftingBench:PivotTo(craftCFrame.Rotation + Vector3.new(craftCFrame.Position.X,posY,craftCFrame.Position.Z))

    -- 悬赏公告板
    local wantedBoard:Model = MapHelper:CreatWantedBoard()
    local wantedCFrame = wantedBoard:GetPivot()
    wantedBoard:PivotTo(wantedCFrame.Rotation + Vector3.new(wantedCFrame.Position.X,posY,wantedCFrame.Position.Z))

    -- 随机一个水池
    local offsetX = math.random(0,2)
    local offsetZ = math.random(0,2)
    if offsetX ~= 2 and offsetZ ~= 2 then
        if math.random(1,2) == 1 then
            offsetX = 2
        else
            offsetZ = 2
        end
    end
    local grid1X = centerGrid + CommonFunc:RandomSign() * offsetX
    local grid1Z = centerGrid + CommonFunc:RandomSign() * offsetZ
    local pondPosY
    -- 生成池塘
    local ground = MapHelper:FindGroundPart(grid1X,grid1Z)
    if ground then
        pondPosY = ground.Position.Y
        ground:Destroy()
    else
        pondPosY = math.random() * math.random(-1,1)
    end
    local pondGround = createNormalLand(grid1X,grid1Z,pondPosY,"池塘")
    pondGround:AddTag(GameEnum.Tag.ClearFog)
    MapHelper:SetMapGridType(grid1X,grid1Z,GridType.pond)
    
    GameHelper:TryRemoveObstaclesAround(wantedBoard) -- 清理障碍
    GameHelper:TryRemoveObstaclesAround(craftingBench) -- 清理障碍
end

-- 初始化灯库
function initLightHouse()
    -- 灯库
    local prefab = _specialHouse:FindFirstChild("灯库")
    if not prefab then return end
    local lightHouse:Model = prefab:Clone()

    for i=1,20 do
        local grid2Vos = MapHelper.ZoneMap2[math.random(1,2)]
        local grid2Vo = grid2Vos[math.random(1,#grid2Vos)]
        if tryInitLandmark(grid2Vo.x,grid2Vo.z,1,1,MapHelper.GridType.LightHouse,lightHouse) then
            lightHouse.Parent = _mapParent
            break
        end
    end

    prefab:Destroy()
end

-- 创建神枪手据点
function initStronghole()
    local parent = Instance.new("Folder")
    parent.Name = "神枪手据点"
    parent.Parent = workspace
    local gridType = MapHelper.GridType.Stronghold
    for _,lo:WantedSetting.Type in ipairs(WantedSetting.data) do
        local gridVos = MapHelper.ZoneMap2[lo.zoneLv]
        if not gridVos then continue end

        local prefab = workspace:FindFirstChild("Prefabs"):FindFirstChild("Map"):FindFirstChild("神枪手据点"):FindFirstChild(tostring(lo.id))
        if not prefab then continue end

        local stronghold:Model
        local grid2Vo:GameType.GridVo
        while not stronghold do
            grid2Vo = gridVos[math.random(1,#gridVos)]
            stronghold = tryCreateLandmark(grid2Vo.x,grid2Vo.z,3,3,gridType,prefab,parent)
        end
        ValueHelper:InitByModel(stronghold,StrongholdValue)
        ValueHelper:SetValue(stronghold,StrongholdValue.id,lo.id)
        stronghold:AddTag(GameEnum.Tag.Stronghold)

        -- initBuilding(stronghold,grid2Vo.x,grid2Vo.z)
        prefab:Destroy()
    end
end

-- 创建医院
function initHospital()
    local parent = Instance.new("Folder")
    parent.Name = "医院"
    parent.Parent = workspace
    local gridType = MapHelper.GridType.Hospital
    local prefab = _specialHouse:FindFirstChild("医院")
    local zoneLvs = {2,3,4,5}
    local num = math.random(2,#zoneLvs)
    for i = 1,num do
        local zoneLv = table.remove(zoneLvs,math.random(1,#zoneLvs))
        local gridVos = MapHelper.ZoneMap2[zoneLv]
        local grid2Vo = gridVos[math.random(1,#gridVos)]
        local hospital = tryCreateLandmark(grid2Vo.x,grid2Vo.z,2,1,gridType,prefab,parent)
        if hospital then
            hospital.Name = "医院"
            initBuilding(hospital,grid2Vo.x,grid2Vo.z)
        end
    end
    prefab:Destroy()
end

-- 创建钻石塔
function initGemTower()
    local controller = MapHelper:CreateGemTowerController()
    if not controller then return end
    local suc = false
    while not suc do
        local gridType = MapHelper.GridType.GemTower
        local gridVos = MapHelper.ZoneMap2[math.random(3,4)]
        local gridVo = gridVos[math.random(1,#gridVos)]
        suc = tryInitLandmark(gridVo.x,gridVo.z,3,3,gridType,controller)
    end
end

-- 初始化武器库
function initGunHouse()
    -- 武器库
    local prefab = _specialHouse:FindFirstChild("武器库")
    if not prefab then return end
    local gridType = MapHelper.GridType.building
    for zoneLv=2,#CampfireSetting.data do
        local num = math.random(0,1)
        local gridVos = MapHelper.ZoneMap2[zoneLv]
        for i=1,num do
            local grid2Vo = gridVos[math.random(1,#gridVos)]
            local gunHouse = tryCreateLandmark(grid2Vo.x,grid2Vo.z,1,1,gridType,prefab,_mapParent)
            if gunHouse then
                gunHouse:SetAttribute("randomseed",math.random(1,9999))
            end
        end
    end
    prefab:Destroy()
end

-- 初始化武器工坊
function initWeaponWorkshop()
    if not GameHelper.Switch.WeaponWorkshop then return end

    local prefab = _specialHouse:FindFirstChild("2x2,武器工坊")
    if not prefab then
        warn("[MapService] Missing weapon workshop prefab")
        return
    end

    local zoneGridVos = MapHelper.ZoneMap2[4]
    if not zoneGridVos or #zoneGridVos == 0 then
        warn("[MapService] Missing zone 4 grid candidates for weapon workshop")
        return
    end

    local candidates = {}
    for _, gridVo in ipairs(zoneGridVos) do
        table.insert(candidates, gridVo)
    end

    while #candidates > 0 do
        local candidate = table.remove(candidates, math.random(1, #candidates))
        local workshop = tryCreateLandmark(
            candidate.x,
            candidate.z,
            2,
            2,
            GridType.building,
            prefab,
            _mapParent
        )
        if workshop then
            workshop.Name = "2x2,武器工坊"
            initBuilding(workshop, candidate.x, candidate.z)

            local structure = workshop:FindFirstChild("Model")
            local door = structure and structure:FindFirstChild("门")
            if door then
                door:SetAttribute("GearMechanismId", 1)
                door:RemoveTag(GameEnum.Tag.GearMechanismDoor)
                door:AddTag(GameEnum.Tag.GearMechanismDoor)
            end

            print("[MapService] Weapon workshop created in zone 4:", candidate.x, candidate.z)
            return workshop
        end
    end

    warn("[MapService] Could not place weapon workshop in zone 4")
end

-- 创建专属齿轮资源点
function initGearSourcePoints()
    if not GameHelper.Switch.WeaponWorkshop then return end

    local gearSourceFolder = workspace:FindFirstChild("Prefabs")
        and workspace.Prefabs:FindFirstChild("Map")
        and workspace.Prefabs.Map:FindFirstChild("齿轮资源点")
    if not gearSourceFolder then
        warn("[MapService] Missing gear source prefab folder")
        return
    end

    local runtimeFolder = workspace:FindFirstChild("齿轮资源点")
    if not runtimeFolder then
        runtimeFolder = Instance.new("Folder")
        runtimeFolder.Name = "齿轮资源点"
        runtimeFolder.Parent = workspace
    end

    local setting = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("ExcelConfig"):WaitForChild("GearSourceSetting"))
    for _, config in ipairs(setting.data) do
        local prefab = gearSourceFolder:FindFirstChild(config.prefabName)
        if not prefab then
            warn("[MapService] Missing gear source prefab:", config.prefabName)
            continue
        end

        local zoneGridVos = MapHelper.ZoneMap2[config.zoneLevel]
        local candidates = {}
        if zoneGridVos then
            for _, gridVo in ipairs(zoneGridVos) do
                table.insert(candidates, gridVo)
            end
        end

        local created
        while #candidates > 0 do
            local candidate = table.remove(candidates, math.random(1, #candidates))
            local source = prefab:Clone()
            if tryInitLandmark(
                candidate.x,
                candidate.z,
                1,
                1,
                GridType.building,
                source
            ) then
                local embeddedGear = source:FindFirstChild(tostring(config.gearItemId), true)
                if not embeddedGear or not embeddedGear:IsA("Model") then
                    warn("[MapService] Missing embedded gear in prefab:", config.prefabName)
                    source:Destroy()
                    source = nil
                else
                    local gearSpawnCFrame = embeddedGear:GetPivot()
                    embeddedGear:SetAttribute("GearSourceId", config.id)
                    embeddedGear:SetAttribute("GearSourceZone", config.zoneLevel)
                    embeddedGear:SetAttribute("GearSourceState", "Guarded")
                    embeddedGear:SetAttribute("GearSourceConsumed", false)
                    source:SetAttribute("GearSpawnCFrame", gearSpawnCFrame)
                    source.Parent = runtimeFolder
                end
            else
                source:Destroy()
                source = nil
            end
            if source then
                source.Name = string.format("齿轮资源点_%d", config.id)
                source.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
                source:SetAttribute("GearSourceId", config.id)
                source:SetAttribute("GearSourceZone", config.zoneLevel)
                source:SetAttribute("GearSourceState", "Guarded")
                source:SetAttribute("GearSourceActivated", false)
                source:SetAttribute("AliveGuards", 0)
                source:SetAttribute("Grid2X", candidate.x)
                source:SetAttribute("Grid2Z", candidate.z)
                created = source
                print("[MapService] Gear source created:", config.id, "zone", config.zoneLevel, candidate.x, candidate.z)
                break
            end
        end

        if not created then
            warn("[MapService] Could not place gear source in zone", config.zoneLevel)
        end
    end
end

-- 随机淘金屋
function initGoldPan()
    -- if not RunService:IsStudio() then return end
    local prefab = _specialHouse:FindFirstChild("淘金屋")
    if not prefab then return end
    local gridVos = MapHelper.ZoneMap2[2]
    local grid2Vo = gridVos[math.random(1,#gridVos)]
    local goldPan = tryCreateLandmark(grid2Vo.x,grid2Vo.z,2,1,GridType.building,prefab,nil,"空地块")
    if not goldPan then return end
    goldPan:AddTag(GameEnum.Tag.GoldPan)
    prefab:Destroy()
end

function tryCreateMiniEvent(prefab:Model,zoneLv:number,gridType:number,parent:Instance)
    if not gridType then gridType = GridType.building end
    if not parent then parent = workspace:FindFirstChild("随机事件") end
    local gridVos = MapHelper.ZoneMap2[zoneLv]
    local grid2Vo = gridVos[math.random(1,#gridVos)]
    local size = getResPointSize(prefab)
    for i = 1,10 do
        local miniStronghold = tryCreateLandmark(grid2Vo.x,grid2Vo.z,size.X,size.Y,gridType,prefab,parent)
        if miniStronghold then
            print("区域等级"..tostring(zoneLv),"创建额外随机小事件",prefab.Name)
            initBuilding(miniStronghold,grid2Vo.x,grid2Vo.z)
            break
        end
    end
end

-- 小随机事件
function initMiniEvents()
    local parent = Instance.new("Folder")
    parent.Name = "随机事件"
    parent.Parent = workspace

    local folder = workspace:FindFirstChild("Prefabs"):FindFirstChild("Map"):FindFirstChild("随机事件")
    local prefabs = folder:GetChildren()
    local gridType = GridType.building
    for zoneLv = 2,#CampfireSetting.data do
        local prefab = table.remove(prefabs,math.random(1,#prefabs))
        tryCreateMiniEvent(prefab,zoneLv,gridType,parent)
    end
    folder:Destroy()

    -- 特殊随机事件
    tryCreateMiniEvent(_specialHouse:FindFirstChild("1x1,化石"),math.random(4,6),gridType,parent)
    -- tryCreateMiniEvent(_specialHouse:FindFirstChild("1x1,传送马车"),6,gridType,parent)
end

function tryInitLandmark(grid2X:number,grid2Z:number,sizeX:number,sizeZ:number,gridType:number,landmark:Model,groundName:string?)
    -- local gird1XMax
    local gird1XMax = grid2X * MapHelper.gridSize_2 - sizeX + 1
    local gird1XMin = (grid2X - 1) * MapHelper.gridSize_2 + 1
    local gird1ZMax = grid2Z * MapHelper.gridSize_2 - sizeZ + 1
    local gird1ZMin = (grid2Z - 1) * MapHelper.gridSize_2 + 1

    if sizeX ~= sizeZ and math.random(1,2) == 1 then
        local oldZ = sizeZ
        sizeZ = sizeX
        sizeX = oldZ
    end
    -- print("grid2",grid2X, grid2Z)
    -- print("size2",sizeX, sizeZ)
    
    for i=1,10 do
        local match = true
        -- 随机10次，如果找不到就不创建了
        local spawnGrid1X = math.random(gird1XMin,gird1XMax)
        local spawnGrid1Z = math.random(gird1ZMin,gird1ZMax)

        -- print("start",grid1XStart, grid1ZStart)
        for offsetX = 1, sizeX do
            for offsetZ = 1, sizeZ do
                local grid1X = spawnGrid1X + offsetX - 1
                local grid1Z = spawnGrid1Z + offsetZ - 1
                local tempGridType = MapHelper:GetMapGridType(grid1X,grid1Z)
                if tempGridType and tempGridType ~= GridType.land then
                    match = false
                    break
                end
                -- print(grid1X, grid1Z)
            end
            if not match then break end
        end

        if not match then continue end

        local groundPosY = nil
        for offsetX = 1, sizeX do
            for offsetZ = 1, sizeZ do
                local grid1X = spawnGrid1X + offsetX - 1
                local grid1Z = spawnGrid1Z + offsetZ - 1
                -- print(grid1X, grid1Z)
                local ground = MapHelper:FindGroundPart(grid1X,grid1Z)
                if groundName and ground then
                    if not groundPosY then
                        groundPosY = ground.Position.Y
                    end
                    ground:Destroy()
                    ground = nil
                end
                if not ground then
                    ground = createNormalLand(grid1X,grid1Z,groundPosY,groundName)
                end
                if groundPosY then
                    local cframe = ground:GetPivot()
                    ground:PivotTo(cframe.Rotation + Vector3.new(cframe.Position.X,groundPosY,cframe.Position.Z))
                else
                    groundPosY = ground.Position.Y
                end
                
                MapHelper:SetMapGridType(grid1X,grid1Z,gridType or GridType.building)
            end
        end

        local posX,posZ = MapHelper:GetGridPos(spawnGrid1X,spawnGrid1Z)
        posX += sizeX / 2 * MapHelper.gridSize_1 - MapHelper.halfGridSize_1
        posZ += sizeZ / 2 * MapHelper.gridSize_1 - MapHelper.halfGridSize_1
        local ground:Part = MapHelper:FindGroundPart(spawnGrid1X,spawnGrid1Z)
        local posY = ground.Position.Y + ground.Size.Y / 2
        local position = Vector3.new(posX,posY,posZ)
        local rotationY:number
        if sizeX == sizeZ then
            -- 360度随机旋转
            -- building:PivotTo(CFrame.new(position,position + Vector3.new(math.random(-1,1),0,math.random(-1,1))))
            -- rotationY = math.random() * 360
            -- 90度随机旋转
            rotationY = math.random(0,3) * 90
        else
            -- 只接受180度旋转
            rotationY = math.random(1,2) == 1 and 0 or 180
            if sizeZ > sizeX then
                rotationY += 90
            end
        end
        landmark:PivotTo(CFrame.new(position) * CFrame.Angles(0,math.rad(rotationY),0))

        return true
    end
end

-- 创建地标
function tryCreateLandmark(grid2X:number,grid2Z:number,sizeX:number,sizeZ:number,gridType:number,prefab:Model,parent:Instance?,groundName:string?)
    if not prefab then return end

    local landmark:Model = prefab:Clone()
    if tryInitLandmark(grid2X,grid2Z,sizeX,sizeZ,gridType,landmark,groundName) then
        landmark.Parent = parent or _mapParent
    else
        landmark:Destroy()
        landmark = nil
    end

    return landmark
end

function initBuilding(building:BasePart,grid2X:number,grid2Z:number)
    if not building then return end
    ValueHelper:InitByModel(building,BuildingValue)
    ValueHelper:SetValue(building,BuildingValue.grid2,Vector3.new(grid2X,0,grid2Z))
    ValueHelper:SetValue(building,BuildingValue.level,MapHelper:GetZoneLevelByGrid2Pos(grid2X,grid2Z))
    building:AddTag(GameEnum.Tag.Building)
end

function tryCreateMountain(centerGrid1X:number,centerGrid1Z:number,r:number,groundPrefabName:string,gridType:number?)
    -- local centerGridType = MapHelper:GetMapGridType(centerGrid1X,centerGrid1Z)
    -- if centerGridType then return end

    if not MapHelper:GetIsSafetyRange(centerGrid1X,centerGrid1Z,r) then return end
    local sign = 1

    for offsetX =-r,r do
        for offsetZ=-r, r do
            local grid1X = offsetX + centerGrid1X
            local grid1Z = offsetZ + centerGrid1Z

            if not MapHelper:IsInMapGrid1(grid1X,grid1Z) then continue end
            -- if MapHelper:GetMapGridType(grid1X,grid1Z) then continue end

            local height = (r - math.max(math.abs(offsetX),math.abs(offsetZ))) * 5 * sign
            local offset = sign * math.random() * 2
            local posY = height + offset

            createNormalLand(grid1X,grid1Z,posY,groundPrefabName)
            MapHelper:SetMapGridType(grid1X,grid1Z,gridType)
        end
    end
    return true
end

function tryCreateTerrain(centerGrid1X:number,centerGrid1Z:number,r:number,sign:number,specialGridType:number?)
    -- local centerGridType = MapHelper:GetMapGridType(centerGrid1X,centerGrid1Z)
    -- if centerGridType then return end

    if not MapHelper:GetIsSafetyRange(centerGrid1X,centerGrid1Z,r) then return end
    if not sign then sign = 1 end

    for offsetX =-r,r do
        for offsetZ=-r, r do
            local grid1X = offsetX + centerGrid1X
            local grid1Z = offsetZ + centerGrid1Z

            if not MapHelper:IsInMapGrid1(grid1X,grid1Z) then continue end

            local gridType = MapHelper:GetMapGridType(grid1X,grid1Z)
            if gridType then continue end

            -- print(grid1X,grid1Z)
            local height = (r - math.max(math.abs(offsetX),math.abs(offsetZ))) * 5 * sign
            local offset = sign * math.random() * 2
            local posY = height + offset
            local prefabName:string
            local absOffsetX = math.abs(offsetX)
            local absOffsetZ = math.abs(offsetZ)
            if sign > 0 then
                local max = 2
                if absOffsetX <= max and absOffsetZ <= max then
                    if absOffsetX < max and absOffsetZ < max then
                        prefabName = "高原地区地块"
                    elseif absOffsetX == max or absOffsetZ == max then
                        if math.random(1,2) == 1 then
                            prefabName = "高原地区地块"
                        end
                    end
                end
            else
                local max = 2
                if absOffsetX <= max and absOffsetZ <= max then
                    if absOffsetX < max and absOffsetZ < max then
                        prefabName = "低位地区地块"
                    elseif absOffsetX == max or absOffsetZ == max then
                        if math.random(1,2) == 1 then
                            prefabName = "低位地区地块"
                        end
                    end
                end
            end
            -- if absOffsetX < 2 and absOffsetZ < 2 then
            --     prefabName = "高原地区地块"
            -- elseif posY <= -35 then
            --     prefabName = "低位地区地块"
            -- end

            createNormalLand(grid1X,grid1Z,posY,prefabName)
            MapHelper:SetMapGridType(grid1X,grid1Z,specialGridType or GridType.land)
        end
    end
    return true
end

-- 初始化铃铛洞穴
function initBellCave()
    if not GameHelper.Switch.BellCave then return end

    local folder:Folder = workspace.Prefabs.Map:FindFirstChild("铃铛洞穴")

    local grid1Vos4 = MapHelper.ZoneMap1[4]
    local grid1Vos5 = MapHelper.ZoneMap1[5]

    -- 在4级区域生成1级铃铛入口
    for i=1,100 do
        local grid1Vo = grid1Vos4[math.random(1,#grid1Vos4)]
        -- MapHelper:CreateBuilding
        local gridType = MapHelper:GetMapGridType(grid1Vo.x,grid1Vo.z)
        if gridType ~= GridType.land then continue end
        local prefab = folder:FindFirstChild("1x1,1级铃铛洞穴")
        local building = MapHelper:CreateBuilding(grid1Vo.x,grid1Vo.z,1,1,nil,prefab)
        MapHelper:initBuilding(building,MapHelper:Grid1ToGrid2(grid1Vo.x,grid1Vo.z))
        building:AddTag(GameEnum.Tag.BellCave)
        building:AddTag(GameEnum.Tag.BigWolfCave)
        print("创建1级别铃铛洞穴",grid1Vo.x,grid1Vo.z)

        -- 创建副本
        local pos = building:GetPivot().Position
        local battleGround:Model = folder:FindFirstChild("1级铃铛洞穴战场")
        local y = MapHelper.CaveY.BellCave1
        battleGround:PivotTo(CFrame.new(pos.X,y,pos.Z))
        battleGround:AddTag(GameEnum.Tag.BellCaveBattleGround)
        battleGround.Parent = building

        -- 赋值副本
        local v_battleGround:ObjectValue = building:FindFirstChild("铃铛洞穴"):FindFirstChild("战场")
        v_battleGround.Value = battleGround
        local v_enter:ObjectValue = battleGround:FindFirstChild("Values"):FindFirstChild("入口")
        v_enter.Value = building
        break
    end

    -- 在5级区域生成2级铃铛入口
    for i=1,100 do
        local grid1Vo = grid1Vos5[math.random(1,#grid1Vos4)]
        -- MapHelper:CreateBuilding
        local gridType = MapHelper:GetMapGridType(grid1Vo.x,grid1Vo.z)
        if gridType ~= GridType.land then continue end
        local prefab = folder:FindFirstChild("1x1,2级铃铛洞穴")
        local building = MapHelper:CreateBuilding(grid1Vo.x,grid1Vo.z,1,1,nil,prefab)
        MapHelper:initBuilding(building,MapHelper:Grid1ToGrid2(grid1Vo.x,grid1Vo.z))
        building:AddTag(GameEnum.Tag.BellCave)
        building:AddTag(GameEnum.Tag.BigAlligatorCave)
        print("创建2级别铃铛洞穴",grid1Vo.x,grid1Vo.z)

        -- 创建副本
        local pos = building:GetPivot().Position
        local battleGround:Model = folder:FindFirstChild("2级铃铛洞穴战场")
        local y = MapHelper.CaveY.BellCave2
        battleGround:PivotTo(CFrame.new(pos.X,y,pos.Z))
        battleGround:AddTag(GameEnum.Tag.BellCaveBattleGround)
        battleGround.Parent = building

        -- 赋值副本
        local v_battleGround:ObjectValue = building:FindFirstChild("铃铛洞穴"):FindFirstChild("战场")
        v_battleGround.Value = battleGround
        local v_enter:ObjectValue = battleGround:FindFirstChild("Values"):FindFirstChild("入口")
        v_enter.Value = building
        break
    end
end

function initSnowfield()
    if not GameHelper.Switch.Snowfield then return end

    local grid1Vos:{GameType.GridVo} = {
        {x=10,z=45},
        {x=45,z=10},
        {x=10,z=10},
        {x=45,z=45}
    }
    local r = GameHelper.SnowfieldRadius
    local centerGrid1X
    local centerGrid1Z

    for i=1,100 do
        local index = math.random(1,#grid1Vos)
        local grid1Vo = grid1Vos[index]
        local grid1X = grid1Vo.x
        local grid1Z = grid1Vo.z
        -- local grid1X = math.random(minGrid,maxGrid)
        -- local grid1Z = math.random(minGrid,maxGrid)

        -- local zoneLv = MapHelper:GetZoneLevelByGrid1(grid1X,grid1Z)
        -- if zoneLv <= 2 then continue end

        if not MapHelper:GetIsSafetyRange(grid1X,grid1Z,r) then continue end

        centerGrid1X = grid1X
        centerGrid1Z = grid1Z
        break
    end

    if not centerGrid1X or not centerGrid1Z then return end

    print("创建雪原区域，中心点",centerGrid1X,centerGrid1Z)

    local groundPrefabNames = {
        {item = "雪原地块",weight = 30},
        {item = "雪原地块2",weight = 3},
        {item = "雪原地块3",weight = 3},
        {item = "雪原池塘",weight = 1},
    }
    local sign = 1
    for offsetX =-r,r do
        for offsetZ=-r, r do
            local grid1X = offsetX + centerGrid1X
            local grid1Z = offsetZ + centerGrid1Z

            if not MapHelper:IsInMapGrid1(grid1X,grid1Z) then continue end
            if MapHelper:GetMapGridType(grid1X,grid1Z) then continue end

            local isEdgeGround = math.abs(offsetX) == r or math.abs(offsetZ) == r
            if isEdgeGround then
                if math.random(1,2) == 1 then continue end -- 在边缘时随机生成，造成不规则形状
            else
                local r2 = r-1
                isEdgeGround = math.abs(offsetX) >= r2 or math.abs(offsetZ) >= r2
            end

            local height = (r - math.max(math.abs(offsetX),math.abs(offsetZ))) * 5 * sign
            local offset = sign * math.random() * 2
            local posY = height + offset

            -- local groundPrefabName = groundPrefabNames[math.random(1,#groundPrefabNames)]
            local groundPrefabName = CommonFunc:WeightedRandom(groundPrefabNames)
            local ground = createNormalLand(grid1X,grid1Z,posY,groundPrefabName)
            ground:AddTag(GameEnum.Tag.SnowfieldGround)
            MapHelper:SetMapGridType(grid1X,grid1Z,GridType.Snowfield)

            if isEdgeGround then
                ground:AddTag(GameEnum.Tag.SnowfieldEdgeGround)
            end
        end
    end
    -- 生成山体
    -- for i = 1,100 do
    --     local suc = tryCreateMountain(centerGrid1X,centerGrid1Z,r,"雪原地块",GridType.Snowfield)
    --     if suc then break end
    -- end

    -- 生成地块
    -- for offsetX =-r,r do
    --     for offsetZ=-r, r do
    --         local grid1X = offsetX + centerGrid1X
    --         local grid1Z = offsetZ + centerGrid1Z
    --         if not MapHelper:IsInMapGrid1(grid1X,grid1Z) then continue end
    --         -- if grid1X < 1 or grid1X > MapHelper.mapSize_1 or grid1Z < 1 or grid1Z > MapHelper.mapSize_1 then
    --         --     continue
    --         -- end

    --         local isEdgeGround = math.abs(offsetX) == r or math.abs(offsetZ) == r
    --         if isEdgeGround then
    --             if math.random(1,2) == 1 then continue end -- 在边缘时随机生成，造成不规则形状
    --         end

    --         if MapHelper:GetMapGridType(grid1X,grid1Z) then continue end

    --         local posY = math.random() * math.random(-1,1)

    --         local zoneLv = MapHelper:GetZoneLevelByGrid1(grid1X,grid1Z)

    --         local ground:Part = createNormalLand(grid1X,grid1Z,posY,"雪原地块")
    --         -- 沼泽普通地块
    --         MapHelper:SetMapGridType(grid1X,grid1Z,GridType.Snowfield)
    --         -- ground:AddTag(GameEnum.Tag.MarshGround)
    --         -- if isEdgeGround then
    --         --     ground:AddTag(GameEnum.Tag.MarshEdgeGround)
    --         -- end
    --         -- table.insert(marshGrid1Vos,{x=grid1X,z=grid1Z})
    --     end
    -- end

    -- 在中心点创建雪山控制器
    local scPrefab = workspace:FindFirstChild("Prefabs"):FindFirstChild("雪原Map"):FindFirstChild("雪山"):FindFirstChild("雪山控制器")
    local sc = MapHelper:CreateBuildingOnCenter(centerGrid1X,centerGrid1Z,5,5,GridType.Special,scPrefab,"雪原地块")
    sc.Parent = workspace:FindFirstChild("雪原")
    MapHelper:initBuilding(sc,MapHelper:Grid1ToGrid2(centerGrid1X,centerGrid1Z))
end

-- 初始化沼泽地
function initMarsh()
    if not GameHelper.Switch.Marsh then return end
    -- local minGrid = 10
    -- local maxGrid = MapHelper.mapSize_1 - minGrid
    local r = GameHelper.MarshWidth

    local centerGrid1X
    local centerGrid1Z

    -- local grid1Vos = MapHelper.ZoneMap1[4]

    local grid1Vos:{GameType.GridVo} = {
        -- {x=10,z=10},
        -- {x=30,z=10},
        -- {x=10,z=30},
        -- {x=45,z=30},
        -- {x=10,z=45},
        -- {x=30,z=45},
        -- {x=45,z=45},
        {x=10,z=45},
        {x=45,z=10},
        {x=10,z=10},
        {x=45,z=45}
    }
    for i=1,100 do
        local index = math.random(1,#grid1Vos)
        local grid1Vo = grid1Vos[index]
        local grid1X = grid1Vo.x
        local grid1Z = grid1Vo.z
        -- local grid1X = math.random(minGrid,maxGrid)
        -- local grid1Z = math.random(minGrid,maxGrid)

        -- local zoneLv = MapHelper:GetZoneLevelByGrid1(grid1X,grid1Z)
        -- if zoneLv <= 2 then continue end

        if not MapHelper:GetIsSafetyRange(grid1X,grid1Z,r) then continue end

        centerGrid1X = grid1X
        centerGrid1Z = grid1Z
        break
    end

    if not centerGrid1X or not centerGrid1Z then return end
    -- centerGrid1X = 10
    -- centerGrid1Z = 10
    print("初始化沼泽，沼泽中心点",centerGrid1X,centerGrid1Z)
    -- 生成水池
    local maxPondNum = math.random(10,20)
    local curPondNum = 0
    for i=1,5 do
        if curPondNum >= maxPondNum then break end

        local offsetX = math.random(-r,r)
        local offsetZ = math.random(-r,r)
        local grid1X = centerGrid1X + offsetX
        local grid1Z = centerGrid1Z + offsetZ
        if not MapHelper:IsInMapGrid1(grid1X,grid1Z) then continue end

        local gridType = MapHelper:GetMapGridType(grid1X,grid1Z)
        if gridType then continue end
        local isEdgeGround = math.abs(offsetX) == r or math.abs(offsetZ) == r
        local posY = math.random() * math.random(-1,1)

        local ground = createNormalLand(grid1X,grid1Z,posY,"沼泽池塘")
        MapHelper:SetMapGridType(grid1X,grid1Z,GridType.MarshPond)
        ground:AddTag(GameEnum.Tag.MarshPond)

        curPondNum += 1
        if isEdgeGround then
            ground:AddTag(GameEnum.Tag.MarshEdgeGround)
        end
    end

    local specialGroundPercents = {}
    specialGroundPercents[1] = 0
    specialGroundPercents[2] = 0
    specialGroundPercents[3] = 0
    specialGroundPercents[4] = 10
    specialGroundPercents[5] = 15
    specialGroundPercents[6] = 20

    local marshGrid1Vos:{GameType.GridVo} = {}
    -- 生成地块
    for offsetX =-r,r do
        for offsetZ=-r, r do
            local grid1X = offsetX + centerGrid1X
            local grid1Z = offsetZ + centerGrid1Z
            if not MapHelper:IsInMapGrid1(grid1X,grid1Z) then continue end
            -- if grid1X < 1 or grid1X > MapHelper.mapSize_1 or grid1Z < 1 or grid1Z > MapHelper.mapSize_1 then
            --     continue
            -- end

            local isEdgeGround = math.abs(offsetX) == r or math.abs(offsetZ) == r
            if isEdgeGround then
                if math.random(1,2) == 1 then continue end -- 在边缘时随机生成，造成不规则形状
            end

            local gridType = MapHelper:GetMapGridType(grid1X,grid1Z)
            if gridType then continue end

            local posY = math.random() * math.random(-1,1)

            local zoneLv = MapHelper:GetZoneLevelByGrid1(grid1X,grid1Z)

            local ground:Part
            if math.random(1,100) <= specialGroundPercents[zoneLv] then
                -- 等级越高的区域，越容易生成特殊沼泽地块
                -- ground = createNormalLand(grid1X,grid1Z,posY,"沼泽地块-泥沼")
                if math.random(1,2) == 1 then
                    ground = createNormalLand(grid1X,grid1Z,posY,"沼泽地块-泥沼泽")
                    MapHelper:SetMapGridType(grid1X,grid1Z,GridType.Marsh)
                else
                    ground = createNormalLand(grid1X,grid1Z,posY,"沼泽地块-毒沼泽")
                    MapHelper:SetMapGridType(grid1X,grid1Z,GridType.ToxicSwamp)
                end
            else
                -- 沼泽普通地块
                ground = createNormalLand(grid1X,grid1Z,posY,math.random(1,2) == 1 and "沼泽地块" or "沼泽水地块")
                MapHelper:SetMapGridType(grid1X,grid1Z,GridType.Marsh)
            end
            ground:AddTag(GameEnum.Tag.MarshGround)
            if isEdgeGround then
                ground:AddTag(GameEnum.Tag.MarshEdgeGround)
            end
            table.insert(marshGrid1Vos,{x=grid1X,z=grid1Z})
        end
    end
end

-- 火车大劫案
function initTrain()
    if not GameHelper.Switch.Train then return end

    -- print("初始化火车大劫案，沼泽中心点",centerGrid1X,centerGrid1Z)
    local offset = MapHelper.gridSize_2 * 2 + math.floor(MapHelper.gridSize_2 / 2) -- 应该是10
    local pointConfigs = {
        {
            x = MapHelper.centerGrid1 - offset,
        },
        {
            x = MapHelper.centerGrid1 + offset,
        },
        {
            z = MapHelper.centerGrid1 - offset,
        },
        {
            z = MapHelper.centerGrid1 + offset,
        },
    }

    local suc = false
    while #pointConfigs > 0 do
        local pointConfig = table.remove(pointConfigs,math.random(1,#pointConfigs))
        local startGrid1X = pointConfig.x or 1
        local startGrid1Z = pointConfig.z or 1
        local endGrid1X = pointConfig.x or MapHelper.mapSize_1
        local endGrid1Z = pointConfig.z or MapHelper.mapSize_1

        -- 寻找一条合法的路
        local isMatch = true
        for grid1X = startGrid1X, endGrid1X do
            for grid1Z = startGrid1Z, endGrid1Z do
                local gridType = MapHelper:GetMapGridType(grid1X,grid1Z)
                if gridType then
                    isMatch = false
                    break
                end
            end
            if not isMatch then
                break
            end
        end
        if not isMatch then continue end

        local rotationOffset = 0
        if startGrid1X ~= endGrid1X then
            rotationOffset = 90
        end

        local startGround:Part = nil
        local endGround:Part = nil
        for grid1X = startGrid1X, endGrid1X do
            for grid1Z = startGrid1Z, endGrid1Z do
                local groundPrefabName = "铁轨路"
                if grid1X  == startGrid1X and grid1Z == startGrid1Z then
                    groundPrefabName = "铁轨出入口"
                elseif grid1X == endGrid1X and grid1Z == endGrid1Z then
                    groundPrefabName = "铁轨出入口"
                end

                local ground = createNormalLand(grid1X,grid1Z,0,groundPrefabName)
                local cframe = ground:GetPivot()
                ground:PivotTo(CFrame.Angles(0,math.rad(rotationOffset),0) + cframe.Position)
                ground:AddTag(GameEnum.Tag.RailwayGround)
                MapHelper:SetMapGridType(grid1X,grid1Z,GridType.Railway)

                if grid1X  == startGrid1X and grid1Z == startGrid1Z then
                    startGround = ground
                elseif grid1X == endGrid1X and grid1Z == endGrid1Z then
                    endGround = ground
                end
            end
        end

        if math.random(1,2) == 1 then
            -- 换方向
            local markStartGround = startGround
            startGround = endGround
            endGround = markStartGround
        end

        startGround:PivotTo(CFrame.new(startGround:GetPivot().Position,endGround:GetPivot().Position))
        endGround:PivotTo(CFrame.new(endGround:GetPivot().Position,startGround:GetPivot().Position))

        startGround:AddTag(GameEnum.Tag.RailwayGroundStart)
        endGround:AddTag(GameEnum.Tag.RailwayGroundEnd)
        suc = true
        break
    end

    if not suc then
        local folder = workspace:FindFirstChild("火车大劫案")
        if folder then
            folder:Destroy()
        end
    end
end

function initKingMooseNest()
    if not GameHelper.Switch.KingMoose then return end

    local prefab = _specialHouse and _specialHouse:FindFirstChild("1x1,驼鹿巢穴")
    if not prefab then
        warn("[MapService] King Moose nest prefab is missing")
        return
    end

    local candidates = {}
    for zoneLv = 3,6 do
        local zoneGridPoints = MapHelper.ZoneMap1[zoneLv] or {}
        for _,gridPoint in ipairs(zoneGridPoints) do
            local grid1X = gridPoint.x
            local grid1Z = gridPoint.z
            if MapHelper:GetMapGridType(grid1X,grid1Z) ~= GridType.land then continue end
            if not MapHelper:FindGroundPart(grid1X,grid1Z) then continue end
            if not MapHelper:GetIsSafetyBuildingPoint(grid1X,grid1Z,1,1,GridType.land) then continue end
            table.insert(candidates,{
                x = grid1X,
                z = grid1Z,
                zoneLv = zoneLv,
            })
        end
    end

    for i = #candidates,2,-1 do
        local swapIndex = math.random(1,i)
        candidates[i],candidates[swapIndex] = candidates[swapIndex],candidates[i]
    end

    for _,candidate in ipairs(candidates) do
        if MapHelper:GetMapGridType(candidate.x,candidate.z) ~= GridType.land then continue end
        if not MapHelper:FindGroundPart(candidate.x,candidate.z) then continue end
        if not MapHelper:GetIsSafetyBuildingPoint(candidate.x,candidate.z,1,1,GridType.land) then continue end

        local grid2X,grid2Z = MapHelper:Grid1ToGrid2(candidate.x,candidate.z)
        local nest = MapHelper:CreateBuilding(
            candidate.x,
            candidate.z,
            1,
            1,
            GridType.building,
            prefab
        )
        if not nest then continue end

        initBuilding(nest,grid2X,grid2Z)
        nest:AddTag(GameEnum.Tag.KingMooseNest)
        nest:SetAttribute("KingMooseNestZone",candidate.zoneLv)
        print("生成驼鹿巢穴",candidate.zoneLv,candidate.x,candidate.z)
        return
    end

    warn("[MapService] Could not place King Moose nest in zones 3-6")
end

function initNormalLand()
    -- 山丘
    -- local massifNumMax = math.random(1,2)
    local massifNum = 0
    local minGrid = 10
    local maxGrid = MapHelper.mapSize_1 - minGrid


    local massifNumMax = 1
    for i = 1,100 do
        if massifNum >= massifNumMax then break end
        local centerGrid1X = math.random(minGrid,maxGrid)
        local centerGrid1Z = math.random(minGrid,maxGrid)
        local zoneLv = MapHelper:GetZoneLevelByGrid1(centerGrid1X,centerGrid1Z)
        if zoneLv <= 2 then continue end

        local r = 8
        if GameHelper.Switch.Snowfield then
            -- 有雪地的情况下，缩小山体的大小，提升生成的成功率
            r = 3
        end
        local suc = tryCreateTerrain(centerGrid1X,centerGrid1Z,r,1)
        if not suc then continue end
        massifNum += 1

        -- 把山顶设置成特殊地块
        MapHelper:SetMapGridType(centerGrid1X,centerGrid1Z,GridType.Special)

        -- 刷马地块
        local ground = MapHelper:FindGroundPart(centerGrid1X,centerGrid1Z)
        ground:AddTag(GameEnum.Tag.HorseGround)
    end
    print("随机山数量：",massifNum)

    -- 坑副本
    local holdEvents = {}
    -- table.insert(holdEvents,"无")
    if GameHelper.Switch.Quake then
        table.insert(holdEvents,"无")
        table.insert(holdEvents,"雷神锤")
    end
    if GameHelper.Switch.OldMineTown then
        table.insert(holdEvents,"老矿镇")
    end

    -- 下沉
    -- local sinkNumMax = math.random(1,2)
    local sinkNumMax = 1
    local sinkNum = 0
    for i = 1,100 do
        if sinkNum >= sinkNumMax then break end
        local centerGrid1X = math.random(minGrid,maxGrid)
        local centerGrid1Z = math.random(minGrid,maxGrid)
        local zoneLv = MapHelper:GetZoneLevelByGrid1(centerGrid1X,centerGrid1Z)
        if zoneLv ~= 4 then continue end

        -- local r = math.random(6,8)
        local r = 4
        local suc = tryCreateTerrain(centerGrid1X,centerGrid1Z,r,-1)
        if not suc then continue end
        sinkNum += 1
        -- 判断是否换成雷神锤事件
        local eventName = holdEvents[math.random(1,#holdEvents)]
        if eventName == "雷神锤" then
            print("生成雷神锤子坑",centerGrid1X,centerGrid1Z)
            -- 重新生成中心点为普通地块
            local ground = MapHelper:FindGroundPart(centerGrid1X,centerGrid1Z)
            local cframe = ground:GetPivot()
            ground:Destroy()
            ground = createNormalLand(centerGrid1X,centerGrid1Z,cframe.Position.Y,"雷神锤子专属地块")
            MapHelper:SetMapGridType(centerGrid1X,centerGrid1Z,GridType.Special)
        elseif eventName == "老矿镇" then
            print("老矿镇",centerGrid1X,centerGrid1Z)
            local prefab = workspace:FindFirstChild("Prefabs"):WaitForChild("老矿镇"):WaitForChild("5x5,老矿镇")
            local size = MapHelper:GetResPointSize(prefab)
            local sizeX,sizeZ = MapHelper:RandomBuildingSize(size.X,size.Y)
            local building = MapHelper:CreateBuildingOnCenter(centerGrid1X,centerGrid1Z,sizeX,sizeZ,GridType.Special,prefab,"空地块")
            MapHelper:initBuilding(building,MapHelper:Grid1ToGrid2(centerGrid1X,centerGrid1Z))
            building.Parent = _mapParent
            prefab:Destroy()
        end
    end
    print("随机坑数量：",sinkNum)

    -- 平原
    for grid1X = 1,MapHelper.mapSize_1 do
        for grid1Z = 1,MapHelper.mapSize_1 do
            local gridType = MapHelper:GetMapGridType(grid1X,grid1Z)
            if gridType then continue end
            gridType = GridType.land
            -- local posY = 0
            local posY = math.random() * math.random(-1,1)
            -- local posY = math.random() * 3.8 - 1.9
            -- local sign = math.random(1,2) == 1 and 1 or -1
            -- posY = posY + sign * math.random()
            -- if math.abs(posY) >= 2 then
            --     posY = 2 * sign
            --     sign *= -1
            -- end

            -- 生成普通草地
            local groundPrefabName:string
            if math.random(1,250) <= 1 then
                gridType = GridType.pond
                groundPrefabName = "池塘"
            end
            local ground:Part = createNormalLand(grid1X,grid1Z,posY,groundPrefabName)
            MapHelper:SetMapGridType(grid1X,grid1Z,gridType)
        end
    end
end

-- 获取资源点大小
function getResPointSize(prefab:Instance)
    return MapHelper:GetResPointSize(prefab)
end

-- 初始化宝箱点位
function initTreasurePoint()
    local zoneNum = {
        0,
        math.random(5,7),
        math.random(7,10),
        math.random(7,10),
        math.random(7,10),
        math.random(7,10),
    }

    local folder = workspace:FindFirstChild("Prefabs"):FindFirstChild("Map"):FindFirstChild("宝箱资源点")
    local prefabs = folder:GetChildren()
    local gridType = GridType.building
    for zoneLv = 1,#zoneNum do
        local num = zoneNum[zoneLv]
        local zoneGridVos = MapHelper.ZoneMap2[zoneLv]
        for i=1,num do
            local prefab = prefabs[math.random(1,#prefabs)]
            local size = getResPointSize(prefab)
            for j=1,10 do
                local grid2Vo = zoneGridVos[math.random(1,#zoneGridVos)]
                local grid2X = grid2Vo.x
                local grid2Z = grid2Vo.z
                local building = tryCreateLandmark(grid2X,grid2Z,size.X,size.Y,gridType,prefab)
                if building then
                    building.Name = string.format("%d级区域宝箱点",zoneLv)
                    initBuilding(building,grid2X,grid2Z)
                    break
                end
            end
        end
    end
    folder:Destroy()
end

function initResPoint()
    local folder = workspace:FindFirstChild("Prefabs"):FindFirstChild("Map"):FindFirstChild("资源点")
    local prefabs = folder:GetChildren()
    local gridType = GridType.building
    for grid2X = 1,MapHelper.mapSize_2 do
        for grid2Z = 1,MapHelper.mapSize_2 do
            local count = math.random(2,5)
            for i=1,count do
                local prefab = prefabs[math.random(1,#prefabs)]
                local size = getResPointSize(prefab)
                local building = tryCreateLandmark(grid2X,grid2Z,size.X,size.Y,gridType,prefab)
                initBuilding(building,grid2X,grid2Z)
            end
        end
    end
    -- folder:Destroy()
end

function initTrap()
    local folder = workspace:FindFirstChild("Prefabs"):FindFirstChild("Map"):FindFirstChild("陷阱")
    local prefabs = folder:GetChildren()
    local gridType = GridType.building
    for zoneLv = 5,#CampfireSetting.data do
        local num = math.random(5,10)
        local zoneGridVos = MapHelper.ZoneMap2[zoneLv]
        for i=1,num do
            local prefab = prefabs[math.random(1,#prefabs)]
            local size = getResPointSize(prefab)
            for j=1,10 do
                local grid2Vo = zoneGridVos[math.random(1,#zoneGridVos)]
                local grid2X = grid2Vo.x
                local grid2Z = grid2Vo.z
                local building = tryCreateLandmark(grid2X,grid2Z,size.X,size.Y,gridType,prefab)
                if building then
                    building.Name = string.format("%d级区域陷阱",zoneLv)
                    initBuilding(building,grid2X,grid2Z)
                    break
                end
            end
        end
    end
    folder:Destroy()
end

print("初始化地图...")
MapHelper:init()
initMarsh()
initSnowfield()
initTrain()
initNormalLand()
initKingMooseNest()
initDefaultBuilding()
initLightHouse()
initGemTower()
initStronghole()
initBellCave()
initHospital()
initGunHouse()
initWeaponWorkshop()
initGearSourcePoints()
initGoldPan()
initMiniEvents()
initTreasurePoint()
initResPoint()
-- initTrap() -- 暂时不生成这种陷阱
initAreaSide()
_specialHouse:Destroy()
GameHelper.tryCreateMiniEvent.Event:Connect(tryCreateMiniEvent)
MapHelper.isInit = true
MapHelper.onMapInitComplete:Fire()
print("地图初始化完成,格子数量："..tostring(MapHelper.mapSize_1 * MapHelper.mapSize_1))
-- print("发射？")

local _mapMarkerFolder:Model = workspace:FindFirstChild("MapMarkers")
if not _mapMarkerFolder then
    _mapMarkerFolder = Instance.new("Model")
    _mapMarkerFolder.Name = "MapMarkers"
    _mapMarkerFolder.ModelStreamingMode = Enum.ModelStreamingMode.Persistent
    _mapMarkerFolder.Parent = workspace
end

local _mapMarkersByUserId = {}

local function getMarkerName(userId:number)
    return string.format("MapMarker_%d",userId)
end

local function canUseMapMarkers(player:Player)
    return GameHelper:isAlive(player) and #CollectionService:GetTagged(GameEnum.Tag.Map) > 0
end

local function getCampfireState()
    local heat = GameHelper:GetCampfireHeat()
    local level = GameHelper:GetCampfireLevel()
    return heat, level
end

local function destroyMarkerModel(userId:number)
    local markerModel = _mapMarkerFolder:FindFirstChild(getMarkerName(userId))
    if markerModel then
        markerModel:Destroy()
    end
end

local function buildMarkerVo(player:Player,position:Vector3)
    return {
        userId = player.UserId,
        nickname = player.DisplayName,
        position = position,
    }
end

local function createMarkerModel(markerVo)
    local prefab = workspace.Prefabs.Map:FindFirstChild("MapMarker")
    if not prefab then return end

    destroyMarkerModel(markerVo.userId)

    local markerModel:Model = prefab:Clone()
    markerModel.Name = getMarkerName(markerVo.userId)
    markerModel:PivotTo(CFrame.new(markerVo.position + Vector3.new(0,1.25,0)))
    markerModel.Parent = _mapMarkerFolder
    markerModel:SetAttribute("userId",markerVo.userId)
    markerModel:SetAttribute("nickname",markerVo.nickname)

    local root:BasePart = markerModel.PrimaryPart or markerModel:FindFirstChild("Root")
    if root then
        local billboard:BillboardGui = root:FindFirstChild("BillboardGui")
        if billboard then
            local t_name:TextLabel = billboard:FindFirstChild("t_name")
            if t_name then
                t_name.Text = markerVo.nickname
            end
        end
    end
end

local function isMarkerPositionUnlocked(position:Vector3,campfireLevel:number)
    local grid1X,grid1Z = MapHelper:Pos2Grid1(position)
    if not MapHelper:IsInMapGrid1(grid1X,grid1Z) then
        return false
    end
    return MapHelper:GetZoneLevelByGrid1(grid1X,grid1Z) <= campfireLevel
end

local function resolveMarkerWorldPosition(scale:Vector2)
    local worldPos = MapHelper:MapScaleToWorldPos(scale.X,scale.Y)
    local groundPoint = MapHelper:GetGroundPoint(Vector3.new(worldPos.X,10,worldPos.Z))
    if groundPoint then
        return groundPoint
    end
    return MapHelper:GetSafeLandingPoint(worldPos)
end

local function getMarkerSnapshot()
    local markers = {}
    for _,markerVo in pairs(_mapMarkersByUserId) do
        table.insert(markers,markerVo)
    end
    table.sort(markers,function(a,b)
        return a.userId < b.userId
    end)
    return markers
end

local function sendMarkerSnapshot(player:Player)
    GameHelper.MapMarkerSnapshotS2C:FireClient(player,getMarkerSnapshot())
end

local function upsertPlayerMarker(player:Player,position:Vector3)
    local markerVo = buildMarkerVo(player,position)
    _mapMarkersByUserId[player.UserId] = markerVo
    createMarkerModel(markerVo)
    GameHelper.MapMarkerUpsertS2C:FireAllClients(markerVo)
end

local function removePlayerMarker(userId:number)
    if not _mapMarkersByUserId[userId] then return end
    _mapMarkersByUserId[userId] = nil
    destroyMarkerModel(userId)
    GameHelper.MapMarkerRemoveS2C:FireAllClients(userId)
end

GameHelper.PlaceMapMarkerC2S.OnServerEvent:Connect(function(player:Player,mapScale:Vector2)
    if typeof(mapScale) ~= "Vector2" then return end
    if not canUseMapMarkers(player) then return end

    local heat, level = getCampfireState()
    if heat <= 0 then return end
    if mapScale.X < 0 or mapScale.X > 1 or mapScale.Y < 0 or mapScale.Y > 1 then return end

    local position = resolveMarkerWorldPosition(mapScale)
    if not position then return end
    if not isMarkerPositionUnlocked(position,level) then return end

    upsertPlayerMarker(player,position)
end)

GameHelper.RemoveMapMarkerC2S.OnServerEvent:Connect(function(player:Player)
    removePlayerMarker(player.UserId)
end)

game.Players.PlayerAdded:Connect(function(player:Player)
    task.spawn(function()
        player:WaitForChild("PlayerGui")
        task.wait(1)
        if player:IsDescendantOf(game.Players) then
            sendMarkerSnapshot(player)
        end
    end)
end)

game.Players.PlayerRemoving:Connect(function(player:Player)
    removePlayerMarker(player.UserId)
end)

for _,player:Player in ipairs(game.Players:GetPlayers()) do
    task.spawn(function()
        player:WaitForChild("PlayerGui")
        task.wait(1)
        if player:IsDescendantOf(game.Players) then
            sendMarkerSnapshot(player)
        end
    end)
end
