# NetWire for KOReader

A NetWalk-style puzzle for Kobo e-readers. Rotate the tiles to connect every wire to the power source.

## Features

- Randomly generated, always solvable boards
- 4×4, 6×6, and 8×8 board sizes
- Optional wrap-around edges
- Tap to rotate clockwise, long-press to rotate counterclockwise
- Powered tiles are highlighted as you connect them
- Move counter and win detection

## Installation

Copy `netwire.koplugin` into the `plugins` directory of your KOReader installation:

```text
.adds/koreader/plugins/netwire.koplugin/
```

Restart KOReader, then open **More tools → NetWire**.

## Controls

- **Tap:** rotate a tile clockwise
- **Long-press:** rotate it counterclockwise
- **New game:** generate a new board
- **Size:** choose the board size or toggle wrap-around edges

The dark-gray tile is the power source. Light-gray tiles are connected to it. Connect every tile to win.
