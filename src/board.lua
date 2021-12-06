local colors = require('colors')
local utils = require('utils')

local TIE, CELL_X, CELL_O = 0, 1, 2
local Board = {}

function Board:new(size, space, offset)
    obj = setmetatable({}, self)
    self.__index = self
    obj:init(size, space, offset)
    return obj
end

function Board:init(size, space, offset)
    self.size = size or 3
    self.space = space or 100
    self.offset = offset or {x = 0, y = 0}
    self.one_tenth_space = space * 0.1
    self.half_space = space / 2
    self.circle_radius = space / 2.5
    self.separators = {}

    for i = 1, (self.size - 1) do
        local a = self.space * size
        local b = self.space * i

        self.separators[i] = {
            {
                x = a + self.offset.x,
                y = b + self.offset.y
            },
            {
                x = b + self.offset.x,
                y = a + self.offset.y,
            }
        }
    end

    self:reset_cells()
end

function Board:reset_cells()
    self.cells = {}

    for i = 1, self.size do
        self.cells[i] = {}
    end
end

function Board:get_cell(x, y)
    return self.cells[x][y]
end

function Board:set_cell(x, y, val)
    self.cells[x][y] = val
end

function Board:has_empty_cells()
    for x = 1, self.size do
        for y = 1, self.size do
            if self.cells[x][y] == nil then
                return true
            end
        end
    end
    return false
end

function Board:get_empty_cells()
    local empty_cells = {}
    for x = 1, self.size do
        for y = 1, self.size do
            if self.cells[x][y] == nil then
                table.insert(empty_cells, {x = x, y = y})
            end
        end
    end
    return empty_cells
end

function Board:get_cell_on_point(x, y)
    local rect_y = self.offset.y
    for i = 1, self.size do
        local rect_x = self.offset.x
        for j = 1, self.size do
            if utils.is_point_in_square(x, y, rect_x, rect_y, self.space, self.space) then
                return j, i
            end
            rect_x = rect_x + self.space
        end
        rect_y = rect_y + self.space
    end
end

function Board:draw()
    self:draw_separators()
    self:draw_cells()
end

function Board:draw_separators()
    for i = 1, #self.separators do
        local sep = self.separators[i]

        -- Horizontal lines _
        love.graphics.line(self.offset.x, sep[1].y, sep[1].x, sep[1].y)

        -- Vertical lines |
        love.graphics.line(sep[2].x, self.offset.y, sep[2].x, sep[2].y)
    end
end

function Board:draw_cells()
    for x = 1, self.size do
        for y = 1, self.size do
            local bs = self.cells[x][y]
            if bs == CELL_X then
                self:draw_cross(x, y)
            elseif bs == CELL_O then
                self:draw_circle(x, y)
            end
        end
    end
end

function Board:draw_cross(x, y)
    love.graphics.setColor(colors.RED)

    -- /
    love.graphics.line((x - 1) * self.space + self.one_tenth_space + self.offset.x,
                       y * self.space - self.one_tenth_space + self.offset.y,
                       x * self.space - self.one_tenth_space + self.offset.x,
                       (y - 1) * self.space + self.one_tenth_space + self.offset.y)

    -- \
    love.graphics.line((x - 1) * self.space + self.one_tenth_space + self.offset.x,
                       (y - 1) * self.space + self.one_tenth_space + self.offset.y,
                       x * self.space - self.one_tenth_space + self.offset.x,
                       y * self.space - self.one_tenth_space + self.offset.y)
end

function Board:draw_circle(x, y)
    love.graphics.setColor(colors.BLUE)

    love.graphics.circle('line',
        (x * self.space) - self.half_space + self.offset.x,
        (y * self.space) - self.half_space + self.offset.y,
        self.circle_radius)
end

function Board:get_winner()
    local winner

    for i = 1, self.size do
        local cv, ch, cdl, cdr = 1, 1, 1, 1
        for j = 1, (self.size - 1) do
            -- Diagonal \
            local c1, c2 = self.cells[j][j], self.cells[j + 1][j + 1]
            if c1 == c2 and c1 ~= nil then
                cdl = cdl + 1
            end

            -- Diagonal /
            c1, c2 = self.cells[j][self.size - j + 1], self.cells[j + 1][self.size - j]
            if c1 == c2 and c1 ~= nil then
                cdr = cdr + 1
            end

            -- Vertical
            c1, c2 = self.cells[i][j], self.cells[i][j + 1]
            if c1 == c2 and c1 ~= nil then
                cv = cv + 1
            end

            -- Horizontal
            c1, c2 = self.cells[j][i], self.cells[j+1][i]
            if c1 == c2 and c1 ~= nil then
                ch = ch + 1
            end
        end

        if cv == self.size then
            winner = self.cells[i][1]
        elseif ch == self.size then
            winner = self.cells[1][i]
        elseif cdl == self.size then
            winner = self.cells[1][1]
        elseif cdr == self.size then
            winner = self.cells[self.size][1]
        end

        if winner then
            break
        end
    end

    if winner == nil and not self:has_empty_cells() then
        return TIE
    end

    return winner
end

return {
    Board = Board,
    TIE = TIE,
    CELL_X = CELL_X,
    CELL_O = CELL_O
}
