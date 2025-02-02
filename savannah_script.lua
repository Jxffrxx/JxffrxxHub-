-- Verify key and authentication
if not getgenv().JxffrxxHubAuthorized or not getgenv().UserKey then
    game.Players.LocalPlayer:Kick("Authentication required - please run the authentication script first")
    return
end

-- Verify key with server
local function verifyKey()
    local success, response = pcall(function()
        local requestFunc = syn and syn.request or http_request or request
        return requestFunc({
            Url = "https://hehehehe-jfoglesongjr.replit.app/v1/api/authenticate",
            Method = "GET",
            Headers = {
                ["Authorization"] = getgenv().UserKey,
                ["syn-fingerprint"] = getexecutorname() or getruntimeid() or getexecutorversion() or "Unknown"
            }
        })
    end)

    if not success or response.StatusCode ~= 200 then
        game.Players.LocalPlayer:Kick("Key verification failed")
        return false
    end
    
    return true
end

if not verifyKey() then return end

if game.PlaceId ~= 18214855317 then
    game.Players.LocalPlayer:Kick("This script is only for Savannah Life")
    return
end

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "🔥 Jxffrxx Hub | Savannah Life",
   LoadingTitle = "Loading Jxffrxx Hub",
   LoadingSubtitle = "Custom Features for Savannah Life",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "JxffrxxHub",
      FileName = "SavannahLifeConfig"
   },
   Discord = {
      Enabled = false,
      Invite = "noinvitelink",
      RememberJoins = true
   },
   KeySystem = true,
   KeySettings = {
      Title = "Jxffrxx Hub Key System",
      Subtitle = "Enter Key to Access",
      Note = "The Key is Jxffxey",
      FileName = "JxffxeyHubKey",
      SaveKey = true,
      GrabKeyFromSite = false,
      Key = {"Jxffxey"}
   }
})

-- Tabs
local MainTab = Window:CreateTab("🏠 Main Features", nil)
local MiscTab = Window:CreateTab("⚙️ Misc", nil)
local PVP_Tab = Window:CreateTab("⚔️ PVP Features", nil)

