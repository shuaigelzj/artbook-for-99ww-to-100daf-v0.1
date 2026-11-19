local CommonFunc = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("framework"):WaitForChild("CommonFunc"))
local GameEnum = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("GameEnum"))
local GameHelper = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("Helpers"):WaitForChild("GameHelper"))
local ValueHelper = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("Helpers"):WaitForChild("ValueHelper"))
local UIHelper = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("Helpers"):WaitForChild("UIHelper"))
local AudioHelper = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("Helpers"):WaitForChild("AudioHelper"))
local MapHelper = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("Helpers"):WaitForChild("MapHelper"))

if not GameHelper.Switch.Train then 
	script.Parent:Destroy()
	return 
end


local TimeValue = ValueHelper.ValueModel.TimeValue

local _controller = GameHelper:GetController()
local v_day:IntValue = ValueHelper:FindValue(_controller,TimeValue.day)

local rootFolder = script.Parent
local trainPrefab = workspace.Prefabs:FindFirstChild("火车大劫案"):FindFirstChild("火车")
local _train:Model = nil
local _battleGround:Model = nil
local v_ResetCD = rootFolder.ResetCD
local LocalOrder = rootFolder.LocalOrder


function spawnTrain()
	if _train then 
		_train:Destroy()
		_train = nil
	end
	if _battleGround then
		_battleGround:Destroy()
		_battleGround = nil
	end
	
	-- 火车出动的音效
	local trainSoundEmitter = trainPrefab and (trainPrefab.PrimaryPart or trainPrefab:FindFirstChildWhichIsA("BasePart", true))
	AudioHelper:PlayEffect("TrainComming", trainSoundEmitter, {SourceKey = "train_departure"})
	
	local train = trainPrefab:Clone()
	train.Parent = rootFolder
	
	while not train:HasTag(GameEnum.Tag.Train) do
		task.wait()
	end

	local v_Motion = train.Motion
	local Head = train:FindFirstChild("车头TakeDamageModel")
	local Door = train:FindFirstChild("车门TakeDamageModel")
	
	v_Motion.Value = true
	Door.HumanoidRootPart.ProximityPrompt.Enabled = false
	spawnBandit()
	
	v_Motion.Changed:Connect(function(value: boolean) 
		if v_Motion.Value then
		else
			task.wait(5)
			if Head.HP.Value > 0 then
				v_Motion.Value = true
			end
		end
	end)

	Head.HP.Changed:Connect(function() 
		if Head.HP.Value > 0 then return end
		-- 火车停下来
		v_Motion.Value = false
		Door:AddTag(GameEnum.Tag.TrainDoor)
	end)
	
	Door.HP.Changed:Connect(function() 
		if Door.HP.Value > 0 then return end
		
		-- 门被破坏
		Door.HumanoidRootPart.ProximityPrompt.Enabled = true
		
		-- 移除旧的副本
		if _battleGround then
			_battleGround:Destroy()
			_battleGround = nil
		end
		-- 创建副本
		_battleGround = workspace:FindFirstChild("Prefabs"):FindFirstChild("火车大劫案"):FindFirstChild("车厢战场"):Clone()
		--local cframe = CFrame.new(Door.HumanoidRootPart.Position - Vector3.new(0,250,0))
		local doorPos = Door.HumanoidRootPart.Position
		local cframe = CFrame.new(doorPos.X,MapHelper.CaveY.Train,doorPos.Z)
		_battleGround:PivotTo(cframe)
		_battleGround.Parent = rootFolder
	end)

	Door.HumanoidRootPart.ProximityPrompt.Triggered:Connect(function(player: Player) 
		if v_ResetCD.Value > 0 and v_ResetCD.Value < 5 then
			-- 最后10秒不让进了
			Door.HumanoidRootPart.ProximityPrompt.Enabled = false
			return
		end
		GameHelper:TeleportToTrainBattleGround(player)
	end)
	_train = train
end

function spawnBandit()
	if not _train then  return end
	
	local bandits:{Model} = game.CollectionService:GetTagged(GameEnum.Tag.TrainBandit)
	if #bandits > 0 then return end

	local atts:{Attachment} = _train:FindFirstChild("匪徒位置"):GetChildren()
	for _,att in ipairs(atts) do

	end
end

function onDayChanged()
	if v_day.Value < 3 then
		v_day.Changed:Once(onDayChanged)
		return
	end

	
	-- 第三天，火车才出动
	UIHelper.onPopCenterTips:FireAllClients("🚂The train is about to depart—find them in the wilderness!",UIHelper.TipsStyle.Event)
	-- 播放CG
	task.delay(3,function()
		local event = game.ReplicatedStorage:WaitForChild('Events'):WaitForChild('PlayCam'):WaitForChild('TrainStartEvent')
		event:FireAllClients()
		
		task.wait(5)
		spawnTrain()
	end)
	
end

onDayChanged()


while true do
	local dt = task.wait(1)
	if v_ResetCD.Value > 0 then 
		v_ResetCD.Value -= 1
		if v_ResetCD.Value <= 0 then
			v_ResetCD.Value = 0

			-- 把在副本里的玩家传送出来先
			--print("TODO 把在副本里的玩家传送出来")
			for _,player:Player in ipairs(game.Players:GetPlayers()) do
				if player.Character and player.Character:HasTag(GameEnum.Tag.OnTrainBattleGround) then
					GameHelper:TeleportToTrain(player)
				end
			end
			
			task.wait(0.5)
			spawnTrain()
		end	
	end
end
