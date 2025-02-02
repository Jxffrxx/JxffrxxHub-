local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local HttpService = game:GetService("HttpService")

local CustomLib = {
	Elements = {},
	ThemeObjects = {},
	Connections = {},
	Flags = {},
	Themes = {
		Default = {
			Main = Color3.fromRGB(25, 25, 25),
			Second = Color3.fromRGB(32, 32, 32),
			Stroke = Color3.fromRGB(60, 60, 60),
			Divider = Color3.fromRGB(60, 60, 60),
			Text = Color3.fromRGB(240, 240, 240),
			TextDark = Color3.fromRGB(150, 150, 150),
		},
	},
	SelectedTheme = "Default",
	Folder = nil,
	SaveCfg = false,
}

-- Feather Icons (from lucideblox GitHub)
local Icons = {}
local Success, Response = pcall(function()
	Icons = HttpService:JSONDecode(game:HttpGetAsync("https://raw.githubusercontent.com/evoincorp/lucideblox/master/src/modules/util/icons.json")).icons
end)

if not Success then
	warn("Custom Library - Failed to load Feather Icons. Error code: " .. Response)
end	

local function GetIcon(IconName)
	return Icons[IconName] or nil
end   

local UI = Instance.new("ScreenGui")
UI.Name = "CustomUI"
if syn then
	syn.protect_gui(UI)
	UI.Parent = game.CoreGui
else
	UI.Parent = gethui() or game.CoreGui
end

if gethui then
	for _, Interface in ipairs(gethui():GetChildren()) do
		if Interface.Name == UI.Name and Interface ~= UI then
			Interface:Destroy()
		end
	end
else
	for _, Interface in ipairs(game.CoreGui:GetChildren()) do
		if Interface.Name == UI.Name and Interface ~= UI then
			Interface:Destroy()
		end
	end
end

function CustomLib:IsRunning()
	return UI.Parent == (gethui and gethui() or game.CoreGui)
end

local function AddConnection(Signal, Function)
	if not CustomLib:IsRunning() then return end
	local SignalConnect = Signal:Connect(Function)
	table.insert(CustomLib.Connections, SignalConnect)
	return SignalConnect
end

task.spawn(function()
	while CustomLib:IsRunning() do
		task.wait()
	end
	for _, Connection in next, CustomLib.Connections do
		Connection:Disconnect()
	end
end)

local function MakeDraggable(DragPoint, Main)
	pcall(function()
		local Dragging, DragInput, MousePos, FramePos = false
		AddConnection(DragPoint.InputBegan, function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
				Dragging = true
				MousePos = Input.Position
				FramePos = Main.Position

				Input.Changed:Connect(function()
					if Input.UserInputState == Enum.UserInputState.End then
						Dragging = false
					end
				end)
			end
		end)
		AddConnection(DragPoint.InputChanged, function(Input)
			if Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch then
				DragInput = Input
			end
		end)
		AddConnection(UserInputService.InputChanged, function(Input)
			if Input == DragInput and Dragging then
				local Delta = Input.Position - MousePos
				TweenService:Create(Main, TweenInfo.new(0.05, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Position = UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)}):Play()
				Main.Position = UDim2.new(FramePos.X.Scale, FramePos.X.Offset + Delta.X, FramePos.Y.Scale, FramePos.Y.Offset + Delta.Y)
			end
		end)
	end)
end    

local function Create(Name, Properties, Children)
	local Object = Instance.new(Name)
	for i, v in next, Properties or {} do
		Object[i] = v
	end
	for i, v in next, Children or {} do
		v.Parent = Object
	end
	return Object
end

local function CreateElement(ElementName, ElementFunction)
	CustomLib.Elements[ElementName] = function(...)
		return ElementFunction(...)
	end
end

local function MakeElement(ElementName, ...)
	local NewElement = CustomLib.Elements[ElementName](...)
	return NewElement
end

local function SetProps(Element, Props)
	table.foreach(Props, function(Property, Value)
		Element[Property] = Value
	end)
	return Element
end

local function SetChildren(Element, Children)
	table.foreach(Children, function(_, Child)
		Child.Parent = Element
	end)
	return Element
end

local function Round(Number, Factor)
	local Result = math.floor(Number / Factor + (math.sign(Number) * 0.5)) * Factor
	if Result < 0 then Result = Result + Factor end
	return Result
end

local function ReturnProperty(Object)
	if Object:IsA("Frame") or Object:IsA("TextButton") then
		return "BackgroundColor3"
	end 
	if Object:IsA("ScrollingFrame") then
		return "ScrollBarImageColor3"
	end 
	if Object:IsA("UIStroke") then
		return "Color"
	end 
	if Object:IsA("TextLabel") or Object:IsA("TextBox") then
		return "TextColor3"
	end   
	if Object:IsA("ImageLabel") or Object:IsA("ImageButton") then
		return "ImageColor3"
	end   
end

local function AddThemeObject(Object, Type)
	CustomLib.ThemeObjects[Type] = CustomLib.ThemeObjects[Type] or {}
	table.insert(CustomLib.ThemeObjects[Type], Object)
	Object[ReturnProperty(Object)] = CustomLib.Themes[CustomLib.SelectedTheme][Type]
	return Object
end    

local function SetTheme()
	for Name, Type in pairs(CustomLib.ThemeObjects) do
		for _, Object in pairs(Type) do
			Object[ReturnProperty(Object)] = CustomLib.Themes[CustomLib.SelectedTheme][Name]
		end    
	end    
end

local function PackColor(Color)
	return {R = Color.R * 255, G = Color.G * 255, B = Color.B * 255}
end    

local function UnpackColor(Color)
	return Color3.fromRGB(Color.R, Color.G, Color.B)
