local playerList = Instance.new("ScrollingFrame")
local UIListLayout = Instance.new("UIListLayout")
local screenGui = Instance.new("ScreenGui")

local lp = game.Players.LocalPlayer
local run = game:GetService("RunService")

screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = lp.PlayerGui

playerList.Name = "playerList"
playerList.Parent = screenGui
playerList.Active = true
playerList.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
playerList.BackgroundTransparency = 0.450
playerList.BorderColor3 = Color3.fromRGB(0, 0, 0)
playerList.BorderSizePixel = 0
playerList.Position = UDim2.new(0.75, 0, 0.2, 0)
playerList.Size = UDim2.new(0.2, 0, 0.4, 0)
playerList.CanvasSize = UDim2.new(0, 0, 0, 0)
playerList.ScrollBarThickness = 5

UIListLayout.Parent = playerList
local buttons = {}
local instances = {}
local state = false
local baseGravity = workspace.Gravity
local humanoid = lp.Character and lp.Character:FindFirstChild("Humanoid")
local baseSpeed = humanoid and humanoid.WalkSpeed or 16
local baseJPower = humanoid and humanoid.JumpPower or 50
local connFunc

--[[
	соединяем игрока с игроком (как воздушный шарик)
]]--
local function connectToPlayer(plr)
	if not state then
		local char = lp.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if not hrp then return end
		
		local rope = Instance.new("RopeConstraint")
		rope.Parent = hrp
		rope.Length = 7
		rope.Visible = true
		table.insert(instances, rope)
		
		local a0 = Instance.new("Attachment")
		a0.Parent = hrp
		table.insert(instances, a0)
		
		local ball = Instance.new("Part")
		ball.Shape = Enum.PartType.Ball
		ball.Size = Vector3.new(6, 6, 6)
		ball.Transparency = 0.5
		ball.BrickColor = BrickColor.new("Baby blue")
		ball.Parent = char
		ball.CFrame = hrp.CFrame
		for _, surftype in {"Top", "Back", "Left", "Right", "Front", "Bottom"} do
			ball[surftype.."Surface"] = Enum.SurfaceType.Smooth
		end
		table.insert(instances, ball)
		
		local lead = Instance.new("Part")
		lead.Size = Vector3.new(0.4, 0.4, 0.4)
		lead.CanCollide = false
		lead.Anchored = true
		lead.Transparency = 0.5
		lead.Parent = workspace
		table.insert(instances, lead)
		
		local weld = Instance.new("Weld")
		weld.Parent = hrp
		weld.Part0, weld.Part1 = hrp, ball
		table.insert(instances, weld)
		
		local player = game.Players:FindFirstChild(plr.Name)
		if player then
			if player.Character.Humanoid.RigType == Enum.HumanoidRigType.R15 then
				local a1 = Instance.new("Attachment")
				a1.Parent = lead
				rope.Attachment0, rope.Attachment1 = a0, a1
				table.insert(instances, a1)
				connFunc = run.Heartbeat:Connect(function()
					local hand = player.Character:FindFirstChild("RightHand")
					if hand then lead.CFrame = hand.CFrame end
				end)
			else
				local a1 = Instance.new("Attachment")
				a1.Parent = lead
				rope.Attachment0, rope.Attachment1 = a0, a1
				table.insert(instances, a1)
				connFunc = run.Heartbeat:Connect(function()
					local hand = player.Character:FindFirstChild("Right Arm")
					if hand then lead.CFrame = hand.CFrame end
				end)
			end
			
			char.Humanoid.Sit = true
			char.Humanoid.WalkSpeed = 0
			char.Humanoid.JumpPower = 0
			local force = Instance.new("BodyForce")
			force.Parent = hrp
			force.Force = Vector3.new(0, hrp.Mass * workspace.Gravity * 5, 0)
			workspace.Gravity = 0
			table.insert(instances, force)
		end
		state = true
	end
end

local function disconn()
	if state then
		for _, i in instances do
			i:Destroy()
		end
		table.clear(instances)
		state = false
		if lp.Character then lp.Character.Humanoid.Sit = false end
		if lp.Character then lp.Character.Humanoid.WalkSpeed = baseSpeed end
		if lp.Character then lp.Character.Humanoid.JumpPower = baseJPower end
		workspace.Gravity = baseGravity
		connFunc:Disconnect()
	end
end)

--[[
	первоначальный цикл, собирает игроков в фрейм 
	дальше будем отлавливать по входу/выходу, чтобы не удалять/добавлять кнопки заного
	ибо смысла нет
]]--
local function reload()
	table.clear(buttons)
	for _, b in playerList:GetChildren() do
		if b:IsA("TextButton") then
			b:Destroy()
		end
	end
	playerList.CanvasSize = UDim2.new(0, 0, 0, 0)
	
	local players = game.Players:GetPlayers()
	for _, i in players do
		local playerButton = Instance.new("TextButton")
		playerButton.Name, playerButton.Text = i.Name, i.Name
		playerButton.Size =  UDim2.new(1, 0, 0, 40)
		playerButton.Parent = playerList
		table.insert(buttons, i.Name)
		
		playerButton.MouseButton1Click:Connect(function()
			connectToPlayer(i)
		end)
	end
	
	playerList.CanvasSize = UDim2.new(0, 0, 0, #players * 40)
end

reload()

--[[
	отлов игроков по входу/выходу
]]--
game.Players.PlayerAdded:Connect(function(i)
	local playerButton = Instance.new("TextButton")
	playerButton.Name, playerButton.Text = i.Name, i.Name
	playerButton.Size =  UDim2.new(1, 0, 0, 40)
	playerButton.Parent = playerList
	table.insert(buttons, i.Name)

	playerList.CanvasSize = UDim2.new(0, 0, 0, #buttons * 40)

	playerButton.MouseButton1Click:Connect(function()
		connectToPlayer(i)
	end)
end)

game.Players.PlayerRemoving:Connect(function(i)
	for idx, b in buttons do
		if i.Name == b then
			table.remove(buttons, idx)
			break
		end
	end
	
	local left = playerList:FindFirstChild(i.Name)
	if left then left:Destroy() end
	
	playerList.CanvasSize = UDim2.new(0, 0, 0, #buttons * 40)
end)

--[[
	кнопка дисконнекта
]]
local discButton = Instance.new("TextButton")
discButton.Name, discButton.Text = 'disc', 'disconnect'
discButton.Size =  UDim2.new(0.2, 0, 0, 40)
discButton.Parent = screenGui
discButton.Position = UDim2.new(0.75, 0, 0.61, 0)
discButton.MouseButton1Click:Connect(disconn)

--[[
	если игрок умер
]]
lp.Character.Humanoid.Died:Connect(disconn)

--[[
	кнопка перепросчета игроков
]]
local reloadButton = Instance.new("TextButton")
reloadButton.Name, reloadButton.Text = 'reload', 'reload players'
reloadButton.Size =  UDim2.new(0.2, 0, 0, 40)
reloadButton.Parent = screenGui
reloadButton.Position = UDim2.new(0.75, 0, 0.68, 0)
reloadButton.MouseButton1Click:Connect(reload)
-- строка #200
