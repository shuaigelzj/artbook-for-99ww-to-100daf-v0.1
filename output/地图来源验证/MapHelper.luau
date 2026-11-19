local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local CommonFunc = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("framework"):WaitForChild("CommonFunc"))
local ConfigHelper = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("framework"):WaitForChild("ConfigHelper"))
local GameEnum = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("GameEnum"))
local GameType = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("GameType"))
local ValueHelper = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("Helpers"):WaitForChild("ValueHelper"))

local CampfireSetting = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("ExcelConfig"):WaitForChild("CampfireSetting"))

local CampfireValue = ValueHelper.ValueModel.CampfireValue
local CraftingBenchValue = ValueHelper.ValueModel.CraftingBenchValue
local WantedValue = ValueHelper.ValueModel.WantedValue
local GemTowerValue = ValueHelper.ValueModel.GemTowerValue
local GroundValue = ValueHelper.ValueModel.GroundValue
local BuildingValue = ValueHelper.ValueModel.BuildingValue

local MapHelper = {}

MapHelper.onMapInitComplete = CommonFunc:InitBindableEvent(script,"onMapInitComplete")

MapHelper.gridSize_1 = game.ReplicatedStorage.DefaultSetting:FindFirstChild("格子大小1").Value::number
MapHelper.gridSize_2 = game.ReplicatedStorage.DefaultSetting:FindFirstChild("格子大小2").Value::number
-- MapHelper.mapSize_1 = game.ReplicatedStorage.DefaultSetting:FindFirstChild("地图大小").Value::number
-- MapHelper.mapSize_2 = MapHelper.mapSize_1 / MapHelper.gridSize_2
MapHelper.mapSize_2 = game.ReplicatedStorage.DefaultSetting:FindFirstChild("地图大小").Value::number
MapHelper.GridInfoEnable = game.ReplicatedStorage:WaitForChild("DebugSetting"):WaitForChild("显示网格信息").Value::boolean

MapHelper.mapSize_1 = MapHelper.mapSize_2 * MapHelper.gridSize_2
MapHelper.mapSize = MapHelper.mapSize_2 * MapHelper.gridSize_2 * MapHelper.gridSize_1
MapHelper.centerGrid1 = math.ceil(MapHelper.mapSize_1 / 2)
MapHelper.centerGrid2 = math.ceil(MapHelper.mapSize_2 / 2)

MapHelper.halfGridSize_1 = MapHelper.gridSize_1 / 2
MapHelper.halfGridSize_2 = MapHelper.gridSize_2 / 2
MapHelper.startX = -MapHelper.mapSize_1 / 2 * MapHelper.gridSize_1 + MapHelper.halfGridSize_1
MapHelper.startZ = -MapHelper.mapSize_1 / 2 * MapHelper.gridSize_1 + MapHelper.halfGridSize_1


MapHelper.GridType = {
    campfireLand = 1,-- 营地
    building = 2,-- 建筑物
    Stronghold = 3,-- 神枪手据点
    GemTower = 4,-- 宝石塔
    Hospital = 5,-- 医院
    MiniStronghold = 6,-- 小据点
    LightHouse = 7,-- 灯房子
    Special = 8,-- 特殊地块
    Marsh = 9, -- 沼泽
    MarshPond = 10, -- 沼泽
    ToxicSwamp = 11, -- 有毒沼泽
    Railway = 12, -- 铁路
    Snowfield = 13, -- 雪原
    SnowfieldPond = 14, -- 雪原池塘
    land = 101,-- 地块
    pond = 102,-- 池塘
}

MapHelper.CaveY = {
    WildBoarCave = -150, -- 野猪王洞穴
    Train = -200, -- 火车
    BellCave1 = -230, -- 1级铃铛洞穴
    BellCave2 = -270, -- 2级铃铛洞穴
    BullCave = -100, -- 牛牛副本
}

MapHelper.ZoneMap2 = {}::{{GameType.GridVo}} -- Grid2等级划分映射
MapHelper.ZoneMap1 = {}::{{GameType.GridVo}} -- Grid1等级划分映射
MapHelper.EnterGroundMarks = {}::{boolean}
MapHelper.isInit = false

