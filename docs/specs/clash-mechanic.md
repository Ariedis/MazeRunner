# Feature Spec: Clash Mechanic

## Overview
When two characters collide in the maze, a clash is triggered. A dice roll + size stat determines the winner. The loser must complete a penalty task.

## Trigger
- Collision detection between any two characters (player-AI or AI-AI)
- Both characters freeze during clash resolution
- Game pauses (or just the involved characters freeze)

## Resolution
1. Each participant rolls a d6 (random 1-6)
2. Each participant adds their current Size stat to the roll
3. Higher total wins
4. **Tie:** re-roll (keep rolling until resolved)

## Clash UI (Player Involved)
1. Screen overlay with both characters displayed
2. Dice roll animation for both sides
3. Size stat shown next to each character
4. Totals calculated and displayed
5. Winner/Loser declared with visual flair
6. If player loses → penalty task overlay (see clash-task.md)
7. If player wins → brief "Victory!" message, resume play

## Clash (AI vs AI)
- Resolved instantly (no overlay for player)
- Loser AI enters PENALTY state for appropriate duration
- Optional: notification in HUD — "[AI-A] clashed with [AI-B]"

## Post-Clash
- Winner resumes movement immediately
- Loser enters penalty state (see clash-task.md)
- Characters are briefly separated (pushed apart 1-2 cells to prevent immediate re-clash)

## Edge Cases
- **Clash during task overlay:** should not happen (player is at a location, not moving)
- **Multiple simultaneous clashes:** queue and resolve sequentially
- **Clash near exit:** resolve clash first, then check exit condition

## Testing Criteria
- [ ] Collision triggers clash between player and AI
- [ ] Dice rolls are random (1-6 range)
- [ ] Size stat adds to roll correctly
- [ ] Higher total wins
- [ ] Ties cause re-roll
- [ ] Winner resumes, loser enters penalty
- [ ] Characters separated after clash
- [ ] AI-AI clashes resolve without player overlay
- [ ] No double-clash on separation