-- Services
local players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local runService = game:GetService("RunService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local userInputService = game:GetService("UserInputService")

local player = players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Variables
local infiniteStatsEnabled = false
local afkPlatform = nil
local originalPosition = nil
local attackHitboxSizeMultiplier = 1
local hitboxVisualizerEnabled = false
local autoAimEnabled = false
local isClicking = false
local impalaHitboxVisualizerEnabled = false
local impalaHitboxSizeMultiplier = 1
local instaKillEnabled = false
-- Speed and Acceleration Control Variables
local speedToggle = false
local accelerationToggle = false
local customSpeed = 16 -- Default WalkSpeed
local customAcceleration = 35 -- Default Acceleration


local function enableInfiniteStats()
   infiniteStatsEnabled = true
   runService.Heartbeat:Connect(function()
      if infiniteStatsEnabled and character then
         character:SetAttribute("Food", 100)
         character:SetAttribute("Water", 100)
         character:SetAttribute("Oxygen", 100)
         character:SetAttribute("Stamina", 100)
      end
   end)
end

local function disableInfiniteStats()
   infiniteStatsEnabled = false
end
local function createAFKPlatform()
   if afkPlatform then
      Rayfield:Notify({
         Title = "AFK Platform",
         Content = "AFK Platform already exists!",
         Duration = 5
      })
      return
   end

   afkPlatform = Instance.new("Part", workspace)
   afkPlatform.Size = Vector3.new(50, 1, 50)
   afkPlatform.Position = Vector3.new(0, 1000, 0)
   afkPlatform.Anchored = true
   afkPlatform.Color = Color3.fromRGB(102, 255, 102)
   afkPlatform.Name = "AFKFarmPlatform"

   if character and character:FindFirstChild("HumanoidRootPart") then
      originalPosition = character.HumanoidRootPart.Position

      task.wait(0.1)
      character:MoveTo(afkPlatform.Position + Vector3.new(0, 5, 0))
      Rayfield:Notify({
         Title = "AFK Platform",
         Content = "AFK Farm Platform created and player teleported!",
         Duration = 5
      })
   else
      Rayfield:Notify({
         Title = "AFK Platform",
         Content = "HumanoidRootPart not found! Teleportation failed.",
         Duration = 5
      })
   end
end

local function removeAFKPlatform()
   if afkPlatform then
      afkPlatform:Destroy()
      afkPlatform = nil

      if originalPosition and character and character:FindFirstChild("HumanoidRootPart") then
         character:MoveTo(originalPosition)
         originalPosition = nil
         Rayfield:Notify({
            Title = "AFK Platform",
            Content = "AFK Farm Platform removed! Teleported back to your original position.",
            Duration = 5
         })
      else
         Rayfield:Notify({
            Title = "AFK Platform",
            Content = "AFK Farm Platform removed, but could not teleport back. Original position not found.",
            Duration = 5
         })
      end
   else
      Rayfield:Notify({
         Title = "AFK Platform",
         Content = "No AFK Farm Platform to remove!",
         Duration = 5
      })
   end
end
local function toggleHitboxVisualizer(state)
   local ragdollParts = character:FindFirstChild("RagdollColliderParts")
   if ragdollParts then
      for _, part in ipairs(ragdollParts:GetChildren()) do
         if part:IsA("BasePart") then
            part.Transparency = state and 0.5 or 1
            part.BrickColor = state and BrickColor.new("Bright red") or BrickColor.new("Medium stone grey")
            part.Material = state and Enum.Material.Neon or Enum.Material.Plastic
         end
      end
   end
end
local function performInstaKill(targetHumanoid)
   if not targetHumanoid or not instaKillEnabled then return end

   local remote = replicatedStorage:WaitForChild("AttackHandlerRemoteEvent")
   while isClicking and instaKillEnabled do
      remote:FireServer(targetHumanoid)
      task.wait(0.05) -- Cooldown between each attack
   end
end

local function onPlayerAttack()
   if not instaKillEnabled then return end

   local closestTarget = nil
   local shortestDistance = math.huge

   for _, otherPlayer in ipairs(players:GetPlayers()) do
      if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("Humanoid") then
         local targetHumanoid = otherPlayer.Character.Humanoid
         local targetPart = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
         local distance = (character.HumanoidRootPart.Position - targetPart.Position).Magnitude

         if distance < shortestDistance then
            shortestDistance = distance
            closestTarget = targetHumanoid
         end
      end
   end

   if closestTarget then
      performInstaKill(closestTarget)
   end
end


userInputService.InputBegan:Connect(function(input, gameProcessed)
   if gameProcessed then return end
   if input.UserInputType == Enum.UserInputType.MouseButton1 then
      isClicking = true
      onPlayerAttack()
   end
end)

userInputService.InputEnded:Connect(function(input, gameProcessed)
   if input.UserInputType == Enum.UserInputType.MouseButton1 then
      isClicking = false
   end
end)

local function enableNoFallDamage()
    noFallDamageEnabled = true

    local oldFallDamageHandler = nil
    local playerDamageEvent = replicatedStorage:WaitForChild("PlayerDamageSelfRemoteEvent")

    -- Hook the Fall Damage RemoteEvent using a proper connection
    oldFallDamageHandler = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod()
        local args = { ... }

        -- Only target the fall damage event and block it if enabled
        if noFallDamageEnabled and self == playerDamageEvent and method == "FireServer" then
            return
        end

        -- Call the original function if not blocking
        return oldFallDamageHandler(self, ...)
    end)

    Rayfield:Notify({
        Title = "No Fall Damage Enabled",
        Content = "Fall damage has been successfully disabled!",
        Duration = 5,
    })
end

local function disableNoFallDamage()
    noFallDamageEnabled = false

    Rayfield:Notify({
        Title = "No Fall Damage Disabled",
        Content = "Fall damage has been re-enabled.",
        Duration = 5,
    })
end


local function toggleImpalaHitboxVisualizer(state)
   local attackPartFolder = workspace:FindFirstChild(player.Name) and workspace[player.Name]:FindFirstChild("AttackPartCollidersFolder")
   if attackPartFolder then
      local attackPart = attackPartFolder:FindFirstChild("ClientSideAttackPartHitBoxFor: Head")
      if attackPart then
         attackPart.Transparency = state and 0.5 or 1
         attackPart.BrickColor = state and BrickColor.new("Bright red") or BrickColor.new("Medium stone grey")
         attackPart.Material = state and Enum.Material.Neon or Enum.Material.Plastic
      end
   end
end

local function adjustImpalaHitboxSize(multiplier)
   local attackPartFolder = workspace:FindFirstChild(player.Name) and workspace[player.Name]:FindFirstChild("AttackPartCollidersFolder")
   if attackPartFolder then
      local attackPart = attackPartFolder:FindFirstChild("ClientSideAttackPartHitBoxFor: Head")
      if attackPart then
         attackPart.Size = Vector3.new(2, 2, 2) * multiplier
      end
   end
