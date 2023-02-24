Class = require 'lib/class'
Vector = require 'lib/vector'
require 'lib/color'
require 'CONSTANTS'
imgui = require "lib.cimgui"
local ffi = require("ffi")

require 'Curve'

local curve = Curve()

Mouse = Vector(0, 0)

Modes = {
    AddNew = 0,
    Edit = 1,
    Delete = 2,
    AddBetween = 3,
}
MODE = Modes.AddNew

AddBetween = {1, 2} -- the index of the two points to add between when in add between mode

BackgroundColor = GRAY_E

function love.load()
    math.randomseed(os.time())
    love.window.setTitle("Bezier Tool V1.0")
    love.window.setMode(Window.width, Window.height)
    imgui.love.Init("RGBA32")

    love.keyboard.keysPressed = {}
    love.mouse.keysPressed = {}
    love.mouse.keysReleased = {}
    love.mouse.scrolled = 0

end

function love.update(dt)
    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
    imgui.love.Update(dt)
    imgui.NewFrame()

    -- scroll to change the points to add between when in add between mode
    if love.mouse.scrolled ~= 0 then
        if love.mouse.scrolled > 0 then
            if AddBetween[2] < curve.count then
                AddBetween[2] = AddBetween[2] + 1
                AddBetween[1] = AddBetween[1] + 1
            else
                AddBetween[2] = curve.count
                AddBetween[1] = curve.count - 1
            end
        else
            if AddBetween[1] == 1 then
                AddBetween[1] = 1
                AddBetween[2] = 2
            else
                AddBetween[1] = AddBetween[1] - 1
                AddBetween[2] = AddBetween[2] - 1
            end
        end
    end

    -- change mode with number keys
    if love.keyboard.wasPressed('1') then
        MODE = Modes.AddNew
    elseif love.keyboard.wasPressed('2') then
        MODE = Modes.AddBetween
    elseif love.keyboard.wasPressed('3') then
        MODE = Modes.Edit
    elseif love.keyboard.wasPressed('4') then
        MODE = Modes.Delete
    end

    -- add a point when left clicking
    if love.mouse.wasPressed(1) then
        if MODE == Modes.AddNew then
            curve:AddPoint(Mouse.x, Mouse.y)
        elseif MODE == Modes.AddBetween then
            curve:AddPointBetween(Mouse.x, Mouse.y, AddBetween[1], AddBetween[2])
        elseif MODE == Modes.Edit then
            curve:EditPoint(Mouse.x, Mouse.y)
        elseif MODE == Modes.Delete then
            curve:DeletePoint(Mouse.x, Mouse.y)
        end
    end

    -- Imgui window for editing the curve and changing the settings
    imgui.Begin("Editor")
    -- Show the bezier tools
    ShowBezierTools()
    -- Show the color options
    ShowColorOptions()
    -- Show the background color options if there is no background image
    if not BGimg then
        ShowBackgroundColorOptions()
    end
    -- Show the background image options
    ShowBackgroundImageOptions()
    -- Show the width options
    ShowWidthOptions()
    -- Show the control point options
    ShowCtrlPtsOptions()
    -- Show the curve code
    ShowCurveCode()
    imgui.End()

    -- Create a Vector based on the mouse's position
    Mouse = Vector(love.mouse.getPosition())
end

function love.draw()

    -- Background image is an image that covers the entire screen.
    -- If it is nil, then the background color is used instead.
    if BGimg then
        love.graphics.draw(BGimg, 0, 0, 0, Window.width / BGimg:getWidth(), Window.height / BGimg:getHeight())
    else
        BackgroundColor:SetBackground()
    end

    curve:Draw(MODE, AddBetween)

    -- code to render imgui
    imgui.Render()
    imgui.love.RenderDrawLists()
    
    -- reset keys pressed
    love.keyboard.keysPressed = {}
    love.mouse.keysPressed = {}
    love.mouse.keysReleased = {}
    love.mouse.scrolled = 0
end

--[[
    Imgui window functions
]]

--- Show options for the code
function ShowBezierTools()
    imgui.Text("Mode")

    imgui.Separator()
    -- Adding a radio button for each mode        
    if imgui.RadioButton_Bool("Add New", MODE == Modes.AddNew) then
        MODE = Modes.AddNew
    end
    imgui.SameLine()
    if imgui.RadioButton_Bool("Add Between", MODE == Modes.AddBetween) then
        MODE = Modes.AddBetween
    end
    imgui.SameLine()
    if imgui.RadioButton_Bool("Edit", MODE == Modes.Edit) then
        MODE = Modes.Edit
    end
    imgui.SameLine()
    if imgui.RadioButton_Bool("Delete", MODE == Modes.Delete) then
        MODE = Modes.Delete
    end

    -- Add delete all button
    if imgui.Button("Delete All") then
        curve = Curve()
    end
    imgui.Spacing()