local _map:{{number}} = {}
local _resPointSizeMap:{Vector2} = {}

math.randomseed(tick())
function MapHelper:init()
    for grid2X = 1,MapHelper.mapSize_2 do
        for grid2Z = 1,MapHelper.mapSize_2 do
            local level = MapHelper:GetZoneLevelByGrid2Pos(grid2X,grid2Z)
            if not MapHelper.ZoneMap2[level] then
                MapHelper.ZoneMap2[level] = {}
            end
            local gridVo:GameType.GridVo = {
                x = grid2X,
                z = grid2Z
            }
            table.insert(MapHelper.ZoneMap2[level],gridVo)
        end
    end

    for grid1X = 1,MapHelper.mapSize_1 do
        for grid1Z = 1,MapHelper.mapSize_1 do
            local level = MapHelper:GetZoneLevelByGrid1(grid1X,grid1Z)
            if not MapHelper.ZoneMap1[level] then
                MapHelper.ZoneMap1[level] = {}
            end
            local gridVo:GameType.GridVo = {
                x = grid1X,
                z = grid1Z
            }
            table.insert(MapHelper.ZoneMap1[level],gridVo)
        end
    end
end

function MapHelper:GetMapGridType(grid1X:number,grid1Z:number)
    if not _map[grid1X] then
        return
    end
    return _map[grid1X][grid1Z]
end

function MapHelper:GetIsSafetyRange(centerGrid1X:number,centerGrid1Z:number,r:number)
    local centerGridType = MapHelper:GetMapGridType(centerGrid1X,centerGrid1Z)
    if centerGridType then return end

    for offsetX =-r,r do
        for offsetZ=-r, r do
            local grid1X = offsetX + centerGrid1X
            local grid1Z = offsetZ + centerGrid1Z
            local gridType = MapHelper:GetMapGridType(grid1X,grid1Z)
            if gridType then return end
        end
    end

    return true
end

function MapHelper:GetMapGridTypeByGround(ground:Part)
    local gridVo:Vector3 = ValueHelper:FindValueValue(ground,GroundValue.grid)
    return MapHelper:GetMapGridType(gridVo.X,gridVo.Z)
end

function MapHelper:SetMapGridType(grid1X:number,grid1Z:number,mapType:number)
    if not _map[grid1X] then
        _map[grid1X] = {}
    end
    _map[grid1X][grid1Z] = mapType
end

function MapHelper:GetCampfireLo(level:number)
    local lo:CampfireSetting.Type = ConfigHelper:GetById(CampfireSetting,level)
    return lo
end

function MapHelper:GetGridPos(grid1X:number,grid1Z:number)
    local posX = MapHelper.startX + (grid1X-1) * MapHelper.gridSize_1
    local posZ = MapHelper.startZ + (grid1Z-1) * MapHelper.gridSize_1
    return posX,posZ
end

function MapHelper:GetGridPos3(grid1X:number,grid1Z:number)
    local posX,posZ = MapHelper:GetGridPos(grid1X,grid1Z)
    return Vector3.new(posX,0,posZ)
end

function MapHelper:MapScaleToWorldPos(scaleX:number,scaleZ:number,y:number?)
    local worldX = math.clamp(scaleX,0,1) * MapHelper.mapSize - MapHelper.mapSize / 2
    local worldZ = math.clamp(scaleZ,0,1) * MapHelper.mapSize - MapHelper.mapSize / 2
    return Vector3.new(worldX,y or 0,worldZ)
end

function MapHelper:Pos2Grid1(position:Vector3)
    local mapX = position.X - (MapHelper.startX - MapHelper.halfGridSize_1)
    local mapZ = position.Z - (MapHelper.startZ - MapHelper.halfGridSize_1)
    local grid1X = math.ceil(mapX / MapHelper.gridSize_1)
    local grid1Z = math.ceil(mapZ / MapHelper.gridSize_1)
    return grid1X,grid1Z
end

function MapHelper:GetMapParent()
    local mapParent:Folder
    if RunService:IsServer() then
        mapParent = workspace:FindFirstChild("Map")
        if not mapParent then
            mapParent = Instance.new("Folder")
            mapParent.Name = "Map"
            mapParent.Parent = workspace
        end
    else
        mapParent = workspace:WaitForChild("Map")
    end
    return mapParent
