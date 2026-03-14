# Feature Spec: Task Display & Completion

## Overview
When a player reaches an uncompleted location, a task overlay appears with instructions and media. The player completes the task on the honor system.

## Task Data
```
TaskData:
  - title: String
  - description: String  # e.g., "Plank for 30 seconds"
  - media_path: String   # path to gif/mp4/webm file
  - duration_seconds: int # how long the task takes
```

## Overlay Layout
- **Modal overlay** covering the game (game pauses or continues in background — recommend pause)
- **Title** at top
- **Media** (gif/video) displayed prominently in center
- **Description** text below media
- **Timer** counting down from `duration_seconds`
- **"Done" button** — only clickable after timer reaches 0

## Completion Flow
1. Overlay appears with task details
2. Timer counts down (player does the physical task)
3. When timer hits 0, "Done" button becomes active
4. Player clicks "Done"
5. Item reveal animation/message
6. Overlay closes, game resumes

## Default Tasks
Bundle a set of default tasks with the game:
- "Plank for 30 seconds" (30s)
- "Do 10 push-ups" (20s)
- "Do 20 jumping jacks" (15s)
- "Hold a wall sit for 20 seconds" (20s)
- "Do 15 squats" (20s)
- (More TBD)

## Custom Tasks
- Users add custom tasks via Settings (Phase 11)
- Custom tasks are stored in user data directory as JSON + media files
- Custom tasks are mixed into the task pool alongside defaults
- Media supports: .gif, .mp4, .webm

## AI Task Handling
- AI does not see a task overlay
- AI waits at the location for a simulated duration
- Duration varies by difficulty (Easy: longer, Hard: shorter)

## Testing Criteria
- [ ] Overlay displays title, description, media correctly
- [ ] Timer counts down accurately
- [ ] "Done" button disabled until timer completes
- [ ] Game pauses during overlay
- [ ] Item revealed after "Done" pressed
- [ ] Default tasks load correctly
- [ ] Custom tasks with various media formats display correctly
- [ ] AI simulates task wait without overlay