end
local function enableAutoAim()
   local function getClosestTarget()
      local closestTarget = nil
      local shortestDistance = math.huge

      for _, otherPlayer in ipairs(players:GetPlayers()) do
         if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild("HumanoidRootPart") and otherPlayer.Character:FindFirstChild("Humanoid") and otherPlayer.Character.Humanoid.Health > 0 then
            local targetPart = otherPlayer.Character.HumanoidRootPart
            local distance = (player.Character.HumanoidRootPart.Position - targetPart.Position).Magnitude
            if distance < shortestDistance then
               shortestDistance = distance
               closestTarget = targetPart
            end
         end
      end

      return closestTarget
   end

   runService.RenderStepped:Connect(function()
      if not autoAimEnabled or not isClicking or not character or not character:FindFirstChild("HumanoidRootPart") then return end

      local closestTarget = getClosestTarget()
      if closestTarget then
         local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
         if humanoidRootPart then
            -- Set the player's orientation to face the target
            local targetPosition = Vector3.new(closestTarget.Position.X, humanoidRootPart.Position.Y, closestTarget.Position.Z)
            humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position, targetPosition)
         end
      end
   end)
end

local function updateSpeedAndAcceleration()
    local animalMovementHandler = player.PlayerScripts:FindFirstChild("AnimalGameFramework") and player.PlayerScripts.AnimalGameFramework:FindFirstChild("AnimalMovementHandler")

    if not animalMovementHandler then
        Rayfield:Notify({
            Title = "Error",
            Content = "Failed to find AnimalMovementHandler script.",
            Duration = 5
        })
        return
    end

    local movementHandler = require(animalMovementHandler)

    -- Ensure character exists
    if not character or not character:FindFirstChild("Humanoid") or not character:FindFirstChild("HumanoidRootPart") then
        return
    end

    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")

    -- Handle Speed Toggle
    if speedToggle then
        local moveVector = humanoid.MoveDirection -- Movement direction from input (W, A, S, D)

        if moveVector.Magnitude > 0 then
            -- Player is moving: Accelerate toward target speed
            humanoid.WalkSpeed = math.min(humanoid.WalkSpeed + customAcceleration * task.wait(), customSpeed)
        else
            -- Player is not moving: Decelerate back to 0 (or a minimum value, like 16 for default speed)
            humanoid.WalkSpeed = math.max(humanoid.WalkSpeed - customAcceleration * task.wait(), 0)
        end
    else
        humanoid.WalkSpeed = 16 -- Default Roblox speed if toggle is off
    end

    -- Apply acceleration/deceleration attributes if the toggle is enabled
    if accelerationToggle then
        character:SetAttribute("Acceleration", customAcceleration)
        character:SetAttribute("Deceleration", customAcceleration) -- Same slider value for both acceleration and deceleration
    end
end

runService.Stepped:Connect(function()
   if speedToggle or accelerationToggle then
      updateSpeedAndAcceleration()
   end
end)



userInputService.InputBegan:Connect(function(input, gameProcessed)
   if gameProcessed then return end
   if input.UserInputType == Enum.UserInputType.MouseButton1 then
      isClicking = true
   end
end)

userInputService.InputEnded:Connect(function(input, gameProcessed)
   if input.UserInputType == Enum.UserInputType.MouseButton1 then
      isClicking = false
   end
end)

local function disableAutoAim()
   autoAimEnabled = false
end
MainTab:CreateToggle({
   Name = "Enable Infinite Stats",
   CurrentValue = false,
   Flag = "InfiniteStatsToggle",
   Callback = function(Value)
      if Value then
         enableInfiniteStats()
      else
         disableInfiniteStats()
      end
   end
})

MainTab:CreateToggle({
   Name = "No Fall Damage",
   CurrentValue = false,
   Flag = "NoFallDamageToggle",
   Callback = function(Value)
      if Value then
         enableNoFallDamage()
      else
         disableNoFallDamage()
      end
   end
})

MainTab:CreateButton({
   Name = "Create AFK Farm Platform",
   Callback = function()
      createAFKPlatform()
   end
})

MainTab:CreateButton({
   Name = "Remove AFK Farm Platform",
   Callback = function()
      removeAFKPlatform()
   end
})
PVP_Tab:CreateToggle({
   Name = "Enable Insta-Kill",
   CurrentValue = false,
   Flag = "InstaKillToggle",
   Callback = function(Value)
      instaKillEnabled = Value
      Rayfield:Notify({
         Title = "Insta-Kill Toggled",
         Content = Value and "Insta-Kill enabled! Attack players to spam damage." or "Insta-Kill disabled.",
         Duration = 5
      })
   end
})