end

function MapHelper:GetGroundPart(grid1X:number,grid1Z:number)
    local groundName = string.format("%d,%d",grid1X,grid1Z)
    local ground:Part = MapHelper:GetMapParent():WaitForChild(groundName)
    return ground
end

function MapHelper:GetLandingPoint(position:Vector3)
    local ground = MapHelper:GetGroundPart(MapHelper:Pos2Grid1(position))
    if not ground then return end
    local groundPos = ground.Position
    local ret = Vector3.new(position.X,groundPos.Y + ground.Size.Y / 2,position.Z)
    return ret
end

-- 安全着陆点
function MapHelper:GetSafeLandingPoint(position:Vector3)
    local point = MapHelper:GetLandingPoint(position)
    local hitResult:RaycastResult = workspace:Raycast(point + Vector3.yAxis * 100,Vector3.yAxis * -200)
    if hitResult then
        return hitResult.Position + Vector3.new(0,1,0)
    end
end

-- 创建营火
function MapHelper:CreateCampfire()
    local campfire:Model = workspace:WaitForChild("Prefabs"):WaitForChild("Map"):WaitForChild("营火"):WaitForChild("Campfire")
    campfire.Name = "Campfire"
    campfire.Parent = MapHelper:GetMapParent()

    ValueHelper:InitByModel(campfire, CampfireValue)

    return campfire
end

function MapHelper:GetCampfire()
    local mapParent = MapHelper:GetMapParent()
    return mapParent:WaitForChild("Campfire")::Model
end

function MapHelper:CreateCraftingBench()
    local CraftingBench:Model = workspace:WaitForChild("Prefabs"):WaitForChild("Map"):WaitForChild("制造台"):WaitForChild("CraftingBench")
    CraftingBench.Name = "CraftingBench"
    CraftingBench.Parent = MapHelper:GetMapParent()

    ValueHelper:InitByModel(CraftingBench, CraftingBenchValue)

    return CraftingBench
end

function MapHelper:GetCraftingBench()
    local mapParent = MapHelper:GetMapParent()
    return mapParent:WaitForChild("CraftingBench")
end

function MapHelper:GetCraftingBenchModels()
    return workspace:FindFirstChild("Prefabs"):FindFirstChild("Map"):FindFirstChild("制造台"):GetChildren()
end

function MapHelper:CreatWantedBoard()
    local prefab = workspace:WaitForChild("Prefabs"):WaitForChild("Map"):WaitForChild("WantedBoard")

    local WantedBoard:Model = prefab:Clone()
    WantedBoard.Name = "WantedBoard"
    ValueHelper:InitByModel(WantedBoard, WantedValue)
    WantedBoard.Parent = MapHelper:GetMapParent()

    prefab:Destroy()

    return WantedBoard
end

function MapHelper:GetWantedBoard()
    local mapParent = MapHelper:GetMapParent()
    return mapParent:WaitForChild("WantedBoard")
end

function MapHelper:CreateGemTowerController()
    local controller:Model = workspace:FindFirstChild("Prefabs"):FindFirstChild("Map"):FindFirstChild("宝石塔"):FindFirstChild("GemTowerController")
    if not controller then return end
    ValueHelper:InitByModel(controller, GemTowerValue)
    controller.Parent = MapHelper:GetMapParent()

    return controller
end

function MapHelper:GetGemTowerController()
    local mapParent = MapHelper:GetMapParent()
    return mapParent:WaitForChild("GemTowerController")
end

function MapHelper:CreateGemTowerModel(cframe:CFrame)
    local prefab = workspace:FindFirstChild("Prefabs"):FindFirstChild("Map"):FindFirstChild("宝石塔"):FindFirstChild("GemTower")
    local _model:Model = prefab:Clone()
    _model:PivotTo(cframe)
    _model:AddTag("UIGemTower")
    _model.Parent = MapHelper:GetMapParent()
    prefab:Destroy()
    return _model
end

function MapHelper:GetGemTowerModel()
    local mapParent = MapHelper:GetMapParent()
    return mapParent:FindFirstChild("GemTower")
