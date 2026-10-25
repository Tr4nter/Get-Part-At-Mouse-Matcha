local camera = workspace.CurrentCamera
local cameraMatrixOffset = camera.Address+0xc0 -- https://offsets.imtheo.lol/

local lPlayer = game.Players.LocalPlayer
local Mouse = lPlayer:GetMouse()
local objectText = Drawing.new("Text")
objectText.Visible = true

local Enabled = true

local display = "Name"
local copyKey = "F"

local _currentObject 
local clipboardSet 

local Lib = loadstring(game:HttpGet("https://raw.githubusercontent.com/neaxusxgod-png/INS-ui/main/uilib.min.lua"))() or INSUI
local win = Lib:CreateWindow({ title = "Get Part At Mouse", size = Vector2.new(350,400)})
local tab = win:Tab("Main", "cog")
local sec = tab:Section("Main", "Full")


sec:Toggle("Enabled", true, function(state) Enabled = state end)
sec:Dropdown("Part Info Display", {"Name"}, {"Name", "Path", "Precise Path"},false, function(v) 
    display = v[1]
    
end)
sec:Keybind("Copy Path(Hold + Click)", "F", function(key) copyKey = string.upper(key) end)

local function readFloat(a)
    local bits = memory_read("int", a)
    local value, _ = string.unpack("<f", string.pack("<i4", bits))
    return value
end



local function resolveObjectName(object)
    local c = 0
    local index = 1
    if not object.Parent then return object.Name end
    for i, v in object.Parent:GetChildren() do
        if v.Name == object.Name then
            c += 1
        end
        if v == object then index = i end
    end
    
    if c >= 2 then
        return `:GetChildren()[{index}]`
    else
        return object.Name
    end
end


local function getPrecisePath(object)
    if not object.Parent then return object.Name end
    local objectName = resolveObjectName(object) 
    local result = not string.find(objectName, " ") and objectName or `["{objectName}"]`
    local _parent = object.Parent
    while _parent do
        local parentName = resolveObjectName(_parent)
        if parentName == "Ugc" and not _parent.Parent then
            parentName = "game"
        end
        
        local connector = "."
        if string.sub(result, 0, 1) == "[" or string.sub(result, 0, 1) == ":" then
            connector = ""
        end
        if not string.find(parentName, " ") then
            result = `{parentName}{connector}{result}` 
        else
            result = `["{parentName}"]{connector}{result}` 
        end
        _parent = _parent.Parent

        
    end
    return result
end

local function getPath(object)

    if not object.Parent then return object.Name end
    local objectName = object.Name 
    local result = not string.find(objectName, " ") and objectName or `["{objectName}"]`
    local _parent = object.Parent
    while _parent do
        local parentName = _parent.Name 
        if parentName == "Ugc" and not _parent.Parent then
            parentName = "game"
        end
        
        local connector = "."
        if string.sub(result, 0, 1) == "["  then
            connector = ""
        end
        if not string.find(parentName, " ") then
            result = `{parentName}{connector}{result}` 
        else
            result = `["{parentName}"]{connector}{result}` 
        end
        _parent = _parent.Parent

        
    end
    return result
end

local function getMouseDir()
    --VVV SPONSORED BY CHINESE DEEPSEEK V3
    local mouseX, mouseY = Mouse.X, Mouse.Y
   
    local viewportSize = camera.ViewportSize
    if not camera or not camera.FieldOfView then return Vector3.new() end
    local fovRad = math.rad(camera.FieldOfView)

    local ndcX = (2 * mouseX / viewportSize.X) - 1
    local ndcY = 1 - (2 * mouseY / viewportSize.Y)

    local tanHalfFov = math.tan(fovRad/2)
    local aspectRatio = viewportSize.X / viewportSize.Y

    local localDirection = Vector3.new(
        ndcX * tanHalfFov * aspectRatio,
        ndcY * tanHalfFov,
        -1
    ).Unit

    local position = camera.Position

    local m00 = readFloat(cameraMatrixOffset)
    local m01 = readFloat(cameraMatrixOffset+0x04)
    local m02 = readFloat(cameraMatrixOffset+0x08)
    local m10 = readFloat(cameraMatrixOffset+0x0C)
    local m11 = readFloat(cameraMatrixOffset+0x10)
    local m12 = readFloat(cameraMatrixOffset+0x14)
    local m20 = readFloat(cameraMatrixOffset+0x18)
    local m21 = readFloat(cameraMatrixOffset+0x1C)
    local m22 = readFloat(cameraMatrixOffset+0x20)

    local cf = CFrame.new(
    position.X, position.Y, position.Z,
    m00, m01, m02,
    m10, m11, m12,
    m20, m21, m22
)
    return cf:VectorToWorldSpace(localDirection)
end
local hb
local rd
hb = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
    if not win:IsOpen() or not workspace.Raycast then
        objectText:Remove()
        hb:Disconnect()
        if win and win.Unload then
            win:Unload()
        end
    end

    if not Enabled then 
        objectText.Visible = false
        return 
    end
    local dir = getMouseDir()
    local ray = workspace:Raycast(camera.Position, dir*1000)
    if ray then
        local pos, onScreen = WorldToScreen(ray.Position+Vector3.new(0, 0.5,0))
        objectText.Visible = onScreen
        objectText.Position = pos
        if display == "Name" then
            objectText.Text = ray.Instance.Name
        elseif display == "Path" then
            objectText.Text = getPath(ray.Instance)
        else
            objectText.Text = getPrecisePath(ray.Instance)

        end

        _currentObject = ray.Instance
    end
    if not ray or not objectText.Visible then
        _currentObject = nil
        objectText.Text = ""
    end
end)

rd = game:GetService("RunService").RenderStepped:Connect(function(deltaTime)
    if not win:IsOpen() or not workspace.Raycast then
        rd:Disconnect()
        if win and win.Unload then
            win:Unload()
        end
    end

    local isKeyDown = iskeypressed(string.byte(string.upper(copyKey)))
    if _currentObject and ismouse1pressed() and Enabled and isKeyDown then
        if clipboardSet == _currentObject or objectText.Text == "" then return end 
        setclipboard(objectText.Text)
        clipboardSet = _currentObject
    end
end)
