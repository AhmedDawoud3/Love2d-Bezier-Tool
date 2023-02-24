Curve = Class:extend("Curve")

function Curve:new()
    self.points = {}
    self.mouseContralling = false
    self.count = 0
    self.color = Color("#F9B775")
    self.width = 10
    self.showCtrlPts = true
end

function Curve:AddPointBetween(x, y, first, second)
    table.insert(self.points, first * 2 + 1, x)
    table.insert(self.points, first * 2 + 2, y)
    self.curve:insertControlPoint(x, y, first + 1)
    self.count = self.curve:getControlPointCount()
end

function Curve:AddPoint(x, y)
    table.insert(self.points, x)
    table.insert(self.points, y)
    if #self.points >= 4 then
        self:GenerateCurve()
    end
end

function Curve:GenerateCurve(index)
    if not self.curve then
        self.curve = love.math.newBezierCurve(self.points)
    else
        self.curve:insertControlPoint(self.points[#self.points - 1], self.points[#self.points], self.count + 1)
    end
    self.count = self.curve:getControlPointCount()
end

function Curve:EditPoint(x, y)
    for i = 1, self.count do
        local cx, cy = self.curve:getControlPoint(i)
        if x - 10 < cx and cx < x + 10 and y - 10 < cy and cy < y + 10 then
            self.mouseContralling = i
            return
        end
    end
end

function Curve:DeletePoint(x, y)
    if self.count <= 2 then
        return
    end
    for i = 1, self.count do
        local cx, cy = self.curve:getControlPoint(i)
        if x - 10 < cx and cx < x + 10 and y - 10 < cy and cy < y + 10 then
            self.curve:removeControlPoint(i)
            self.count = self.curve:getControlPointCount()
            return
        end
    end
end

function Curve:Draw(mode, between)
    local betweenControl = between or {}
    if love.mouse.wasReleased(1) then
        self.mouseContralling = false
    end
    if self.mouseContralling then
        self.curve:setControlPoint(self.mouseContralling, love.mouse.getX(), love.mouse.getY())
        self.points[self.mouseContralling * 2 - 1] = love.mouse.getX()
        self.points[self.mouseContralling * 2] = love.mouse.getY()
    end

    love.graphics.setLineWidth(self.width)
    love.graphics.setPointSize(10)
    local polyTable = {}
    if self.count >= 2 then
        self.color:Set()
        love.graphics.line(self.curve:render())
        if self.showCtrlPts then
            for i = 1, self.count do
                if mode == Modes.Edit and self.mouseContralling and self.mouseContralling == i then
                    RED_E:Set()
                elseif mode == Modes.AddBetween and (betweenControl[1] == i or betweenControl[2] == i) then
                    GREEN_B:Set()
                else
                    BLUE_A:Set()
                end
                local x, y = self.curve:getControlPoint(i)
                table.insert(polyTable, x)
                table.insert(polyTable, y)
                love.graphics.points(x, y)
            end
            Color.Reset()
            if self.count > 2 then
                love.graphics.setLineWidth(2)
                GRAY_A:Set(0.5)
                for i = 1, self.count - 1 do
                    local x1, y1 = self.curve:getControlPoint(i)
                    local x2, y2 = self.curve:getControlPoint(i + 1)
                    love.graphics.line(x1, y1, x2, y2)
                end
            end
        end
    else
        for i = 1, #self.points, 2 do
            love.graphics.points(self.points[i], self.points[i + 1])
        end
    end
    Color.Reset()
end

function Curve:ToString()
    local str = "love.math.newBezierCurve(\n{"
    for i = 1, #self.points do
        str = str .. self.points[i]
        if i ~= #self.points then
            str = str .. ", "
            if i % 2 == 0 then
                str = str .. "\n"
            end
        end
    end
    str = str .. "}\n)"
    return str
end
