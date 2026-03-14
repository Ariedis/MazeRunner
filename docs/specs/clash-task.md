# Feature Spec: Clash Penalty Task (Loser)

## Overview
The clash loser must complete a physical task. The task difficulty is scaled by the winner's Size and Energy stats.

## Default Penalty Task
**Exercise:** Bicep curls — 10 reps

### Weight Scaling (based on winner's Size stat)
| Winner Size | Weight |
|-------------|--------|
| 1-3 | 1kg |
| 4-7 | 2kg |
| 8-10 | 3kg |

### Speed Scaling (based on winner's Energy stat)
| Winner Energy | Speed Instruction |
|---------------|-------------------|
| >80% | "Do them QUICKLY" |
| 50%-80% | "Do them at normal speed" |
| <50% | "Do them SLOWLY" |

## Penalty Overlay UI
1. Display exercise name
2. Display reps count
3. Display weight requirement
4. Display speed instruction
5. Timer for estimated completion:
   - Quickly: 15 seconds
   - Normal: 25 seconds
   - Slowly: 40 seconds
6. "Done" button (active after timer)

## Loser State During Penalty
- Character is frozen (cannot move)
- Displayed with visual penalty indicator (e.g., red outline, sweat drops)
- Energy does NOT regen during penalty
- Other characters can pass by freely (no re-clash)

## AI as Loser
- AI enters PENALTY state
- AI waits for the same duration as the timer
- After timer, AI resumes previous state

## Custom Penalty Tasks
- Users can add custom penalty tasks via Settings
- Custom tasks can specify: exercise name, reps, weight tiers, speed descriptions
- Custom tasks stored in user data directory

## Testing Criteria
- [ ] Penalty displays correct weight for winner's size bracket
- [ ] Penalty displays correct speed for winner's energy bracket
- [ ] Timer matches speed tier (15s/25s/40s)
- [ ] "Done" button disabled until timer completes
- [ ] Loser frozen during penalty
- [ ] Energy does not regen during penalty
- [ ] AI penalty duration matches timer
- [ ] Custom penalty tasks load and display correctly
- [ ] Boundary values: size=3 gets 1kg, size=4 gets 2kg, energy=80% gets "normal"