end

local NotificationHolder = SetProps(SetChildren(MakeElement("TFrame"), {
	SetProps(MakeElement("List"), {
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Padding = UDim.new(0, 5)
	})
}), {
	Position = UDim2.new(1, -25, 1, -25),
	Size = UDim2.new(0, 300, 1, -25),
	AnchorPoint = Vector2.new(1, 1),
	Parent = UI
})

function CustomLib:MakeNotification(NotificationConfig)
	task.spawn(function()
		NotificationConfig.Name = NotificationConfig.Name or "Notification"
		NotificationConfig.Content = NotificationConfig.Content or "Test"
		NotificationConfig.Image = NotificationConfig.Image or "rbxassetid://4384403532"
		NotificationConfig.Time = NotificationConfig.Time or 15

		local NotificationParent = SetProps(MakeElement("TFrame"), {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Parent = NotificationHolder
		})

		local NotificationFrame = SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(25, 25, 25), 0, 10), {
			Parent = NotificationParent,
			Size = UDim2.new(1, 0, 0, 0),
			Position = UDim2.new(1, -55, 0, 0),
			BackgroundTransparency = 0,
			AutomaticSize = Enum.AutomaticSize.Y
		}), {
			MakeElement("Stroke", Color3.fromRGB(93, 93, 93), 1.2),
			MakeElement("Padding", 12, 12, 12, 12),
			SetProps(MakeElement("Image", NotificationConfig.Image), {
				Size = UDim2.new(0, 20, 0, 20),
				ImageColor3 = Color3.fromRGB(240, 240, 240),
				Name = "Icon"
			}),
			SetProps(MakeElement("Label", NotificationConfig.Name, 15), {
				Size = UDim2.new(1, -30, 0, 20),
				Position = UDim2.new(0, 30, 0, 0),
				Font = Enum.Font.GothamBold,
				Name = "Title"
			}),
			SetProps(MakeElement("Label", NotificationConfig.Content, 14), {
				Size = UDim2.new(1, 0, 0, 0),
				Position = UDim2.new(0, 0, 0, 25),
				Font = Enum.Font.GothamSemibold,
				Name = "Content",
				AutomaticSize = Enum.AutomaticSize.Y,
				TextColor3 = Color3.fromRGB(200, 200, 200),
				TextWrapped = true
			})
		})

		TweenService:Create(NotificationFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {Position = UDim2.new(0, 0, 0, 0)}):Play()

		wait(NotificationConfig.Time - 0.88)
		TweenService:Create(NotificationFrame.Icon, TweenInfo.new(0.4, Enum.EasingStyle.Quint), {ImageTransparency = 1}):Play()
		TweenService:Create(NotificationFrame, TweenInfo.new(0.8, Enum.EasingStyle.Quint), {BackgroundTransparency = 0.6}):Play()
		wait(0.3)
		TweenService:Create(NotificationFrame.UIStroke, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {Transparency = 0.9}):Play()
		TweenService:Create(NotificationFrame.Title, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency = 0.4}):Play()
		TweenService:Create(NotificationFrame.Content, TweenInfo.new(0.6, Enum.EasingStyle.Quint), {TextTransparency = 0.5}):Play()
		wait(0.05)

		NotificationFrame:TweenPosition(UDim2.new(1, 20, 0, 0), 'In', 'Quint', 0.8, true)
		wait(1.35)
		NotificationFrame:Destroy()
	end)
end    

function CustomLib:Init()
	if CustomLib.SaveCfg then	
		pcall(function()
			if isfile(CustomLib.Folder .. "/" .. game.GameId .. ".txt") then
				LoadCfg(readfile(CustomLib.Folder .. "/" .. game.GameId .. ".txt"))
				CustomLib:MakeNotification({
					Name = "Configuration",
					Content = "Auto-loaded configuration for the game " .. game.GameId .. ".",
					Time = 5
				})
			end
		end)		
	end	
end

