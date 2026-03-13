Elemental Garden MVP (Flora Mágica)

A strategic farming and incremental puzzle game prototype developed in **Godot 4**. 

This MVP focuses on a system where the placement of elemental flora directly impacts the economy and growth speed of adjacent plants, creating a dynamic and rewarding game loop.

Core Mechanics:

**-Dynamic Grid System:** A fully code-generated slot system that handles planting, spatial awareness, and prevents overlapping.
**-Elemental Sinergy:** Plants interact with their neighbors based on their elemental types, acting as buff/debuff towers:
**-Water:** Speeds up Earth (+50%), slows down Fire (-50%).
**-Fire:** Increases Luck/Crit chance for Air (+50%).
**-Earth:** Increases Harvest Quality for Water (+50%).
**-Air:** Increases Sell Value for Fire (+50%), decreases Quality for Earth (-50%).
**-Complex Harvesting Math:** RNG-based calculations for multi-drops (Quality) and 2x Gold Crits (Luck), ensuring no values drop below functional thresholds.
**-Incremental Economy:** Players can buy new vases or upgrade global stats (Growing Speed and Irrigation Bonus) with costs that scale exponentially.
**-"Juicy" Visual Feedback:** Implemented dynamic floating text animations (Tweens) to reward the player visually during harvests, especially on Critical hits.

Technical Highlights

**-Language:** GDScript
**-Architecture:** Separation of concerns between the global economy/grid manager (`game.gd`) and individual plant logic (`vase_script.gd`).
**-UI/UX:** Dynamic coloring, slot highlighting during the planting phase, and runtime control node manipulation.

How to Play

1. Buy a new vase using Gold.
2. Select the desired Element (Water, Fire, Earth, or Air).
3. Click on an empty slot to plant.
4. Wait for the timer or click the vase to irrigate and speed up the process.
5. Harvest to gain Gold and plan your next placement to maximize synergies!