end

function MapHelper:FindGroundPart(grid1X:number,grid1Z:number)
    local mapParent:Part = MapHelper:GetMapParent()
    local groundName = string.format("%d,%d",grid1X,grid1Z)
    local ground:Part = mapParent:FindFirstChild(groundName)
    return ground
end

function MapHelper:GetGroundPoint(position:Vector3)
    local raycastParams = RaycastParams.new()
    raycastParams:AddToFilter(CollectionService:GetTagged(GameEnum.Tag.Player))
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.CollisionGroup = GameEnum.CollisionGroup.OnlyGround
    local hitResult:RaycastResult = workspace:Raycast(position + Vector3.new(0, 1, 0), Vector3.new(0, -20, 0), raycastParams)
    if hitResult then
        -- if hitResult.Instance:HasTag(GameEnum.Tag.Ground) then
        --     return hitResult.Position
        -- end
        return hitResult.Position
    end
    return nil -- 没有着陆点
end

function MapHelper:GetTreeSeekPlantPoint(treeSeek:Model)
    local position = treeSeek:GetPivot().Position
    local raycastParams = RaycastParams.new()
    raycastParams:AddToFilter(CollectionService:GetTagged(GameEnum.Tag.Ground))
    raycastParams.FilterType = Enum.RaycastFilterType.Include
    local hitResult:RaycastResult = workspace:Raycast(position + Vector3.new(0, 1, 0), Vector3.new(0, -20, 0), raycastParams)
    if hitResult then
        -- print(hitResult.Instance.Name)
        if hitResult.Instance:HasTag(GameEnum.Tag.Ground) then
            -- print(position, hitResult.Position)
            return hitResult.Position
        end
    end
    return nil -- 没有着陆点
end

function MapHelper:GetZoneLevelByGrid2(grid2:number)
    local level = math.ceil(math.abs(grid2 - MapHelper.centerGrid2)) + 1
    return level
end

function MapHelper:GetZoneLevelByGrid2Pos(grid2X:number,grid2Z:number)
    local level = math.max(MapHelper:GetZoneLevelByGrid2(grid2X),MapHelper:GetZoneLevelByGrid2(grid2Z))
    return level
end

function MapHelper:GetZoneLevelByGrid1(grid1X:number,grid1Z:number)
    local level = MapHelper:GetZoneLevelByGrid2Pos(MapHelper:Grid1ToGrid2(grid1X,grid1Z))
    return level
end

function MapHelper:GetZoneLevelByPos(pos:Vector3)
    local level = MapHelper:GetZoneLevelByGrid1(MapHelper:Pos2Grid1(pos))
    return level
end

function MapHelper:Grid1ToGrid2(grid1X:number,grid1Z:number)
    local grid2X = math.ceil(grid1X / MapHelper.gridSize_2)
    local grid2Z = math.ceil(grid1Z / MapHelper.gridSize_2)
    return grid2X,grid2Z
end

function MapHelper:RandomGrid1Point(grid2X:number,grid2Z:number)
    local gird1XMax = grid2X * MapHelper.gridSize_2
    local gird1XMin = (grid2X - 1) * MapHelper.gridSize_2 + 1
    local gird1ZMax = grid2Z * MapHelper.gridSize_2
    local gird1ZMin = (grid2Z - 1) * MapHelper.gridSize_2 + 1
    local spawnGrid1X = math.random(gird1XMin,gird1XMax)
    local spawnGrid1Z = math.random(gird1ZMin,gird1ZMax)
    return spawnGrid1X,spawnGrid1Z
end

-- 获取资源点大小
function MapHelper:GetResPointSize(prefab:Instance)
    local size = _resPointSizeMap[prefab]
    if not size then
        local sizeStr = prefab.Name:split(",")[1]:split("x")
        size = Vector2.new(tonumber(sizeStr[1]),tonumber(sizeStr[2]))
        _resPointSizeMap[prefab] = size
    end

    return size
end

