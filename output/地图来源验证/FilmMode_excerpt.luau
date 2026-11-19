script.Parent.Enabled = false
--获取服务
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local DataStoreService = game:GetService("DataStoreService")
local UserService = game:GetService("UserService")
local SocialService = game:GetService("SocialService")
local MarketplaceService = game:GetService("MarketplaceService")
local mouse = game.Players.LocalPlayer:GetMouse()

local ConfigHelper = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("framework"):WaitForChild("ConfigHelper"))
local MapHelper = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("Helpers"):WaitForChild("MapHelper"))
local ValueHelper = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("Helpers"):WaitForChild("ValueHelper"))
local GameHelper = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("Helpers"):WaitForChild("GameHelper"))
local UIHelper = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("Helpers"):WaitForChild("UIHelper"))
local AudioHelper = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("Helpers"):WaitForChild("AudioHelper"))
local CommonFunc = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("framework"):WaitForChild("CommonFunc"))
local CommonEnum = require(game.ReplicatedStorage:WaitForChild("src"):WaitForChild("Common"):WaitForChild("CommonEnum"))

local TimeValue = ValueHelper.ValueModel.TimeValue
local gameController = GameHelper:GetController()
local v_isDaytime:BoolValue = ValueHelper:FindValue(gameController,TimeValue.isDaytime)
local v_day:IntValue = ValueHelper:FindValue(gameController,TimeValue.day)

local DebrisService = game:GetService('Debris')
--客户端获取玩家
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local tweenInfo = TweenInfo.new(
	2, -- Time
	Enum.EasingStyle.Linear, -- EasingStyle
	Enum.EasingDirection.Out, -- EasingDirection
	0, -- RepeatCount (小于零时 tween 会无限循环)
	false, -- Reverses (tween 完成目标后会反转)
	0 -- DelayTime
)
local tweenInfoFast = TweenInfo.new(
	1, -- Time
	Enum.EasingStyle.Linear, -- EasingStyle
	Enum.EasingDirection.Out, -- EasingDirection
	0, -- RepeatCount (小于零时 tween 会无限循环)
	false, -- Reverses (tween 完成目标后会反转)
	0 -- DelayTime
)
local point = workspace:WaitForChild('CamSetting').PrimaryPart.CFrame

local tweenInfo2 = TweenInfo.new(1,Enum.EasingStyle.Quint,Enum.EasingDirection.Out,0,false,0)
local tweenInfo3 = TweenInfo.new(0.1,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,20,true,0)

local UIResBar = player:WaitForChild("PlayerGui"):WaitForChild("UIResBar")
local UIInterface= player:WaitForChild("PlayerGui"):WaitForChild("UIInterface")
local UIBagpack= player:WaitForChild("PlayerGui"):WaitForChild("UIBagpack")

local ui = script.Parent:WaitForChild('mubu')
local dark = TweenService:Create(ui, tweenInfoFast, {BackgroundTransparency=0})
local blight = TweenService:Create(ui, tweenInfo, {BackgroundTransparency=1})

local up = script.Parent:WaitForChild("FrameUp")
local down = script.Parent:WaitForChild('FrameDown')

local FirstCowBoyCamera = workspace:WaitForChild('CamSetting'):WaitForChild('FirstCowBoyCamera')
local CowBoyAttackCamera = workspace:WaitForChild('CamSetting'):WaitForChild('CowBoyAttackCamera')
local SheepCam = workspace:WaitForChild('CamSetting'):WaitForChild('SheepCam')
local Cams99 = workspace:WaitForChild('CamSetting'):WaitForChild('Cams99')
local trainCam = workspace:WaitForChild('CamSetting'):WaitForChild('trainCam')
local christmasCam = workspace:WaitForChild('CamSetting'):WaitForChild('christmasCam')
local moonCam = workspace:WaitForChild('CamSetting'):WaitForChild('MoonCam')

local christmasCar = workspace:WaitForChild('CamSetting'):WaitForChild('christmasCar')
local christmasCarStartPoint = workspace:WaitForChild('CamSetting'):WaitForChild('christmasCarStartPoint')
local christmasCarDropPoint = workspace:WaitForChild('CamSetting'):WaitForChild('christmasCarDropPoint')

local isSkip = false
local oldCowboyFilmEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("PlayCam"):WaitForChild("OldCowboyCemeteryEvent")
local oldCowboyFilmFinishedEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("PlayCam"):WaitForChild("OldCowboyCemeteryFinishedEvent")
local oldCowboyFilmActive = false
local oldCowboyFilmSerial = 0

local function restoreOldCowboyView()
	workspace:WaitForChild("CamSetting"):PivotTo(point)
	local currentCharacter = player.Character
	local currentHumanoid = currentCharacter and currentCharacter:FindFirstChildWhichIsA("Humanoid")
	workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
	if currentHumanoid then
		workspace.CurrentCamera.CameraSubject = currentHumanoid
	end
	UIResBar.Enabled = true
	UIInterface.Enabled = true
	UIBagpack.Enabled = true
	script.Parent.Enabled = false
	script.Parent:WaitForChild("Language").Text = ""
	up.BackgroundTransparency = 1
	down.BackgroundTransparency = 1
end
