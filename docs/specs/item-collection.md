# Feature Spec: Item Collection

## Overview
Each player has one specific item they must find. Items are purely cosmetic/thematic — no gameplay stat effects. Players select their item in the New Game screen.

## Item Data
```
Item:
  - id: String
  - name: String         # e.g., "Golden Key", "Crystal Orb"
  - icon: Texture2D      # asset image for display
  - is_custom: bool
```

## Collection Rules
- Player's item is hidden at exactly one location in the maze
- When a task is completed at that location, the item is revealed as the player's
- Item is automatically added to player's inventory
- HUD shows item indicator (top-right of portrait)
- Player can now head to exit to win

## Non-Player Items at Locations
- **Opponent's item:** "This item belongs to [opponent name]." Left at location for that opponent.
- **Size increaser:** "You found a size boost!" → Player's size stat +1 (cap at 10)

## Default Items
Bundle a starter set:
- Golden Key
- Crystal Orb
- Ancient Scroll
- Dragon Scale
- Phoenix Feather
- (More can be added)

## Custom Items
- Added via Settings screen
- Name + image asset
- Appear in New Game item selector alongside defaults

## Testing Criteria
- [ ] Player's item placed at one location per game
- [ ] Collection triggers HUD indicator
- [ ] Opponent items left for opponent
- [ ] Size increaser applies +1, capped at 10
- [ ] Custom items display correctly in game
- [ ] Item state saves/loads correctly