function CustomLib:MakeWindow(WindowConfig)
	local FirstTab = true
	local Minimized = false
	local UIHidden = false

	WindowConfig = WindowConfig or {}
	WindowConfig.Name = WindowConfig.Name or "Custom UI Library"
	WindowConfig.ConfigFolder = WindowConfig.ConfigFolder or WindowConfig.Name
	WindowConfig.SaveConfig = WindowConfig.SaveConfig or false
	WindowConfig.CloseCallback = WindowConfig.CloseCallback or function() end
	WindowConfig.ShowIcon = WindowConfig.ShowIcon or false
	WindowConfig.Icon = WindowConfig.Icon or "rbxassetid://8834748103"
	CustomLib.Folder = WindowConfig.ConfigFolder
	CustomLib.SaveCfg = WindowConfig.SaveConfig

	if WindowConfig.SaveConfig then
		if not isfolder(WindowConfig.ConfigFolder) then
			makefolder(WindowConfig.ConfigFolder)
		end	
	end

	local TabHolder = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255, 255, 255), 4), {
		Size = UDim2.new(1, 0, 1, -50)
	}), {
		MakeElement("List"),
		MakeElement("Padding", 8, 0, 0, 8)
	}), "Divider")

	AddConnection(TabHolder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
		TabHolder.CanvasSize = UDim2.new(0, 0, 0, TabHolder.UIListLayout.AbsoluteContentSize.Y + 16)
	end)

	local CloseBtn = SetChildren(SetProps(MakeElement("Button"), {
		Size = UDim2.new(0.5, 0, 1, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		BackgroundTransparency = 1
	}), {
		AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072725342"), {
			Position = UDim2.new(0, 9, 0, 6),
			Size = UDim2.new(0, 18, 0, 18)
		}), "Text")
	})

	local MinimizeBtn = SetChildren(SetProps(MakeElement("Button"), {
		Size = UDim2.new(0.5, 0, 1, 0),
		BackgroundTransparency = 1
	}), {
		AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072719338"), {
			Position = UDim2.new(0, 9, 0, 6),
			Size = UDim2.new(0, 18, 0, 18),
			Name = "Ico"
		}), "Text")
	})

	local DragPoint = SetProps(MakeElement("TFrame"), {
		Size = UDim2.new(1, 0, 0, 50)
	})

	local WindowStuff = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 10), {
		Size = UDim2.new(0, 150, 1, -50),
		Position = UDim2.new(0, 0, 0, 50)
	}), {
		AddThemeObject(SetProps(MakeElement("Frame"), {
			Size = UDim2.new(1, 0, 0, 10),
			Position = UDim2.new(0, 0, 0, 0)
		}), "Second"), 
		TabHolder
	}), "Second")

	local WindowName = AddThemeObject(SetProps(MakeElement("Label", WindowConfig.Name, 14), {
		Size = UDim2.new(1, -30, 2, 0),
		Position = UDim2.new(0, 25, 0, -24),
		Font = Enum.Font.GothamBlack,
		TextSize = 20
	}), "Text")

	local MainWindow = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 10), {
		Parent = UI,
		Position = UDim2.new(0.5, -307, 0.5, -172),
		Size = UDim2.new(0, 615, 0, 344),
		ClipsDescendants = true
	}), {
		SetChildren(SetProps(MakeElement("TFrame"), {
			Size = UDim2.new(1, 0, 0, 50),
			Name = "TopBar"
		}), {
			WindowName
		}),
		DragPoint,
		WindowStuff
	}), "Main")

	MakeDraggable(DragPoint, MainWindow)
	-- Additional logic continues below...
	local TabFunction = {}
	function TabFunction:MakeTab(TabConfig)
		TabConfig = TabConfig or {}
		TabConfig.Name = TabConfig.Name or "Tab"
		TabConfig.Icon = TabConfig.Icon or ""

		local TabFrame = SetChildren(SetProps(MakeElement("Button"), {
			Size = UDim2.new(1, 0, 0, 30),
			Parent = TabHolder
		}), {
			AddThemeObject(SetProps(MakeElement("Image", TabConfig.Icon), {
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.new(0, 18, 0, 18),
				Position = UDim2.new(0, 10, 0.5, 0),
				ImageTransparency = 0.4,
				Name = "Ico"
			}), "Text"),
			AddThemeObject(SetProps(MakeElement("Label", TabConfig.Name, 14), {
				Size = UDim2.new(1, -35, 1, 0),
				Position = UDim2.new(0, 35, 0, 0),
				Font = Enum.Font.GothamSemibold,
				TextTransparency = 0.4,
				Name = "Title"
			}), "Text")
		})

		if GetIcon(TabConfig.Icon) ~= nil then
			TabFrame.Ico.Image = GetIcon(TabConfig.Icon)
		end	

		local Container = AddThemeObject(SetChildren(SetProps(MakeElement("ScrollFrame", Color3.fromRGB(255, 255, 255), 5), {
			Size = UDim2.new(1, -150, 1, -50),
			Position = UDim2.new(0, 150, 0, 50),
			Parent = MainWindow,
			Visible = false,
			Name = "ItemContainer"
		}), {
			MakeElement("List", 0, 6),
			MakeElement("Padding", 15, 10, 10, 15)
		}), "Divider")

		AddConnection(Container.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
			Container.CanvasSize = UDim2.new(0, 0, 0, Container.UIListLayout.AbsoluteContentSize.Y + 30)
		end)

		if FirstTab then
			FirstTab = false
			TabFrame.Ico.ImageTransparency = 0
			TabFrame.Title.TextTransparency = 0
			TabFrame.Title.Font = Enum.Font.GothamBlack
			Container.Visible = true
		end    

		AddConnection(TabFrame.MouseButton1Click, function()
			for _, Tab in next, TabHolder:GetChildren() do
				if Tab:IsA("TextButton") then
					Tab.Title.Font = Enum.Font.GothamSemibold
					TweenService:Create(Tab.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = 0.4}):Play()
					TweenService:Create(Tab.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0.4}):Play()
				end    
			end
			for _, ItemContainer in next, MainWindow:GetChildren() do
				if ItemContainer.Name == "ItemContainer" then
					ItemContainer.Visible = false
				end    
			end  
			TweenService:Create(TabFrame.Ico, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = 0}):Play()
			TweenService:Create(TabFrame.Title, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
			TabFrame.Title.Font = Enum.Font.GothamBlack
			Container.Visible = true   
		end)

		-- Element creation logic is here
		return self:CreateElements(Container)
	end
	function TabFunction:CreateElements(ItemParent)
		local ElementFunction = {}

		function ElementFunction:AddButton(ButtonConfig)
			ButtonConfig = ButtonConfig or {}
			ButtonConfig.Name = ButtonConfig.Name or "Button"
			ButtonConfig.Callback = ButtonConfig.Callback or function() end

			local Click = SetProps(MakeElement("Button"), {
				Size = UDim2.new(1, 0, 1, 0)
			})

			local ButtonFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
				Size = UDim2.new(1, 0, 0, 33),
				Parent = ItemParent
			}), {
				AddThemeObject(SetProps(MakeElement("Label", ButtonConfig.Name, 15), {
					Size = UDim2.new(1, -12, 1, 0),
					Position = UDim2.new(0, 12, 0, 0),
					Font = Enum.Font.GothamBold,
					Name = "Content"
				}), "Text"),
				AddThemeObject(MakeElement("Stroke"), "Stroke"),
				Click
			}), "Second")

			AddConnection(Click.MouseButton1Click, function()
				ButtonConfig.Callback()
			end)

			return ButtonFrame
		end    

		function ElementFunction:AddSlider(SliderConfig)
			SliderConfig = SliderConfig or {}
			SliderConfig.Name = SliderConfig.Name or "Slider"
			SliderConfig.Min = SliderConfig.Min or 0
			SliderConfig.Max = SliderConfig.Max or 100
			SliderConfig.Increment = SliderConfig.Increment or 1
			SliderConfig.Default = SliderConfig.Default or 50
			SliderConfig.Callback = SliderConfig.Callback or function() end

			local Slider = {Value = SliderConfig.Default}
			local Dragging = false

			local SliderDrag = SetChildren(SetProps(MakeElement("RoundFrame", SliderConfig.Color or Color3.fromRGB(0, 149, 255), 0, 5), {
				Size = UDim2.new(0, 0, 1, 0),
				BackgroundTransparency = 0.3,
				ClipsDescendants = true
			}), {
				AddThemeObject(SetProps(MakeElement("Label", "value", 13), {
					Size = UDim2.new(1, -12, 0, 14),
					Position = UDim2.new(0, 12, 0, 6),
					Font = Enum.Font.GothamBold,
					Name = "Value",
					TextTransparency = 0
				}), "Text")
			})

			local SliderBar = SetChildren(SetProps(MakeElement("RoundFrame", SliderConfig.Color or Color3.fromRGB(0, 149, 255), 0, 5), {
				Size = UDim2.new(1, -24, 0, 26),
				Position = UDim2.new(0, 12, 0, 30),
				BackgroundTransparency = 0.9
			}), {
				SetProps(MakeElement("Stroke"), {
					Color = SliderConfig.Color or Color3.fromRGB(0, 149, 255)
				}),
				AddThemeObject(SetProps(MakeElement("Label", "value", 13), {
					Size = UDim2.new(1, -12, 0, 14),
					Position = UDim2.new(0, 12, 0, 6),
					Font = Enum.Font.GothamBold,
					Name = "Value",
					TextTransparency = 0.8
				}), "Text"),
				SliderDrag
			})

			local SliderFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 4), {
				Size = UDim2.new(1, 0, 0, 65),
				Parent = ItemParent
			}), {
				AddThemeObject(SetProps(MakeElement("Label", SliderConfig.Name, 15), {
					Size = UDim2.new(1, -12, 0, 14),
					Position = UDim2.new(0, 12, 0, 10),
					Font = Enum.Font.GothamBold,
					Name = "Content"
				}), "Text"),
				AddThemeObject(MakeElement("Stroke"), "Stroke"),
				SliderBar
			}), "Second")

			AddConnection(SliderBar.InputBegan, function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then 
					Dragging = true 
				end 
			end)

			AddConnection(SliderBar.InputEnded, function(Input)
				if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then 
					Dragging = false 
				end 
			end)

			AddConnection(UserInputService.InputChanged, function(Input)
				if Dragging then 
					local SizeScale = math.clamp((Mouse.X - SliderBar.AbsolutePosition.X) / SliderBar.AbsoluteSize.X, 0, 1)
					Slider:Set(SliderConfig.Min + ((SliderConfig.Max - SliderConfig.Min) * SizeScale)) 
				end
			end)

			function Slider:Set(Value)
				self.Value = math.clamp(Round(Value, SliderConfig.Increment), SliderConfig.Min, SliderConfig.Max)
				TweenService:Create(SliderDrag, TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.fromScale((self.Value - SliderConfig.Min) / (SliderConfig.Max - SliderConfig.Min), 1)}):Play()
				SliderBar.Value.Text = tostring(self.Value)
				SliderConfig.Callback(self.Value)
			end      

			Slider:Set(Slider.Value)
			return Slider
		end    

		-- You can now add similar functions for toggles, dropdowns, etc.
		return ElementFunction
	end
		function ElementFunction:AddDropdown(DropdownConfig)
			DropdownConfig = DropdownConfig or {}
			DropdownConfig.Name = DropdownConfig.Name or "Dropdown"
			DropdownConfig.Options = DropdownConfig.Options or {}
			DropdownConfig.Default = DropdownConfig.Default or ""
			DropdownConfig.Callback = DropdownConfig.Callback or function() end

			local Dropdown = {Value = DropdownConfig.Default, Options = DropdownConfig.Options, Buttons = {}, Toggled = false}
			local MaxElements = 5

			if not table.find(Dropdown.Options, Dropdown.Value) then
				Dropdown.Value = "..."
			end

			local DropdownList = MakeElement("List")

			local DropdownContainer = AddThemeObject(SetProps(SetChildren(MakeElement("ScrollFrame", Color3.fromRGB(40, 40, 40), 4), {
				DropdownList
			}), {
				Parent = ItemParent,
				Position = UDim2.new(0, 0, 0, 38),
				Size = UDim2.new(1, 0, 1, -38),
				ClipsDescendants = true
			}), "Divider")

			local Click = SetProps(MakeElement("Button"), {
				Size = UDim2.new(1, 0, 1, 0)
			})

			local DropdownFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
				Size = UDim2.new(1, 0, 0, 38),
				Parent = ItemParent,
				ClipsDescendants = true
			}), {
				DropdownContainer,
				SetProps(SetChildren(MakeElement("TFrame"), {
					AddThemeObject(SetProps(MakeElement("Label", DropdownConfig.Name, 15), {
						Size = UDim2.new(1, -12, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content"
					}), "Text"),
					AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://7072706796"), {
						Size = UDim2.new(0, 20, 0, 20),
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.new(1, -30, 0.5, 0),
						ImageColor3 = Color3.fromRGB(240, 240, 240),
						Name = "Ico"
					}), "TextDark"),
					AddThemeObject(SetProps(MakeElement("Label", "Selected", 13), {
						Size = UDim2.new(1, -40, 1, 0),
						Font = Enum.Font.Gotham,
						Name = "Selected",
						TextXAlignment = Enum.TextXAlignment.Right
					}), "TextDark"),
					AddThemeObject(SetProps(MakeElement("Frame"), {
						Size = UDim2.new(1, 0, 0, 1),
						Position = UDim2.new(0, 0, 1, -1),
						Name = "Line",
						Visible = false
					}), "Stroke"),
					Click
				}), {
					Size = UDim2.new(1, 0, 0, 38),
					ClipsDescendants = true,
					Name = "F"
				}),
				AddThemeObject(MakeElement("Stroke"), "Stroke"),
				MakeElement("Corner")
			}), "Second")

			AddConnection(DropdownList:GetPropertyChangedSignal("AbsoluteContentSize"), function()
				DropdownContainer.CanvasSize = UDim2.new(0, 0, 0, DropdownList.AbsoluteContentSize.Y)
			end)

			local function AddOptions(Options)
				for _, Option in pairs(Options) do
					local OptionBtn = AddThemeObject(SetProps(SetChildren(MakeElement("Button", Color3.fromRGB(40, 40, 40)), {
						MakeElement("Corner", 0, 6),
						AddThemeObject(SetProps(MakeElement("Label", Option, 13, 0.4), {
							Position = UDim2.new(0, 8, 0, 0),
							Size = UDim2.new(1, -8, 1, 0),
							Name = "Title"
						}), "Text")
					}), {
						Parent = DropdownContainer,
						Size = UDim2.new(1, 0, 0, 28),
						BackgroundTransparency = 1,
						ClipsDescendants = true
					}), "Divider")

					AddConnection(OptionBtn.MouseButton1Click, function()
						Dropdown:Set(Option)
					end)

					Dropdown.Buttons[Option] = OptionBtn
				end
			end

			function Dropdown:Refresh(Options, Delete)
				if Delete then
					for _,v in pairs(Dropdown.Buttons) do
						v:Destroy()
					end    
					table.clear(Dropdown.Options)
					table.clear(Dropdown.Buttons)
				end
				Dropdown.Options = Options
				AddOptions(Dropdown.Options)
			end  

			function Dropdown:Set(Value)
				if not table.find(Dropdown.Options, Value) then
					Dropdown.Value = "..."
					DropdownFrame.F.Selected.Text = Dropdown.Value
					for _, v in pairs(Dropdown.Buttons) do
						TweenService:Create(v, TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
						TweenService:Create(v.Title, TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.4}):Play()
					end	
					return
				end

				Dropdown.Value = Value
				DropdownFrame.F.Selected.Text = Dropdown.Value

				for _, v in pairs(Dropdown.Buttons) do
					TweenService:Create(v, TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
					TweenService:Create(v.Title, TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0.4}):Play()
				end	
				TweenService:Create(Dropdown.Buttons[Value], TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0}):Play()
				TweenService:Create(Dropdown.Buttons[Value].Title, TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
				return DropdownConfig.Callback(Dropdown.Value)
			end

			AddConnection(Click.MouseButton1Click, function()
				Dropdown.Toggled = not Dropdown.Toggled
				DropdownFrame.F.Line.Visible = Dropdown.Toggled
				TweenService:Create(DropdownFrame.F.Ico, TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Rotation = Dropdown.Toggled and 180 or 0}):Play()
				if #Dropdown.Options > MaxElements then
					TweenService:Create(DropdownFrame, TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Dropdown.Toggled and UDim2.new(1, 0, 0, 38 + (MaxElements * 28)) or UDim2.new(1, 0, 0, 38)}):Play()
				else
					TweenService:Create(DropdownFrame, TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Dropdown.Toggled and UDim2.new(1, 0, 0, DropdownList.AbsoluteContentSize.Y + 38) or UDim2.new(1, 0, 0, 38)}):Play()
				end
			end)

			Dropdown:Refresh(Dropdown.Options, false)
			Dropdown:Set(Dropdown.Value)
			return Dropdown
		end
		function ElementFunction:AddToggle(ToggleConfig)
			ToggleConfig = ToggleConfig or {}
			ToggleConfig.Name = ToggleConfig.Name or "Toggle"
			ToggleConfig.Default = ToggleConfig.Default or false
			ToggleConfig.Callback = ToggleConfig.Callback or function() end
			ToggleConfig.Color = ToggleConfig.Color or Color3.fromRGB(9, 99, 195)

			local Toggle = {Value = ToggleConfig.Default}

			local Click = SetProps(MakeElement("Button"), {
				Size = UDim2.new(1, 0, 1, 0)
			})

			local ToggleBox = SetChildren(SetProps(MakeElement("RoundFrame", ToggleConfig.Color, 0, 4), {
				Size = UDim2.new(0, 24, 0, 24),
				Position = UDim2.new(1, -24, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5)
			}), {
				SetProps(MakeElement("Stroke"), {
					Color = ToggleConfig.Color,
					Name = "Stroke",
					Transparency = 0.5
				}),
				SetProps(MakeElement("Image", "rbxassetid://3944680095"), {
					Size = UDim2.new(0, 20, 0, 20),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					ImageColor3 = Color3.fromRGB(255, 255, 255),
					Name = "Ico"
				}),
			})

			local ToggleFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
				Size = UDim2.new(1, 0, 0, 38),
				Parent = ItemParent
			}), {
				AddThemeObject(SetProps(MakeElement("Label", ToggleConfig.Name, 15), {
					Size = UDim2.new(1, -12, 1, 0),
					Position = UDim2.new(0, 12, 0, 0),
					Font = Enum.Font.GothamBold,
					Name = "Content"
				}), "Text"),
				AddThemeObject(MakeElement("Stroke"), "Stroke"),
				ToggleBox,
				Click
			}), "Second")

			function Toggle:Set(Value)
				Toggle.Value = Value
				TweenService:Create(ToggleBox, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Toggle.Value and ToggleConfig.Color or OrionLib.Themes.Default.Divider}):Play()
				TweenService:Create(ToggleBox.Stroke, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Color = Toggle.Value and ToggleConfig.Color or OrionLib.Themes.Default.Stroke}):Play()
				TweenService:Create(ToggleBox.Ico, TweenInfo.new(0.3, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {ImageTransparency = Toggle.Value and 0 or 1, Size = Toggle.Value and UDim2.new(0, 20, 0, 20) or UDim2.new(0, 8, 0, 8)}):Play()
				ToggleConfig.Callback(Toggle.Value)
			end    

			Toggle:Set(Toggle.Value)

			AddConnection(Click.MouseEnter, function()
				TweenService:Create(ToggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)}):Play()
			end)

			AddConnection(Click.MouseLeave, function()
				TweenService:Create(ToggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second}):Play()
			end)

			AddConnection(Click.MouseButton1Up, function()
				TweenService:Create(ToggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)}):Play()
				Toggle:Set(not Toggle.Value)
			end)

			AddConnection(Click.MouseButton1Down, function()
				TweenService:Create(ToggleFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 6, OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 6, OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 6)}):Play()
			end)

			return Toggle
		end
		function ElementFunction:AddTextbox(TextboxConfig)
			TextboxConfig = TextboxConfig or {}
			TextboxConfig.Name = TextboxConfig.Name or "Textbox"
			TextboxConfig.Default = TextboxConfig.Default or ""
			TextboxConfig.TextDisappear = TextboxConfig.TextDisappear or false
			TextboxConfig.Callback = TextboxConfig.Callback or function() end

			local Click = SetProps(MakeElement("Button"), {
				Size = UDim2.new(1, 0, 1, 0)
			})

			local TextboxActual = AddThemeObject(Create("TextBox", {
				Size = UDim2.new(1, 0, 1, 0),
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				PlaceholderColor3 = Color3.fromRGB(210, 210, 210),
				PlaceholderText = "Input",
				Font = Enum.Font.GothamSemibold,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextSize = 14,
				ClearTextOnFocus = false
			}), "Text")

			local TextContainer = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 4), {
				Size = UDim2.new(0, 24, 0, 24),
				Position = UDim2.new(1, -12, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5)
			}), {
				AddThemeObject(MakeElement("Stroke"), "Stroke"),
				TextboxActual
			}), "Main")

			local TextboxFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
				Size = UDim2.new(1, 0, 0, 38),
				Parent = ItemParent
			}), {
				AddThemeObject(SetProps(MakeElement("Label", TextboxConfig.Name, 15), {
					Size = UDim2.new(1, -12, 1, 0),
					Position = UDim2.new(0, 12, 0, 0),
					Font = Enum.Font.GothamBold,
					Name = "Content"
				}), "Text"),
				AddThemeObject(MakeElement("Stroke"), "Stroke"),
				TextContainer,
				Click
			}), "Second")

			AddConnection(TextboxActual:GetPropertyChangedSignal("Text"), function()
				TweenService:Create(TextContainer, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.new(0, TextboxActual.TextBounds.X + 16, 0, 24)}):Play()
			end)

			AddConnection(TextboxActual.FocusLost, function()
				TextboxConfig.Callback(TextboxActual.Text)
				if TextboxConfig.TextDisappear then
					TextboxActual.Text = ""
				end
			end)

			TextboxActual.Text = TextboxConfig.Default

			AddConnection(Click.MouseEnter, function()
				TweenService:Create(TextboxFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)}):Play()
			end)

			AddConnection(Click.MouseLeave, function()
				TweenService:Create(TextboxFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = OrionLib.Themes[OrionLib.SelectedTheme].Second}):Play()
			end)

			AddConnection(Click.MouseButton1Up, function()
				TweenService:Create(TextboxFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 3, OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 3)}):Play()
				TextboxActual:CaptureFocus()
			end)

			AddConnection(Click.MouseButton1Down, function()
				TweenService:Create(TextboxFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {BackgroundColor3 = Color3.fromRGB(OrionLib.Themes[OrionLib.SelectedTheme].Second.R * 255 + 6, OrionLib.Themes[OrionLib.SelectedTheme].Second.G * 255 + 6, OrionLib.Themes[OrionLib.SelectedTheme].Second.B * 255 + 6)}):Play()
			end)
		end
		function ElementFunction:AddColorpicker(ColorpickerConfig)
			ColorpickerConfig = ColorpickerConfig or {}
			ColorpickerConfig.Name = ColorpickerConfig.Name or "Colorpicker"
			ColorpickerConfig.Default = ColorpickerConfig.Default or Color3.fromRGB(255, 255, 255)
			ColorpickerConfig.Callback = ColorpickerConfig.Callback or function() end

			local ColorH, ColorS, ColorV = 1, 1, 1
			local Colorpicker = {Value = ColorpickerConfig.Default, Toggled = false}

			local ColorSelection = Create("ImageLabel", {
				Size = UDim2.new(0, 18, 0, 18),
				Position = UDim2.new(select(3, Color3.toHSV(Colorpicker.Value))),
				ScaleType = Enum.ScaleType.Fit,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Image = "http://www.roblox.com/asset/?id=4805639000"
			})

			local HueSelection = Create("ImageLabel", {
				Size = UDim2.new(0, 18, 0, 18),
				Position = UDim2.new(0.5, 0, 1 - select(1, Color3.toHSV(Colorpicker.Value))),
				ScaleType = Enum.ScaleType.Fit,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Image = "http://www.roblox.com/asset/?id=4805639000"
			})

			local Color = Create("ImageLabel", {
				Size = UDim2.new(1, -25, 1, 0),
				Visible = false,
				Image = "rbxassetid://4155801252"
			}, {
				Create("UICorner", {CornerRadius = UDim.new(0, 5)}),
				ColorSelection
			})

			local Hue = Create("Frame", {
				Size = UDim2.new(0, 20, 1, 0),
				Position = UDim2.new(1, -20, 0, 0),
				Visible = false
			}, {
				Create("UIGradient", {Rotation = 270, Color = ColorSequence.new{
					ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 4)),
					ColorSequenceKeypoint.new(0.20, Color3.fromRGB(234, 255, 0)),
					ColorSequenceKeypoint.new(0.40, Color3.fromRGB(21, 255, 0)),
					ColorSequenceKeypoint.new(0.60, Color3.fromRGB(0, 255, 255)),
					ColorSequenceKeypoint.new(0.80, Color3.fromRGB(0, 17, 255)),
					ColorSequenceKeypoint.new(0.90, Color3.fromRGB(255, 0, 251)),
					ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 4))
				}}),
				Create("UICorner", {CornerRadius = UDim.new(0, 5)}),
				HueSelection
			})

			local ColorpickerFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
				Size = UDim2.new(1, 0, 0, 38),
				Parent = ItemParent
			}), {
				SetProps(SetChildren(MakeElement("TFrame"), {
					AddThemeObject(SetProps(MakeElement("Label", ColorpickerConfig.Name, 15), {
						Size = UDim2.new(1, -12, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content"
					}), "Text"),
				}), {Size = UDim2.new(1, 0, 0, 38)})
			}), "Second")

			function Colorpicker:Set(Value)
				Colorpicker.Value = Value
				ColorpickerConfig.Callback(Colorpicker.Value)
			end

			Colorpicker:Set(Colorpicker.Value)
			return Colorpicker
		end
			local ColorpickerContainer = Create("Frame", {
				Position = UDim2.new(0, 0, 0, 32),
				Size = UDim2.new(1, 0, 1, -32),
				BackgroundTransparency = 1,
				ClipsDescendants = true
			}, {
				Hue,
				Color,
				Create("UIPadding", {
					PaddingLeft = UDim.new(0, 35),
					PaddingRight = UDim.new(0, 35),
					PaddingBottom = UDim.new(0, 10),
					PaddingTop = UDim.new(0, 17)
				})
			})

			local Click = SetProps(MakeElement("Button"), {
				Size = UDim2.new(1, 0, 1, 0)
			})

			local ColorpickerBox = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 4), {
				Size = UDim2.new(0, 24, 0, 24),
				Position = UDim2.new(1, -12, 0.5, 0),
				AnchorPoint = Vector2.new(1, 0.5)
			}), {
				AddThemeObject(MakeElement("Stroke"), "Stroke")
			}), "Main")

			local ColorpickerFrame = AddThemeObject(SetChildren(SetProps(MakeElement("RoundFrame", Color3.fromRGB(255, 255, 255), 0, 5), {
				Size = UDim2.new(1, 0, 0, 38),
				Parent = ItemParent
			}), {
				SetProps(SetChildren(MakeElement("TFrame"), {
					AddThemeObject(SetProps(MakeElement("Label", ColorpickerConfig.Name, 15), {
						Size = UDim2.new(1, -12, 1, 0),
						Position = UDim2.new(0, 12, 0, 0),
						Font = Enum.Font.GothamBold,
						Name = "Content"
					}), "Text"),
					ColorpickerBox,
					Click,
					AddThemeObject(SetProps(MakeElement("Frame"), {
						Size = UDim2.new(1, 0, 0, 1),
						Position = UDim2.new(0, 0, 1, -1),
						Name = "Line",
						Visible = false
					}), "Stroke")
				}), {
					Size = UDim2.new(1, 0, 0, 38),
					ClipsDescendants = true,
					Name = "F"
				}),
				ColorpickerContainer,
				AddThemeObject(MakeElement("Stroke"), "Stroke")
			}), "Second")

			AddConnection(Click.MouseButton1Click, function()
				Colorpicker.Toggled = not Colorpicker.Toggled
				TweenService:Create(ColorpickerFrame, TweenInfo.new(.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Colorpicker.Toggled and UDim2.new(1, 0, 0, 148) or UDim2.new(1, 0, 0, 38)}):Play()
				Color.Visible = Colorpicker.Toggled
				Hue.Visible = Colorpicker.Toggled
				ColorpickerFrame.F.Line.Visible = Colorpicker.Toggled
			end)

			local function UpdateColorPicker()
				ColorpickerBox.BackgroundColor3 = Color3.fromHSV(ColorH, ColorS, ColorV)
				Color.BackgroundColor3 = Color3.fromHSV(ColorH, 1, 1)
				Colorpicker:Set(ColorpickerBox.BackgroundColor3)
				ColorpickerConfig.Callback(ColorpickerBox.BackgroundColor3)
				SaveCfg(game.GameId)
			end

			ColorH = 1 - (math.clamp(HueSelection.AbsolutePosition.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y) / Hue.AbsoluteSize.Y)
			ColorS = (math.clamp(ColorSelection.AbsolutePosition.X - Color.AbsolutePosition.X, 0, Color.AbsoluteSize.X) / Color.AbsoluteSize.X)
			ColorV = 1 - (math.clamp(ColorSelection.AbsolutePosition.Y - Color.AbsolutePosition.Y, 0, Color.AbsoluteSize.Y) / Color.AbsoluteSize.Y)

			AddConnection(Color.InputBegan, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					if ColorInput then
						ColorInput:Disconnect()
					end
					ColorInput = AddConnection(RunService.RenderStepped, function()
						local ColorX = (math.clamp(Mouse.X - Color.AbsolutePosition.X, 0, Color.AbsoluteSize.X) / Color.AbsoluteSize.X)
						local ColorY = (math.clamp(Mouse.Y - Color.AbsolutePosition.Y, 0, Color.AbsoluteSize.Y) / Color.AbsoluteSize.Y)
						ColorSelection.Position = UDim2.new(ColorX, 0, ColorY, 0)
						ColorS = ColorX
						ColorV = 1 - ColorY
						UpdateColorPicker()
					end)
				end
			end)

			AddConnection(Color.InputEnded, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					if ColorInput then
						ColorInput:Disconnect()
					end
				end
			end)

			AddConnection(Hue.InputBegan, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					if HueInput then
						HueInput:Disconnect()
					end

					HueInput = AddConnection(RunService.RenderStepped, function()
						local HueY = (math.clamp(Mouse.Y - Hue.AbsolutePosition.Y, 0, Hue.AbsoluteSize.Y) / Hue.AbsoluteSize.Y)

						HueSelection.Position = UDim2.new(0.5, 0, HueY, 0)
						ColorH = 1 - HueY

						UpdateColorPicker()
					end)
				end
			end)

			AddConnection(Hue.InputEnded, function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					if HueInput then
						HueInput:Disconnect()
					end
				end
			end)

			function Colorpicker:Set(Value)
				Colorpicker.Value = Value
				ColorpickerBox.BackgroundColor3 = Colorpicker.Value
				ColorpickerConfig.Callback(Colorpicker.Value)
			end

			Colorpicker:Set(Colorpicker.Value)
			if ColorpickerConfig.Flag then				
				OrionLib.Flags[ColorpickerConfig.Flag] = Colorpicker
			end
			return Colorpicker
		end
   			return ElementFunction
		end

		-- Build the UI for this Tab
		local TabFunction = {}

		-- Add a Section to the Tab
		function TabFunction:AddSection(SectionConfig)
			SectionConfig = SectionConfig or {}
			SectionConfig.Name = SectionConfig.Name or "Section"

			local SectionFrame = SetChildren(SetProps(MakeElement("TFrame"), {
				Size = UDim2.new(1, 0, 0, 26),
				Parent = Container
			}), {
				AddThemeObject(SetProps(MakeElement("Label", SectionConfig.Name, 14), {
					Size = UDim2.new(1, -12, 0, 16),
					Position = UDim2.new(0, 0, 0, 3),
					Font = Enum.Font.GothamSemibold
				}), "TextDark"),
				SetChildren(SetProps(MakeElement("TFrame"), {
					AnchorPoint = Vector2.new(0, 0),
					Size = UDim2.new(1, 0, 1, -24),
					Position = UDim2.new(0, 0, 0, 23),
					Name = "Holder"
				}), {
					MakeElement("List", 0, 6)
				}),
			})

			AddConnection(SectionFrame.Holder.UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
				SectionFrame.Size = UDim2.new(1, 0, 0, SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y + 31)
				SectionFrame.Holder.Size = UDim2.new(1, 0, 0, SectionFrame.Holder.UIListLayout.AbsoluteContentSize.Y)
			end)

			local SectionFunction = {}
			for i, v in next, GetElements(SectionFrame.Holder) do
				SectionFunction[i] = v
			end
			return SectionFunction
		end

		for i, v in next, GetElements(Container) do
			TabFunction[i] = v
		end

		if TabConfig.PremiumOnly then
			for i, v in next, TabFunction do
				TabFunction[i] = function() end
			end
			Container:FindFirstChild("UIListLayout"):Destroy()
			Container:FindFirstChild("UIPadding"):Destroy()
			SetChildren(SetProps(MakeElement("TFrame"), {
				Size = UDim2.new(1, 0, 1, 0),
				Parent = ItemParent
			}), {
				AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://3610239960"), {
					Size = UDim2.new(0, 18, 0, 18),
					Position = UDim2.new(0, 15, 0, 15),
					ImageTransparency = 0.4
				}), "Text"),
				AddThemeObject(SetProps(MakeElement("Label", "Unauthorized Access", 14), {
					Size = UDim2.new(1, -38, 0, 14),
					Position = UDim2.new(0, 38, 0, 18),
					TextTransparency = 0.4
				}), "Text"),
				AddThemeObject(SetProps(MakeElement("Image", "rbxassetid://4483345875"), {
					Size = UDim2.new(0, 56, 0, 56),
					Position = UDim2.new(0, 84, 0, 110),
				}), "Text"),
				AddThemeObject(SetProps(MakeElement("Label", "Premium Features", 14), {
					Size = UDim2.new(1, -150, 0, 14),
					Position = UDim2.new(0, 150, 0, 112),
					Font = Enum.Font.GothamBold
				}), "Text"),
				AddThemeObject(SetProps(MakeElement("Label", "This part of the script is locked to Premium users. Unlock it in the Discord server.", 12), {
					Size = UDim2.new(1, -200, 0, 14),
					Position = UDim2.new(0, 150, 0, 138),
					TextWrapped = true,
					TextTransparency = 0.4
				}), "Text")
			})
		end

		return TabFunction
	end
end

function OrionLib:Destroy()
	Orion:Destroy()
end

return OrionLib


