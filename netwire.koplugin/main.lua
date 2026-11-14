local Blitbuffer = require("ffi/blitbuffer")
local Button = require("ui/widget/button")
local ButtonDialog = require("ui/widget/buttondialog")
local ButtonTable = require("ui/widget/buttontable")
local CenterContainer = require("ui/widget/container/centercontainer")
local ConfirmBox = require("ui/widget/confirmbox")
local Font = require("ui/font")
local FrameContainer = require("ui/widget/container/framecontainer")
local Game = require("netwire_game")
local Geom = require("ui/geometry")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local Screen = require("device").screen
local Size = require("ui/size")
local TextBoxWidget = require("ui/widget/textboxwidget")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
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
    self:checkWin()
end

function NetWire:checkWin()
    if not self.game.won and not self.game:isSolved() then return end
    self.game.won = true
    UIManager:show(ConfirmBox:new{
        text = string.format(_("Network connected in %d moves!"), self.game.moves),
        ok_text = _("New game"),
        ok_callback = function() self:newGame() end,
    })
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
    local cellSize = math.floor(math.min(
        Screen:getWidth() / self.width,
        (Screen:getHeight() - 180) / self.height,
        96))
    local grid = VerticalGroup:new{}
    for y = 1, self.height do
        local row = HorizontalGroup:new{}
        for x = 1, self.width do
            local index = (y - 1) * self.width + x
            local cell = self.game.cells[index]
            local background = Blitbuffer.COLOR_WHITE
            if index == self.game.source then
                background = Blitbuffer.COLOR_DARK_GRAY
            elseif cell.powered then
                background = Blitbuffer.COLOR_LIGHT_GRAY
            end
            table.insert(row, Button:new{
                text = GLYPHS[cell.mask],
                background = background,
                width = cellSize,
                height = cellSize,
                bordersize = 0,
                margin = 0,
                padding = 0,
                avoid_text_truncation = false,
                text_font_size = cellSize,
                text_font_bold = false,
                callback = function() self:play(index, 1) end,
                hold_callback = function() self:play(index, -1) end,
            })
        end
        table.insert(grid, row)
    end
    local boardWidth = cellSize * self.width
    local content = VerticalGroup:new{
        TextBoxWidget:new{
            text = string.format(_("NetWire · %d moves · %d/%d connected · tap ↻ / hold ↺"),
                self.game.moves, connected, self.width * self.height),
            face = Font:getFace("infofont", 20),
            width = boardWidth,
        },
        VerticalSpan:new{width = Size.padding.default},
        grid,
        VerticalSpan:new{width = Size.padding.default},
        ButtonTable:new{
            width = boardWidth,
            buttons = {{
                {text = _("New game"), callback = function() self:newGame() end},
                {text = _("Size"), callback = function() self:showSizeMenu() end},
                {text = _("Close"), callback = function() UIManager:close(self.dialog) end},
            }},
        },
    }
    self.dialog = FrameContainer:new{
        width = Screen:getWidth(),
        height = Screen:getHeight(),
        background = Blitbuffer.COLOR_WHITE,
        bordersize = 0,
        padding = 0,
        CenterContainer:new{
            dimen = Geom:new{x = 0, y = 0, w = Screen:getWidth(), h = Screen:getHeight()},
            content,
        },
    }
    UIManager:show(self.dialog)
end

return NetWire
