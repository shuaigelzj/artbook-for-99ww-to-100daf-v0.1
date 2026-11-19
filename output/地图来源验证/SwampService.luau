local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local CommonFunc = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("framework"):WaitForChild("CommonFunc"))
local ConfigHelper = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("framework"):WaitForChild("ConfigHelper"))
local GameEnum = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("GameEnum"))
local ValueHelper = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("Helpers"):WaitForChild("ValueHelper"))
local GameHelper = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("Helpers"):WaitForChild("GameHelper"))
local MapHelper = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("Helpers"):WaitForChild("MapHelper"))
local EnemyHelper = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("Helpers"):WaitForChild("EnemyHelper"))
local ResourcesItemHelper = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("Helpers"):WaitForChild("ResourcesItemHelper"))
local EnemySetting = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("ExcelConfig"):WaitForChild("EnemySetting"))

if not GameHelper.Switch.Marsh then return end

local _parent = workspace:FindFirstChild("沼泽")
if not _parent then
    _parent = Instance.new("Folder")
    _parent.Name = "沼泽"
    _parent.Parent = workspace
end

local CharacterValue = ValueHelper.ValueModel.CharacterValue
local WeatherValue = ValueHelper.ValueModel.WeatherValue
local GroundValue = ValueHelper.ValueModel.GroundValue
local GridType = MapHelper.GridType

local _specialHouse:Folder = workspace:FindFirstChild("Prefabs"):FindFirstChild("沼泽Map"):FindFirstChild("特殊房子")
local _controller = GameHelper:GetController()
local v_weather:IntValue = ValueHelper:WaitValue(_controller,WeatherValue.weather)

local _enemyIdsMap = {}
_enemyIdsMap[3] = {110}
_enemyIdsMap[4] = {107}
_enemyIdsMap[5] = {107,108}
_enemyIdsMap[6] = {108}

local _mushroomIds = {234,235,236}
local _mushroomSpawnMarks:{boolean} = {}
local _enterGroundMarks:{Part} = {}
local _groundIsCanSpawnAnimal:{boolean} = {}
local _groundAnimals:{Model} = {}
local _init = false
math.randomseed(tick())

