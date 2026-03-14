# Feature Spec: Main Menu & Screens

## Main Menu
### Layout
- Game title/logo at top
- Vertical button stack, centered:
  1. **New Game** → navigates to New Game screen
  2. **Continue** → loads most recent save, starts game (greyed out if no save)
  3. **Load Game** → navigates to Load Game screen
  4. **Settings** → navigates to Settings screen
  5. **Quit** → exits application

## New Game Screen
### Layout
- **Map Size:** toggle or dropdown (Small / Medium / Large)
- **Character Creator:** embedded section (see character-creator.md)
- **Number of Opponents:** number selector (range: 1 to max for map size)
- **AI Difficulty:** one dropdown per opponent (Easy / Medium / Hard)
  - Dynamically shows/hides dropdowns based on opponent count
- **Item Selector:** dropdown or grid of available items (default + custom)
- **Start Game** button — validates all fields, launches game
- **Back** button → returns to Main Menu

## Load Game Screen
### Layout
- List of save slots with metadata:
  - Slot name / number
  - Date/time saved
  - Map size
  - Progress indicator (locations completed / total)
- **Load** button per slot
- **Delete** button per slot (with confirmation dialog)
- **Back** button → Main Menu

## Testing Criteria
- [ ] All menu buttons navigate correctly
- [ ] Continue greyed out when no saves exist
- [ ] Quit exits the application
- [ ] New Game validates before starting (item selected, valid config)
- [ ] AI difficulty dropdowns match opponent count
- [ ] Load Game lists all saves with correct metadata
- [ ] Delete save requires confirmation
- [ ] Back buttons return to correct screens
