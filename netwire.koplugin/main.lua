local Blitbuffer = require("ffi/blitbuffer")
local ButtonDialog = require("ui/widget/buttondialog")
local ConfirmBox = require("ui/widget/confirmbox")
local Game = require("netwire_game")
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

function NetWire:newGame(width, mirror)
    self.width = width or self.width or 6
    self.mirror = mirror
    if self.mirror == nil then self.mirror = false end
    self.seed = self.seed + 1
    self.game = Game.new(self.width, self.width, self.mirror, self.seed)
    self:showBoard()
end

function NetWire:play(index, direction)
    local won = self.game:rotate(index, direction)
    self:showBoard()
    if won then
        UIManager:show(ConfirmBox:new{
            text = string.format(_("Network connected in %d moves!"), self.game.moves),
            ok_text = _("New game"),
            ok_callback = function() self:newGame() end,
        })
    end
end

function NetWire:showSizeMenu()
    local dialog
    local function sizeButton(size)
        return {
            text = string.format("%d × %d", size, size),
            callback = function()
                UIManager:close(dialog)
                self:newGame(size, self.mirror)
            end,
        }
    end
    dialog = ButtonDialog:new{
        title = _("Board size"),
        buttons = {
            {sizeButton(4), sizeButton(6), sizeButton(8)},
            {{
                text = self.mirror and _("Wrap edges: on") or _("Wrap edges: off"),
                callback = function()
                    UIManager:close(dialog)
                    self.mirror = not self.mirror
                    self:newGame(self.width, self.mirror)
                end,
            }},
        },
    }
    UIManager:show(dialog)
end

function NetWire:showBoard()
    if self.dialog then UIManager:close(self.dialog) end
    local rows = {}
    for y = 1, self.width do
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
                font_size = 32,
                height = 64,
                callback = function() self:play(index, 1) end,
                hold_callback = function() self:play(index, -1) end,
            })
        end
        table.insert(rows, row)
    end
    table.insert(rows, {
        {
            text = _("New game"),
            callback = function() self:newGame() end,
        },
        {
            text = _("Size"),
            callback = function() self:showSizeMenu() end,
        },
        {
            text = _("Close"),
            callback = function() UIManager:close(self.dialog) end,
        },
    })
    self.dialog = ButtonDialog:new{
        title = string.format(_("NetWire · %d moves · tap ↻ / hold ↺"), self.game.moves),
        buttons = rows,
    }
    UIManager:show(self.dialog)
end

return NetWire