function MapHelper:CreateBuilding(spawnGrid1X:number,spawnGrid1Z:number,sizeX:number,sizeZ:number,gridType:number,landmarkPrefab:Model,groundName:string?)
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

                    local newGround = MapHelper:CreateNormalLand(grid1X,grid1Z,groundPosY,groundName)
                    -- 复制Tag
                    local tags = ground:GetTags()
                    for _,tag in ipairs(tags) do
                        newGround:AddTag(tag)
                    end
                    ground:Destroy()
                    ground = newGround
                end
                if not ground then
                    ground = MapHelper:CreateNormalLand(grid1X,grid1Z,groundPosY,groundName)
                end
                if groundPosY then
                    local cframe = ground:GetPivot()
                    ground:PivotTo(cframe.Rotation + Vector3.new(cframe.Position.X,groundPosY,cframe.Position.Z))
                else
                    groundPosY = ground.Position.Y
                end

                MapHelper:SetMapGridType(grid1X,grid1Z,gridType or MapHelper.GridType.building)
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
        local landmark = landmarkPrefab:Clone()
        landmark:PivotTo(CFrame.new(position) * CFrame.Angles(0,math.rad(rotationY),0))
        landmark.Parent = MapHelper:GetMapParent()

        return landmark
end

function MapHelper:CreateBuildingOnCenter(spawnGrid1X:number,spawnGrid1Z:number,sizeX:number,sizeZ:number,gridType:number,landmarkPrefab:Model,groundName:string?)
    local groundPosY = nil
    local minPos = MapHelper:GetGridPos3(spawnGrid1X,spawnGrid1Z)
    local maxPos = minPos
    for offsetX = 1, sizeX do
        for offsetZ = 1, sizeZ do
            local grid1X = spawnGrid1X + offsetX - math.ceil(sizeX / 2)
            local grid1Z = spawnGrid1Z + offsetZ - math.ceil(sizeZ / 2)
            -- print(grid1X, grid1Z)
            local ground = MapHelper:FindGroundPart(grid1X,grid1Z)
            if groundName and ground then
                if not groundPosY then
                    groundPosY = ground.Position.Y
                end

                local newGround = MapHelper:CreateNormalLand(grid1X,grid1Z,groundPosY,groundName)
                -- 复制Tag
                local tags = ground:GetTags()
                for _,tag in ipairs(tags) do
                    newGround:AddTag(tag)
                end
                ground:Destroy()
                ground = newGround
            end
            if not ground then
                ground = MapHelper:CreateNormalLand(grid1X,grid1Z,groundPosY,groundName)
            end
            if groundPosY then
                local cframe = ground:GetPivot()
                ground:PivotTo(cframe.Rotation + Vector3.new(cframe.Position.X,groundPosY,cframe.Position.Z))
            else
                groundPosY = ground.Position.Y
            end

            local tempPos = MapHelper:GetGridPos3(grid1X,grid1Z)
            minPos = Vector3.min(minPos,tempPos)
            maxPos = Vector3.max(maxPos,tempPos)

            MapHelper:SetMapGridType(grid1X,grid1Z,gridType or MapHelper.GridType.building)
        end
    end

    -- local posX,posZ = MapHelper:GetGridPos(spawnGrid1X,spawnGrid1Z)
    local posX = minPos.X + (maxPos.X - minPos.X) / 2
    local posZ = minPos.Z + (maxPos.Z - minPos.Z) / 2
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
    local landmark = landmarkPrefab:Clone()
    landmark:PivotTo(CFrame.new(position) * CFrame.Angles(0,math.rad(rotationY),0))
    landmark.Parent = MapHelper:GetMapParent()

    return landmark
end

function MapHelper:initBuilding(building:BasePart,grid2X:number,grid2Z:number)
    if not building then return end
    ValueHelper:InitByModel(building,BuildingValue)
    ValueHelper:SetValue(building,BuildingValue.grid2,Vector3.new(grid2X,0,grid2Z))
    ValueHelper:SetValue(building,BuildingValue.level,MapHelper:GetZoneLevelByGrid2Pos(grid2X,grid2Z))
    building:AddTag(GameEnum.Tag.Building)
end

