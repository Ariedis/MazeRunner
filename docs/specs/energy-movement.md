# Feature Spec: Energy & Movement

## Overview
Movement costs energy. When energy is depleted, the player moves at half speed. Standing still regenerates energy.

## Movement
- Player moves through maze corridors using arrow keys / WASD
- Movement is continuous (not turn-based)
- Base movement speed: TBD pixels/second (suggest 150 px/s full, 75 px/s half)
- Player cannot move through walls

## Energy Drain
- Energy decreases at a constant rate while the player is actively moving
- Suggested rate: **1% per second of movement** (tunable)
- Energy does not drain while stationary
- Energy does not drain during overlays (task, clash)

## Energy Regeneration
- Energy increases while the player is completely stationary
- Suggested rate: **2% per second** (tunable)
- Regen does not occur while moving
- Regen does not occur during overlays (task, clash)
- Caps at 100%

## Speed States
- **Full speed:** energy > 0%
- **Half speed:** energy = 0%
- Transition is immediate when crossing the threshold
- Speed returns to full as soon as energy > 0% (from regen)

## Strategic Implications
- Players must balance exploration speed with energy conservation
- Standing still near a location to regen before a potential clash is a valid strategy
- Half-speed players are more vulnerable to clashes (opponents catch up)

## Testing Criteria
- [x] Energy decreases only while moving
- [x] Energy increases only while stationary
- [x] Speed halves at exactly 0% energy
- [x] Speed restores when energy > 0%
- [x] Energy doesn't change during overlays (game paused via is_paused flag)
- [x] Drain/regen rates are configurable for balancing (ENERGY_DRAIN / ENERGY_REGEN constants in Enums)