end

--- Show options for the curve color
function ShowColorOptions()
    imgui.Text("Curve Color")
    imgui.Separator()
    local col_table = curve.color:ToTable()
    local cCol = ffi.new("float[4]", col_table)
    if imgui.ColorEdit4("Curve Color", cCol) then
        for i = 1, 4 do
            col_table[i] = cCol[i - 1]
        end
    end
    curve.color = Color(col_table)
    imgui.Spacing()
end

--- Show options for the background color
function ShowBackgroundColorOptions()
    imgui.Text("Background Color")
    imgui.Separator()
    local col_table = BackgroundColor:ToTable()
    local bCol = ffi.new("float[4]", col_table)
    if imgui.ColorEdit4("Background Color", bCol) then
        for i = 1, 4 do
            col_table[i] = bCol[i - 1]
        end
    end
    BackgroundColor = Color(col_table)
    imgui.Spacing()
end

--- Show options for the background image
function ShowBackgroundImageOptions()
    imgui.Text("Background Image")
    imgui.Separator()
    if BGfilename then
        if imgui.Button("Remove Image") then
            BGfilename = nil
            BGimg = nil
        end
    end
    imgui.Text("Filename: " .. (BGfilename or "None"))
    imgui.Text("Drag and drop an image on the canvas")
    imgui.Spacing()
end

--- Show options for the curve width
function ShowWidthOptions()
    imgui.Text("Width")
    imgui.Separator()
    local w = ffi.new("float[1]", curve.width)
    if imgui.SliderFloat("Width", w, 1, 30) then
        curve.width = w[0]
    end
    imgui.Spacing()
end

--- Show options for the control points
function ShowCtrlPtsOptions()
    imgui.Text("Control Points")
    imgui.Separator()
    -- Adding a checkbox for showing control points
    if imgui.Checkbox("Show Control Points", ffi.new("bool[1]", curve.showCtrlPts)) then
        curve.showCtrlPts = not curve.showCtrlPts
    end
    imgui.Spacing()
end

--- Show the curve code
function ShowCurveCode()
    imgui.Text("Curve Code")
    imgui.Separator()
    if imgui.Button("Copy") then
        love.system.setClipboardText(curve:ToString())
    end
    if imgui.TreeNode_Str("Curve Code") then
        imgui.TextWrapped(curve:ToString())
    end
    imgui.Spacing()
end

--- Callback function for when a file is dropped on the window, which is used to set the background image
function love.filedropped(file)
    local filename = file:getFilename()
    local ext = filename:match("%.%w+$")

    if ext == ".png" then
        BGfilename = filename
        file:open("r")
        fileData = file:read("data")
        local img = love.image.newImageData(fileData)
        BGimg = love.graphics.newImage(img)
        -- resize the window to the size of the image
        Window.width = img:getWidth()
        Window.height = img:getHeight()
        love.window.setMode(img:getWidth(), img:getHeight())
    end
end

--[[
    Callback functions for imgui
]]
function love.keypressed(key)
    imgui.love.KeyPressed(key)
    if not imgui.love.GetWantCaptureKeyboard() then
        love.keyboard.keysPressed[key] = true
    end
end

function love.keyreleased(key, ...)
    imgui.love.KeyReleased(key)
end

function love.mousemoved(x, y, ...)
    imgui.love.MouseMoved(x, y)
end

function love.mousepressed(x, y, key)
    imgui.love.MousePressed(key)
    if not imgui.love.GetWantCaptureMouse() then
        love.mouse.keysPressed[key] = true
    end
end

function love.mousereleased(x, y, key)
    imgui.love.MouseReleased(key)
    if not imgui.love.GetWantCaptureMouse() then
        love.mouse.keysReleased[key] = true
    end
end

function love.textinput(t)
    imgui.love.TextInput(t)
end

function love.keyboard.wasPressed(key)
    return love.keyboard.keysPressed[key]
end

function love.mouse.wasPressed(key)
    return love.mouse.keysPressed[key]
end

function love.mouse.wasReleased(key)
    return love.mouse.keysReleased[key]
end

function love.wheelmoved(x, y)
    imgui.love.WheelMoved(x, y)
    if not imgui.love.GetWantCaptureMouse() then
        love.mouse.scrolled = y
    end
end

function love.quit()
    imgui.love.Shutdown()
end