function MapHelper:CreateNormalLand(grid1X:number,grid1Z:number,posY:number,prefabName:string?)
    if not prefabName then
        -- prefabName = string.format("%d级地块",zoneLv)
        prefabName = "Grassland"
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
    
    ground.Parent = MapHelper:GetMapParent()

    local surface:SurfaceGui = ground:FindFirstChildWhichIsA("SurfaceGui",true)
    if surface then
        if RunService:IsStudio() and MapHelper.GridInfoEnable then
            surface.Enabled = true
            -- local grid2X = math.ceil(grid1X / MapHelper.gridSize_2)
            -- local grid2Z = math.ceil(grid1Z / MapHelper.gridSize_2)
            local grid2X,grid2Z = MapHelper:Grid1ToGrid2(grid1X,grid1Z)
            -- local c1 = grid2X / MapHelper.gridSize_2
            -- local c2 = grid2Z / MapHelper.gridSize_2
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

function MapHelper:RandomBuildingSize(sizeX:number,sizeZ:number)
    if sizeX ~= sizeZ and math.random(1,2) == 1 then
        local oldZ = sizeZ
        sizeZ = sizeX
        sizeX = oldZ
    end
    return sizeX,sizeZ
end

function MapHelper:IsInMapGrid1(grid1X:number,grid1Z:number)
    if grid1X < 1 or grid1X > MapHelper.mapSize_1 then
        return false
    end
    if grid1Z < 1 or grid1Z > MapHelper.mapSize_1 then
        return false
    end
    return true
end

function MapHelper:GetIsSafetyBuildingPoint(spawnGrid1X:number,spawnGrid1Z:number,sizeX:number,sizeZ:number,safeGridType:number?)
    if not safeGridType then
        safeGridType = MapHelper.GridType.land
    end

    for offsetX = 1, sizeX do
        for offsetZ = 1, sizeZ do
            local grid1X = spawnGrid1X + offsetX - 1
            local grid1Z = spawnGrid1Z + offsetZ - 1
            local tempGridType = MapHelper:GetMapGridType(grid1X,grid1Z)
            if tempGridType and tempGridType ~= safeGridType then
                return false
            end
        end
    end
    return true
end

local raycastGroundDir = Vector3.new(0,-100,0)
function MapHelper:RaycastGroundFromPart(part:BasePart,tag:string)
    local grounds = CollectionService:GetTagged(tag)
    if #grounds == 0 then return end

    local raycastParams = RaycastParams.new()
    raycastParams:AddToFilter(grounds)
    raycastParams.FilterType = Enum.RaycastFilterType.Include

    local hitResult:RaycastResult = workspace:Raycast(part.Position,raycastGroundDir,raycastParams)
    return hitResult
end

function MapHelper:SpawnSnow(ground:Part)
    -- 随机雪块
    local posX = ground.Position.X
    local posZ = ground.Position.Z
    local groundY = ground.Position.Y + ground.Size.Y / 2
    local num = math.random(1,3)
    local folder = workspace:FindFirstChild("Prefabs"):FindFirstChild("Map"):FindFirstChild("雪块")
    for i=1,num do
        local childs = folder:GetChildren()
        local snowX = math.random(posX-MapHelper.halfGridSize_1,posX + MapHelper.halfGridSize_1)
        local snowZ = math.random(posZ-MapHelper.halfGridSize_1,posZ + MapHelper.halfGridSize_1)
        -- local rotationY = math.random() * 360
        local rotationY = math.random(0,3) * 90
        local prefab:Model = childs[math.random(1,#childs)]
        local snow = prefab:Clone()
        snow:PivotTo(CFrame.Angles(0,math.rad(rotationY),0)+Vector3.new(snowX,groundY,snowZ))
        -- stone:PivotTo(prefab:GetPivot().Rotation + Vector3.new(stoneX,groundY,stoneZ))
        snow.Parent = workspace
    end
end

function MapHelper:GetBuildingEnterPlayerKey(Player:Player)
    return string.format("EnterBuildingPlayer_%d",Player.UserId)
end

function MapHelper:GetBuildingActivity(building:Model)
    if not building then return false end

    for _,player:Player in ipairs(game.Players:GetPlayers()) do
        if building:HasTag(MapHelper:GetBuildingEnterPlayerKey(player)) then
            return true
        end
    end

    return false
end

return MapHelper
