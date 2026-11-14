local band = bit.band

local Game = {}
Game.__index = Game

local DIRECTIONS = {
    {dx = 0, dy = -1, bit = 1, opposite = 4},
    {dx = 1, dy = 0, bit = 2, opposite = 8},
    {dx = 0, dy = 1, bit = 4, opposite = 1},
    {dx = -1, dy = 0, bit = 8, opposite = 2},
}

local ROTATE_CW = {0, 2, 4, 6, 8, 10, 12, 14, 1, 3, 5, 7, 9, 11, 13, 15}
local ROTATE_CCW = {0, 8, 1, 9, 2, 10, 3, 11, 4, 12, 5, 13, 6, 14, 7, 15}

local function rotateMask(mask, direction)
    if direction == -1 then
        return ROTATE_CCW[mask + 1]
    end
    return ROTATE_CW[mask + 1]
end

local function shuffledDirections()
    local directions = {1, 2, 3, 4}
    for i = #directions, 2, -1 do
        local j = math.random(i)
        directions[i], directions[j] = directions[j], directions[i]
    end
    return directions
end

function Game.new(width, height, mirror, seed)
    local self = setmetatable({
        width = width,
        height = height,
        mirror = mirror,
        cells = {},
        source = 0,
        moves = 0,
        won = false,
    }, Game)
    math.randomseed(seed)
    for index = 1, width * height do
        self.cells[index] = {mask = 0, powered = false}
    end
    self.source = math.random(width * height)
    self:generate()
    self:scramble()
    return self
end

function Game:neighbor(x, y, direction)
    local nx = x + direction.dx
    local ny = y + direction.dy
    if self.mirror then
        nx = (nx - 1) % self.width + 1
        ny = (ny - 1) % self.height + 1
    elseif nx < 1 or nx > self.width or ny < 1 or ny > self.height then
        return nil
    end
    return (ny - 1) * self.width + nx
end

function Game:generate()
    local visited = {}
    local function visit(index)
        visited[index] = true
        local x = (index - 1) % self.width + 1
        local y = math.floor((index - 1) / self.width) + 1
        for _, directionIndex in ipairs(shuffledDirections()) do
            local direction = DIRECTIONS[directionIndex]
            local other = self:neighbor(x, y, direction)
            if other and not visited[other] then
                self.cells[index].mask = self.cells[index].mask + direction.bit
                self.cells[other].mask = self.cells[other].mask + direction.opposite
                visit(other)
            end
        end
    end
    visit(self.source)
end

function Game:updatePower()
    local queue = {self.source}
    local count = 1
    for _, cell in ipairs(self.cells) do
        cell.powered = false
    end
    self.cells[self.source].powered = true
    local head = 1
    while head <= #queue do
        local index = queue[head]
        head = head + 1
        local x = (index - 1) % self.width + 1
        local y = math.floor((index - 1) / self.width) + 1
        for _, direction in ipairs(DIRECTIONS) do
            if band(self.cells[index].mask, direction.bit) ~= 0 then
                local other = self:neighbor(x, y, direction)
                if other and not self.cells[other].powered and band(self.cells[other].mask, direction.opposite) ~= 0 then
                    self.cells[other].powered = true
                    count = count + 1
                    table.insert(queue, other)
                end
            end
        end
    end
    return count
end

function Game:isSolved()
    return self:updatePower() == self.width * self.height
end

function Game:scramble()
    for _, cell in ipairs(self.cells) do
        local turns = math.random(4) - 1
        for _ = 1, turns do
            cell.mask = rotateMask(cell.mask, 1)
        end
    end
    if self:isSolved() then
        for _, cell in ipairs(self.cells) do
            if cell.mask ~= 0 and cell.mask ~= 5 and cell.mask ~= 10 and cell.mask ~= 15 then
                cell.mask = rotateMask(cell.mask, 1)
                break
            end
        end
        self:updatePower()
    end
end

function Game:rotate(index, direction)
    if self.won then return end
    local cell = self.cells[index]
    cell.mask = rotateMask(cell.mask, direction)
    self.moves = self.moves + 1
    self.won = self:isSolved()
    return self.won
end

return Game
