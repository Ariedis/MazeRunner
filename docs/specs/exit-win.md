# Feature Spec: Exit Discovery & Win Condition

## Overview
The exit is hidden somewhere in the maze. The first player (human or AI) to reach the exit while holding their item wins.

## Exit Properties
- Placed during maze generation (bottom-right quadrant, prefer dead-end)
- Hidden under fog of war until player explores that cell
- Visually distinct from normal cells when revealed (e.g., glowing door)

## Interaction
- **Player has item:** entering exit cell triggers win sequence
- **Player doesn't have item:** message displayed — "You need your item to exit!"
- **AI has item:** AI entering exit triggers player loss

## Win Sequence
1. Brief win animation / fanfare
2. Win screen displays:
   - "You Win!" / "[AI Name] Wins!"
   - Time taken
   - Locations explored
   - Clashes won/lost
   - Size stat final value
3. Buttons: "Play Again" (new game with same settings) / "Main Menu"

## Loss Sequence
- Triggered when any AI reaches exit with their item
- Same stats display but "You Lose" header
- Same buttons

## Edge Cases
- If two AI reach exit on same frame → first processed wins
- Player can still explore after AI wins (optional — or just trigger loss immediately)

## Testing Criteria
- [ ] Exit hidden until explored
- [ ] Exit interaction requires item
- [ ] Win screen shows on player exit with item
- [ ] Loss screen shows on AI exit with item
- [ ] Stats displayed correctly
- [ ] Play Again starts new game with same config
- [ ] Main Menu returns to menu
