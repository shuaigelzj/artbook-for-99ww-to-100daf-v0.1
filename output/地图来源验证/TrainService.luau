local ValueHelper = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("Helpers"):WaitForChild("ValueHelper"))
local GameHelper = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("Helpers"):WaitForChild("GameHelper"))
local MapHelper = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("Helpers"):WaitForChild("MapHelper"))

if not GameHelper.Switch.Train then return end

local GroundValue = ValueHelper.ValueModel.GroundValue

local _enterGroundMarks:{Part} = {}
local _storePrefabNames = {"灌木丛1","灌木丛2","草1","草2","草1","草2","草1","草2"}

math.randomseed(tick())
function spawnStore(ground:Part)
    if not ground then return end
    local folder = workspace:FindFirstChild("Prefabs"):FindFirstChild("Map"):FindFirstChild("石头")
    local prefab:Model = folder:FindFirstChild(_storePrefabNames[math.random(1,#_storePrefabNames)])
    if prefab then
        local posX = ground.Position.X
        local posZ = ground.Position.Z
        local groundY = ground.Position.Y + ground.Size.Y / 2
        local stoneX = math.random(posX-MapHelper.halfGridSize_1,posX + MapHelper.halfGridSize_1)
        local stoneZ = math.random(posZ-MapHelper.halfGridSize_1,posZ + MapHelper.halfGridSize_1)
        local rotationY = math.random(0,3) * 90
        local stone = prefab:Clone()
        stone:PivotTo(CFrame.Angles(0,math.rad(rotationY),0)+Vector3.new(stoneX,groundY,stoneZ))
        stone.Parent = workspace
    end
end

-- 随机石头
function trySpawnStoreAndTree(ground:Part)
    local gridPoint:Vector3 = ValueHelper:FindValueValue(ground,GroundValue.grid)
    local gridType = MapHelper:GetMapGridType(gridPoint.X,gridPoint.Z)
    if gridType == MapHelper.GridType.Railway then
        -- 随机石块
        local num = math.random(1,3)
        for i=1,num do
            spawnStore(ground)
        end
    end
end

GameHelper.GroundEnterC2S.OnServerEvent:Connect(function(player,ground:Part)
    while not MapHelper.isInit do
        task.wait()
    end

    if not _enterGroundMarks[ground] then
        _enterGroundMarks[ground] = ground
        trySpawnStoreAndTree(ground)
    end
end)