function spawnStore(ground:Part,folderName:string?)
    if not ground then return end
    local prefab:Model
    local folder = workspace:FindFirstChild("Prefabs"):FindFirstChild("沼泽Map"):FindFirstChild(folderName or "装饰")
    if folder then
        local childs = folder:GetChildren()
        if #childs > 0 then
            local posX = ground.Position.X
            local posZ = ground.Position.Z
            local groundY = ground.Position.Y + ground.Size.Y / 2
            local stoneX = math.random(posX-MapHelper.halfGridSize_1,posX + MapHelper.halfGridSize_1)
            local stoneZ = math.random(posZ-MapHelper.halfGridSize_1,posZ + MapHelper.halfGridSize_1)
            local rotationY = math.random(0,3) * 90
            prefab = childs[math.random(1,#childs)]
            local stone = prefab:Clone()
            stone:PivotTo(CFrame.Angles(0,math.rad(rotationY),0)+Vector3.new(stoneX,groundY,stoneZ))
            stone.Parent = workspace
        end
    end
end

-- 随机石头
function trySpawnStoreAndTree(ground:Part)
    local gridPoint:Vector3 = ValueHelper:FindValueValue(ground,GroundValue.grid)
    local gridType = MapHelper:GetMapGridType(gridPoint.X,gridPoint.Z)
    if gridType == MapHelper.GridType.Marsh then
        local grid1X = gridPoint.X
        local grid1Z = gridPoint.Z
        local posX = ground.Position.X
        local posZ = ground.Position.Z
        local groundY = ground.Position.Y + ground.Size.Y / 2

        -- 随机一些树
        local zoneLevel = MapHelper:GetZoneLevelByGrid1(grid1X,grid1Z)
        local treeCount = 0
        if zoneLevel <= 2 then
            treeCount = math.random(0,3)
        elseif zoneLevel <= 4 then
            treeCount = math.random(0,2)
        else
            treeCount = math.random(0,1)
        end
        for i=1,treeCount do
            local prefabName = "TreeL"
            local tag = GameEnum.Tag.Tree
            if math.random(1,5) <= 1 then
                tag = GameEnum.Tag.BigTree
                prefabName = "TreeXL"
            end
            local tree:Model = workspace:WaitForChild("Prefabs"):WaitForChild("沼泽Map"):WaitForChild("树"):WaitForChild(prefabName):Clone()
            local treeX = math.random(posX-MapHelper.halfGridSize_1,posX + MapHelper.halfGridSize_1)
            local treeZ = math.random(posZ-MapHelper.halfGridSize_1,posZ + MapHelper.halfGridSize_1)

            -- local rotationY:number = math.random() * 360
            local rotationY = math.random(0,3) * 90
            tree:PivotTo(CFrame.new(treeX,groundY,treeZ) * CFrame.Angles(0,math.rad(rotationY),0))
            tree.Parent = workspace
            tree:AddTag(tag)
        end

        -- 随机石块
        if math.random(1,3) <= 1 then
            spawnStore(ground)
        end

        -- 生成雪块
        GameHelper:SpawnSnow(ground)
    end

    -- 在沼泽边缘的地块上生成一些装饰
    if ground:HasTag(GameEnum.Tag.MarshEdgeGround) then
        local r = 1
        for offsetX =-r,r do
            for offsetZ=-r, r do
                local grid1X = gridPoint.X + offsetX
                local grid1Z = gridPoint.Z + offsetZ
                if MapHelper:GetMapGridType(grid1X,grid1Z) == MapHelper.GridType.land then
                    local g = MapHelper:FindGroundPart(grid1X,grid1Z)
                    if g:HasTag("SpawnedEdgeStore") then continue end
                    g:AddTag("SpawnedEdgeStore")
                    local num = math.random(1,3)
                    for i=1,num do
                        spawnStore(g,"边缘装饰")
                    end
                end
            end
        end
    end
end

-- 生成蘑菇
function trySpawnMushroom(ground:Part)
    if not ground:HasTag(GameEnum.Tag.MarshGround) then return end
    if _mushroomSpawnMarks[ground] then return end
    _mushroomSpawnMarks[ground] = true
    local gridPoint:Vector3 = ValueHelper:FindValueValue(ground,GroundValue.grid)
    -- local zoneLevel = MapHelper:GetZoneLevelByGrid1(gridPoint.X,gridPoint.Z)
    -- if zoneLevel > 3 then return end

    local gridType = MapHelper:GetMapGridType(gridPoint.X,gridPoint.Z)
    if gridType ~= GridType.Marsh and gridType ~= GridType.ToxicSwamp then return end
    local isSpawn = math.random(1,2) == 1
    if not isSpawn then
        task.delay(300,function()
            _mushroomSpawnMarks[ground] = nil
        end)
        return
    end

    local posY = ground.Position.Y + ground.Size.Y / 2
    local rangeX = ground.Size.X * 0.5
    local rangeZ = ground.Size.Z * 0.5
    local posX = ground.Position.X + math.random(-rangeX,rangeX)
    local posZ = ground.Position.Z + math.random(-rangeZ,rangeZ)
    local mushroomId = _mushroomIds[math.random(1,#_mushroomIds)]
    local resItem = ResourcesItemHelper:CreateItem(mushroomId,CFrame.new(posX,posY,posZ))
    if resItem.PrimaryPart then
        resItem.PrimaryPart.Anchored = true
    end
end

-- 生成鳄鱼/野猪/火鸡
function trySpawnAnimals(ground:Part)
    if _groundIsCanSpawnAnimal[ground] == false then return end

    -- 此地块是否会生成
    local gridPoint:Vector3 = ValueHelper:FindValueValue(ground,GroundValue.grid)
    local gridType = MapHelper:GetMapGridType(gridPoint.X,gridPoint.Z)
    if gridType ~= MapHelper.GridType.Marsh and gridType ~= GridType.ToxicSwamp then
        -- 如果非普通地块则不生成
        _groundIsCanSpawnAnimal[ground] = false
    end

    -- 获得敌人随机组id
    local zoneLevel = MapHelper:GetZoneLevelByGrid1(gridPoint.X,gridPoint.Z)
    local enemyIds = _enemyIdsMap[zoneLevel]
    if not enemyIds then
        _groundIsCanSpawnAnimal[ground] = false
        return
    end

    local enemyId = enemyIds[math.random(1,#enemyIds)]
    if _groundIsCanSpawnAnimal[ground] == nil then
        local enemyLo:EnemySetting.Type = ConfigHelper:GetById(EnemySetting,enemyId)
        _groundIsCanSpawnAnimal[ground] = math.random(1,100) <= enemyLo.spawnPercent
    end

    if _groundIsCanSpawnAnimal[ground] == false then return end

    -- 是否已经执行过生成，生成过不会再生成
    if _groundAnimals[ground] then return end

    local enemyLo:EnemySetting.Type = ConfigHelper:GetById(EnemySetting,enemyId)
    local parent = EnemyHelper:GetEnemyParent(enemyLo.id)
    local posY = ground.Position.Y + ground.Size.Y / 2 + 5
    local rangeX = ground.Size.X * 0.5
    local rangeZ = ground.Size.Z * 0.5
    local animal = EnemyHelper:CreateAnimal(enemyLo.id,parent)
    animal:PivotTo(CFrame.new(
        ground.Position.X + math.random(-rangeX,rangeX),
        posY,
        ground.Position.Z + math.random(-rangeZ,rangeZ)
    ))
    animal.Destroying:Connect(function()
        _groundAnimals[ground] = nil
    end)
    _groundAnimals[ground] = animal
    
    -- 如果死掉就不再刷了
    local humanoid:Humanoid = animal:FindFirstChild("Humanoid")
    humanoid.Died:Connect(function()
        animal:RemoveTag(GameEnum.Tag.AutoStreamingOutDestroy)
        _groundIsCanSpawnAnimal[ground] = false
    end)
    animal:AddTag(GameEnum.Tag.AutoStreamingOutDestroy)
    -- animal:SetAttribute("Grid",string.format("%d,%d",gridPoint.X,gridPoint.Z))

    -- Debris:AddItem(enemy,_animalLifeTime)
end

-- 宝箱点
function initTreasurePoint()
    local parent = Instance.new("Folder")
    parent.Name = "沼泽区域宝箱点"
    parent.Parent = _parent

    local prefabs = workspace:FindFirstChild("Prefabs"):FindFirstChild("沼泽Map"):FindFirstChild("宝箱资源点"):GetChildren()
    local gridType = GridType.building
    -- local num = math.random(15,20)
    local density = GameHelper.MarshSize / 7 -- 计算密度
    local num = math.random(math.ceil(density * 0.9),math.ceil(density * 1.1))
    local grounds = CollectionService:GetTagged(GameEnum.Tag.MarshGround)
    for i=1,num do
        if #grounds <= 0 then break end
        local prefab = prefabs[math.random(1,#prefabs)]
        local size = MapHelper:GetResPointSize(prefab)
        local sizeX,sizeZ = MapHelper:RandomBuildingSize(size.X,size.Y)
        for j=1,10 do
            local ground = grounds[math.random(1,#grounds)]
            local grid1Vo = ValueHelper:FindValueValue(ground,GroundValue.grid)
            if not grid1Vo then
                warn("找不到地块坐标值",ground.Name)
            end
            local grid1X = grid1Vo.X
            local grid1Z = grid1Vo.Z
            if not MapHelper:GetIsSafetyBuildingPoint(grid1X,grid1Z,sizeX,sizeZ,MapHelper.GridType.Marsh) then continue end
            local building = MapHelper:CreateBuilding(grid1X,grid1Z,sizeX,sizeZ,gridType,prefab)
            -- building.Name = "沼泽区域宝箱点"
            MapHelper:initBuilding(building,MapHelper:Grid1ToGrid2(grid1X,grid1Z))
            building.Parent = parent
            break
        end
    end
end

-- 带敌人资源点
function initHasEnemyResPoint()
    local parent = Instance.new("Folder")
    parent.Name = "沼泽区域宝箱点"
    parent.Parent = _parent

    local folder = workspace:FindFirstChild("Prefabs"):FindFirstChild("沼泽Map"):FindFirstChild("带敌人资源点")
    local prefabs = folder:GetChildren()
    local gridType = GridType.building
    local num = 2
    local grounds = CollectionService:GetTagged(GameEnum.Tag.MarshGround)
    for i=1,2 do
        if #grounds <= 0 then break end
        local prefab = prefabs[math.random(1,#prefabs)]
        local size = MapHelper:GetResPointSize(prefab)
        local sizeX,sizeZ = MapHelper:RandomBuildingSize(size.X,size.Y)
        for j=1,10 do
            local ground = grounds[math.random(1,#grounds)]
            local grid1Vo = ValueHelper:FindValueValue(ground,GroundValue.grid)
            if not grid1Vo then
                warn("找不到地块坐标值",ground.Name)
            end
            local grid1X = grid1Vo.X
            local grid1Z = grid1Vo.Z
            if not MapHelper:GetIsSafetyBuildingPoint(grid1X,grid1Z,sizeX,sizeZ,MapHelper.GridType.Marsh) then continue end
            local building = MapHelper:CreateBuilding(grid1X,grid1Z,sizeX,sizeZ,gridType,prefab)
            -- building.Name = "沼泽区域宝箱点"
            MapHelper:initBuilding(building,MapHelper:Grid1ToGrid2(grid1X,grid1Z))
            building.Parent = parent
            break
        end
    end
    folder:Destroy()
end

function initResPoint()
    local parent = Instance.new("Folder")
    parent.Name = "沼泽区域资源"
    parent.Parent = _parent

    local folder = workspace:FindFirstChild("Prefabs"):FindFirstChild("沼泽Map"):FindFirstChild("资源点")
    local prefabs = folder:GetChildren()
    local gridType = GridType.building
    -- local num = math.random(30,35)
    local density = GameHelper.MarshSize / 2 -- 计算密度
    local num = math.random(math.ceil(density * 0.9),math.ceil(density * 1.1))
    local grounds = CollectionService:GetTagged(GameEnum.Tag.MarshGround)
    for i=1,num do
        if #grounds <= 0 then break end
        local prefab = prefabs[math.random(1,#prefabs)]
        local size = MapHelper:GetResPointSize(prefab)
        local sizeX,sizeZ = MapHelper:RandomBuildingSize(size.X,size.Y)
        for j=1,10 do
            local ground = grounds[math.random(1,#grounds)]
            local grid1Vo = ValueHelper:FindValueValue(ground,GroundValue.grid)
            if not grid1Vo then
                warn("找不到地块坐标值",ground.Name)
            end
            local grid1X = grid1Vo.X
            local grid1Z = grid1Vo.Z
            if not MapHelper:GetIsSafetyBuildingPoint(grid1X,grid1Z,sizeX,sizeZ,MapHelper.GridType.Marsh) then continue end
            local building = MapHelper:CreateBuilding(grid1X,grid1Z,sizeX,sizeZ,gridType,prefab)
            -- building.Name = "沼泽区域资源点"
            MapHelper:initBuilding(building,MapHelper:Grid1ToGrid2(grid1X,grid1Z))
            building.Parent = parent
            break
        end
    end
    folder:Destroy()
end

function initSenior()
    local parent = Instance.new("Folder")
    parent.Name = "前辈"
    parent.Parent = _parent

    if not MapHelper.isInit then return end
    local folder = workspace:FindFirstChild("Prefabs"):FindFirstChild("沼泽Map"):FindFirstChild("沼泽前辈")
    local prefabs = folder:GetChildren()
    local gridType = GridType.building
    local grounds = CollectionService:GetTagged(GameEnum.Tag.MarshGround)
    for i=1,2 do
        local prefab = prefabs[math.random(1,#prefabs)]
        local size = MapHelper:GetResPointSize(prefab)
        local sizeX,sizeZ = MapHelper:RandomBuildingSize(size.X,size.Y)
        for j=1,10 do
            local ground = grounds[math.random(1,#grounds)]
            local grid1Vo = ValueHelper:FindValueValue(ground,GroundValue.grid)
            local grid1X = grid1Vo.X
            local grid1Z = grid1Vo.Z
            if not MapHelper:GetIsSafetyBuildingPoint(grid1X,grid1Z,sizeX,sizeZ,MapHelper.GridType.Marsh) then continue end
            local building = MapHelper:CreateBuilding(grid1X,grid1Z,sizeX,sizeZ,gridType,prefab)
            MapHelper:initBuilding(building,MapHelper:Grid1ToGrid2(grid1X,grid1Z))
            building.Parent = parent
            print("生成沼泽前辈",grid1X,grid1Z,prefab.Name)
            break
        end
    end
    folder:Destroy()
end

-- 野猪王巢穴
function initBossEntrance()
    local prefab = _specialHouse:FindFirstChild("2x1,野猪王入口")
    local size = MapHelper:GetResPointSize(prefab)
    local sizeX,sizeZ = MapHelper:RandomBuildingSize(size.X,size.Y)
    local grounds:{Part} = CollectionService:GetTagged(GameEnum.Tag.MarshGround)
    local bossHousePos:Vector3
    for i=1,#grounds do
        local ground = table.remove(grounds,math.random(1,#grounds))
        local grid1Vo = ValueHelper:FindValueValue(ground,GroundValue.grid)
        local grid1X = grid1Vo.X
        local grid1Z = grid1Vo.Z
        local zoneLevel = MapHelper:GetZoneLevelByGrid1(grid1X,grid1Z)
        if zoneLevel ~= 3 then continue end
        if not MapHelper:GetIsSafetyBuildingPoint(grid1X,grid1Z,sizeX,sizeZ,MapHelper.GridType.Marsh) then continue end
        local building = MapHelper:CreateBuilding(grid1X,grid1Z,sizeX,sizeZ,GridType.building,prefab,"空地块")
        MapHelper:initBuilding(building,MapHelper:Grid1ToGrid2(grid1X,grid1Z))
        building.Parent = _parent
        building:AddTag(GameEnum.Tag.MadPigCave)
        bossHousePos = building:GetPivot().Position
        print("生成野猪王入口",grid1X,grid1Z)
        break
    end
    prefab:Destroy()

    -- 野猪王Boss场地
    if bossHousePos then
        local bossHouse:Model = _parent:FindFirstChild("野猪王战场")
        if bossHouse then
            bossHouse:PivotTo(CFrame.new(bossHousePos.X,MapHelper.CaveY.WildBoarCave,bossHousePos.Z))
        end
    end
end

-- 野人之家
function initWildManHome()
    local folder = workspace:FindFirstChild("Prefabs"):FindFirstChild("沼泽Map"):FindFirstChild("土著村落")
    local prefabs = folder:GetChildren()
    local grounds:{Part} = CollectionService:GetTagged(GameEnum.Tag.MarshGround)
    for i=1,5 do
        if #prefabs == 0 then break end
        if #grounds == 0 then break end

        local prefab = table.remove(prefabs,math.random(1,#prefabs))
        for j=1,100 do
            local ground = table.remove(grounds,math.random(1,#grounds))

            local grid1Vo = ValueHelper:FindValueValue(ground,GroundValue.grid)
            local grid1X = grid1Vo.X
            local grid1Z = grid1Vo.Z
            local zoneLevel = MapHelper:GetZoneLevelByGrid1(grid1X,grid1Z)
            if zoneLevel < 4 or zoneLevel > 5 then
                print("生成土著村落 zoneLevel 不够",zoneLevel,grid1X,grid1Z)
                continue
            end
            local size = MapHelper:GetResPointSize(prefab)
            local sizeX,sizeZ = MapHelper:RandomBuildingSize(size.X,size.Y)
            if not MapHelper:GetIsSafetyBuildingPoint(grid1X,grid1Z,sizeX,sizeZ,MapHelper.GridType.Marsh) then continue end
            local building = MapHelper:CreateBuilding(grid1X,grid1Z,sizeX,sizeZ,GridType.building,prefab)
            MapHelper:initBuilding(building,MapHelper:Grid1ToGrid2(grid1X,grid1Z))
            building.Parent = _parent
            building:AddTag(GameEnum.Tag.WildManHome)
            print("生成土著村落",grid1X,grid1Z)
            break
        end
    end
    folder:Destroy()
end

-- 工坊
function initWineWorkshop()
    local prefab = _specialHouse:FindFirstChild("2x1,私酒工坊LV1")
    local size = MapHelper:GetResPointSize(prefab)
    local sizeX,sizeZ = MapHelper:RandomBuildingSize(size.X,size.Y)
    local grounds:{Part} = CollectionService:GetTagged(GameEnum.Tag.MarshGround)
    for i=1,#grounds do
        local ground = table.remove(grounds,math.random(1,#grounds))
        local grid1Vo = ValueHelper:FindValueValue(ground,GroundValue.grid)
        local grid1X = grid1Vo.X
        local grid1Z = grid1Vo.Z
        local zoneLevel = MapHelper:GetZoneLevelByGrid1(grid1X,grid1Z)
        if zoneLevel ~= 3 then
                -- print("生成私酒工坊失败 zoneLevel ~= 3",zoneLevel,grid1X,grid1Z)
            continue
        end
        if not MapHelper:GetIsSafetyBuildingPoint(grid1X,grid1Z,sizeX,sizeZ,MapHelper.GridType.Marsh) then continue end
        local building = MapHelper:CreateBuilding(grid1X,grid1Z,sizeX,sizeZ,GridType.building,prefab)
        MapHelper:initBuilding(building,MapHelper:Grid1ToGrid2(grid1X,grid1Z))
        building.Parent = _parent
        building:AddTag(GameEnum.Tag.WineWorkshop)
        print("生成私酒工坊",grid1X,grid1Z)
        break
    end
    prefab:Destroy()
end

-- 加特林工坊
function initGatlinWorkshop()
    local prefab = _specialHouse:FindFirstChild("3x3,加特林工坊LV2")
    local size = MapHelper:GetResPointSize(prefab)
    local sizeX,sizeZ = MapHelper:RandomBuildingSize(size.X,size.Y)
    local grounds:{Part} = CollectionService:GetTagged(GameEnum.Tag.MarshGround)
    for i=1,#grounds do
        local ground = table.remove(grounds,math.random(1,#grounds))
        local grid1Vo = ValueHelper:FindValueValue(ground,GroundValue.grid)
        local grid1X = grid1Vo.X
        local grid1Z = grid1Vo.Z
        local zoneLevel = MapHelper:GetZoneLevelByGrid1(grid1X,grid1Z)
        if zoneLevel ~= 4 then
                -- print("生成加特林工坊失败 zoneLevel~= 4",zoneLevel,grid1X,grid1Z)
            continue
        end
        if not MapHelper:GetIsSafetyBuildingPoint(grid1X,grid1Z,sizeX,sizeZ,MapHelper.GridType.Marsh) then continue end
        local building = MapHelper:CreateBuilding(grid1X,grid1Z,sizeX,sizeZ,GridType.building,prefab)
        MapHelper:initBuilding(building,MapHelper:Grid1ToGrid2(grid1X,grid1Z))
        building.Parent = _parent
        building:AddTag(GameEnum.Tag.GatlinWorkshop)
        print("生成加特林工坊",grid1X,grid1Z)
        break
    end
    prefab:Destroy()
end

function init()
    if not MapHelper.isInit then return end
    if _init then return end
    _init = true
    print("初始化沼泽开始")
    initBossEntrance()
    initWildManHome()
    initGatlinWorkshop()
    initWineWorkshop()
    initTreasurePoint()
    initResPoint()
    initHasEnemyResPoint()
    initSenior()
    _specialHouse:Destroy()
    print("初始化沼泽完成")
end

init()
MapHelper.onMapInitComplete.Event:Connect(init)
CommonFunc:GetInstanceTagAddedSignal(GameEnum.Tag.InMud,function(character:Model,connections:{RBXScriptConnection})
    if not character:HasTag(GameEnum.Tag.ImmunityMud) then
	    ValueHelper:SetBonusValueValue(character,CharacterValue.WalkSpeedBonus,"淤泥减速",-8)
    end
end,function(character:Model)
	ValueHelper:SetBonusValueValue(character,CharacterValue.WalkSpeedBonus,"淤泥减速",0)
end)

CommonFunc:GetInstanceTagAddedSignal(GameEnum.Tag.ImmunityMud,function(character:Model,connections:{RBXScriptConnection})
	ValueHelper:SetBonusValueValue(character,CharacterValue.WalkSpeedBonus,"淤泥减速",0)
end,function(character:Model)
    if not character:HasTag(GameEnum.Tag.InMud) then
	    ValueHelper:SetBonusValueValue(character,CharacterValue.WalkSpeedBonus,"淤泥减速",-8)
    end
end)

GameHelper.GroundEnterC2S.OnServerEvent:Connect(function(player,ground:Part)
    while not MapHelper.isInit do
        task.wait()
    end
    -- print("长蘑菇啊")
    if not _enterGroundMarks[ground] then
        _enterGroundMarks[ground] = ground
        trySpawnStoreAndTree(ground)
    end
    -- 蘑菇周期生长
    trySpawnMushroom(ground)
end)

GameHelper.GroundSpawnEnterC2S.OnServerEvent:Connect(function(player,ground:Instance)
    if not GameHelper:ValidateGroundSpawnRequest(player,ground,175) then return end

    trySpawnAnimals(ground)
end)

-- 下雨长出来蘑菇
v_weather.Changed:Connect(function(value)
    if v_weather.Value == GameEnum.WeatherId.Rain then
        _mushroomSpawnMarks = {}
        local r = 2
        for _,player:Player in ipairs(game.Players:GetPlayers()) do
            local character = player.Character
            if not character then continue end

            local centerGrid1X,centerGrid1Z = MapHelper:Pos2Grid1(character:GetPivot().Position)
            for offsetX =-r,r do
                for offsetZ=-r, r do
                    local grid1X = offsetX + centerGrid1X
                    local grid1Z = offsetZ + centerGrid1Z
                    local ground = MapHelper:GetGroundPart(grid1X,grid1Z)
                    if not ground then continue end
                    trySpawnMushroom(ground)
                end
            end
        end
    end
end)

GameHelper.onBuildingSpawnEnemy.Event:Connect(function(building:Model,enemy:Model)
    if not building:HasTag(GameEnum.Tag.GatlinWorkshop) then return end
    local humanoid:Humanoid = enemy:FindFirstChild("Humanoid")
    if humanoid.Health > 0 then
        enemy:AddTag(GameEnum.Tag.GatlinWorkshopEnemy)
        humanoid.Died:Once(function()
            enemy:RemoveTag(GameEnum.Tag.GatlinWorkshopEnemy)
        end)
    end
end)
