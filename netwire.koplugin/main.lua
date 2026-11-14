local Blitbuffer = require("ffi/blitbuffer")
local ButtonDialog = require("ui/widget/buttondialog")
local InfoMessage = require("ui/widget/infomessage")
local Game = require("netwire_game")
local Screen = require("device").screen
local Size = require("ui/size")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")

local NetWire = WidgetContainer:extend{
    name = "netwire",
    is_doc_only = false,
}

local GLYPHS = {
    [0] = "·", "╵", "╴", "└", "╷", "│", "┌", "├",
    "╶", "┘", "─", "┴", "┐", "┤", "┬", "┼",
}

local BOARD_SIZES = {
    {width = 6, height = 4},
    {width = 8, height = 6},
    {width = 10, height = 8},
}

function NetWire:init()
    self.ui.menu:registerToMainMenu(self)
    self.seed = os.time()
end

function NetWire:addToMainMenu(menu_items)
    menu_items.netwire = {
        text = _("NetWire"),
        sorting_hint = "more_tools",
        callback = function()
            self:newGame()
        end,
    }
end

function NetWire:newGame(width, height, mirror)
    self.width = width or self.width or 8
    self.height = height or self.height or 6
    self.mirror = mirror
    if self.mirror == nil then self.mirror = false end
    self.seed = self.seed + 1
    self.game = Game.new(self.width, self.height, self.mirror, self.seed)
    self:showBoard()
end

function NetWire:play(index, direction)
    self.game:rotate(index, direction)
    self:showBoard()
end

function NetWire:showWin()
    self.game.won = true
    UIManager:show(InfoMessage:new{
        text = string.format(_("Network connected in %d moves!\nStarting a new game…"), self.game.moves),
    })
    UIManager:scheduleIn(1.5, function()
        self:newGame()
    end)
end

function NetWire:showSizeMenu()
    local dialog
    local function sizeButton(size)
        return {
            text = string.format("%d × %d", size.width, size.height),
            callback = function()
                UIManager:close(dialog)
                self:newGame(size.width, size.height, self.mirror)
            end,
        }
    end
    dialog = ButtonDialog:new{
        title = _("Board size"),
        buttons = {
            {sizeButton(BOARD_SIZES[1]), sizeButton(BOARD_SIZES[2]), sizeButton(BOARD_SIZES[3])},
            {{
                text = self.mirror and _("Wrap edges: on") or _("Wrap edges: off"),
                callback = function()
                    UIManager:close(dialog)
                    self.mirror = not self.mirror
                    self:newGame(self.width, self.height, self.mirror)
                end,
            }},
        },
    }
    UIManager:show(dialog)
end

function NetWire:showBoard()
    if self.dialog then UIManager:close(self.dialog) end
    local connected = self.game:updatePower()
    if connected == self.width * self.height then
        self:showWin()
        return
    end
    local cellSize = math.floor(math.min(
        (Screen:getHeight() - 240) / self.height,
        Screen:getWidth() / self.width,
        96))
    local rows = {}
    for y = 1, self.height do
        local row = {}
        for x = 1, self.width do
            local index = (y - 1) * self.width + x
            local cell = self.game.cells[index]
            local background = Blitbuffer.COLOR_WHITE
            if index == self.game.source then
                background = Blitbuffer.COLOR_DARK_GRAY
            elseif cell.powered then
                background = Blitbuffer.COLOR_LIGHT_GRAY
            end
            table.insert(row, {
                text = GLYPHS[cell.mask],
                background = background,
                font_size = math.floor(cellSize * 0.75),
                height = cellSize,
                callback = function() self:play(index, 1) end,
                hold_callback = function() self:play(index, -1) end,
            })
        end
        table.insert(rows, row)
    end
    table.insert(rows, {
        {text = _("New game"), callback = function() self:newGame() end},
        {text = _("Size"), callback = function() self:showSizeMenu() end},
        {text = _("Close"), callback = function() UIManager:close(self.dialog) end},
    })
    self.dialog = ButtonDialog:new{
        title = string.format(_("%d moves · %d/%d connected"),
            self.game.moves, connected, self.width * self.height),
        width = cellSize * self.width + 2 * Size.border.window + 2 * Size.padding.button,
        buttons = rows,
    }
    UIManager:show(self.dialog)
end

return NetWire