PVP_Tab:CreateToggle({
   Name = "Enable Hitbox Visualizer",
   CurrentValue = false,
   Flag = "HitboxVisualizerToggle",
   Callback = function(Value)
      hitboxVisualizerEnabled = Value
      toggleHitboxVisualizer(Value)
   end
})

PVP_Tab:CreateSlider({
   Name = "Attack Part Hitbox Size Multiplier",
   Range = {1, 10},
   Increment = 1,
   Suffix = "x",
   CurrentValue = 1,
   Flag = "AttackHitboxMultiplier",
   Callback = function(Value)
      attackHitboxSizeMultiplier = Value
      adjustAttackHitboxSize(Value)
   end
})

PVP_Tab:CreateToggle({
   Name = "Impala Hitbox Visualizer",
   CurrentValue = false,
   Flag = "ImpalaHitboxVisualizerToggle",
   Callback = function(Value)
      impalaHitboxVisualizerEnabled = Value
      toggleImpalaHitboxVisualizer(Value)
   end
})

PVP_Tab:CreateSlider({
   Name = "Impala Attack Hitbox Size Multiplier",
   Range = {1, 10},
   Increment = 1,
   Suffix = "x",
   CurrentValue = 1,
   Flag = "ImpalaHitboxMultiplier",
   Callback = function(Value)
      impalaHitboxSizeMultiplier = Value
      adjustImpalaHitboxSize(Value)
   end
})

-- Speed Toggle
MiscTab:CreateToggle({
   Name = "Enable Custom Speed",
   CurrentValue = false,
   Flag = "CustomSpeedToggle",
   Callback = function(Value)
      speedToggle = Value
      Rayfield:Notify({
         Title = "Custom Speed",
         Content = Value and "Custom Speed Enabled" or "Custom Speed Disabled",
         Duration = 5
      })
   end
})

-- Speed Slider
MiscTab:CreateSlider({
   Name = "Custom Speed",
   Range = {16, 10000}, -- Adjust the range as needed
   Increment = 1,
   Suffix = "WalkSpeed",
   CurrentValue = 16,
   Flag = "SpeedSlider",
   Callback = function(Value)
      customSpeed = Value
      if speedToggle then
         updateSpeedAndAcceleration()
      end
   end
})

-- Acceleration Toggle
MiscTab:CreateToggle({
   Name = "Enable Custom Acceleration",
   CurrentValue = false,
   Flag = "CustomAccelerationToggle",
   Callback = function(Value)
      accelerationToggle = Value
      Rayfield:Notify({
         Title = "Custom Acceleration",
         Content = Value and "Custom Acceleration Enabled" or "Custom Acceleration Disabled",
         Duration = 5
      })
   end
})

-- Acceleration Slider
MiscTab:CreateSlider({
   Name = "Custom Acceleration",
   Range = {10, 10000}, -- Adjust the range as needed
   Increment = 1,
   Suffix = "Units",
   CurrentValue = 35,
   Flag = "AccelerationSlider",
   Callback = function(Value)
      customAcceleration = Value
      if accelerationToggle then
         updateSpeedAndAcceleration()
      end
   end
})




PVP_Tab:CreateToggle({
   Name = "Enable Auto-Aim",
   CurrentValue = false,
   Flag = "AutoAimToggle",
   Callback = function(Value)
      autoAimEnabled = Value
      if Value then
         Rayfield:Notify({
            Title = "Auto Aim Enabled",
            Content = "Automatically targeting the closest player while clicking!",
            Duration = 5
         })
         enableAutoAim()
      else
         disableAutoAim()
         Rayfield:Notify({
            Title = "Auto Aim Disabled",
            Content = "Stopped targeting players automatically.",
            Duration = 5
         })
      end
   end
})

player.CharacterAdded:Connect(function(newCharacter)
   character = newCharacter

   if infiniteStatsEnabled then
      enableInfiniteStats()
   end

   if hitboxVisualizerEnabled then
      toggleHitboxVisualizer(true)
   end

   if impalaHitboxVisualizerEnabled then
      toggleImpalaHitboxVisualizer(true)
   end

    if speedToggle or accelerationToggle then
      updateSpeedAndAcceleration()
    end

end)

Rayfield:LoadConfiguration()