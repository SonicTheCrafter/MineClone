# API
## Groups
MineClone 2 makes very extensive use of groups. Making sure your items and objects have the correct group memberships is very important.
Groups are explained in `GROUPS.md`.

## Mod naming convention
Mods mods in MineClone 2 follow a simple naming convention: Mods with the prefix “`mcl_`” are specific to MineClone 2, although they may be based on an existing standalone. Mods which lack this prefix are *usually* verbatim copies of a standalone mod. Some modifications may still have been applied, but the APIs are held compatible.

## Adding items
### Special fields

All nodes can have these fields:

* `_mcl_hardness`: Hardness of the block, ranges from 0 to infinity (represented by -1). Determines digging times. Default: 0
* `_mcl_blast_resistance`: How well this block blocks and resistst explosions. Default: 0

Use the `mcl_sounds` mod for the sounds.

## APIs
A lot of things are possible by using one of the APIs in the mods. Note that not all APIs are documented yet, but it is planned. The following APIs should be more or less stable but keep in mind that MineClone 2 is still unfinished. All directory names are relative to `mods/`

### Items
* Doors: `ITEMS/mcl_doors`
* Fences and fence gates: `ITEMS/mcl_fences`
* Walls: `ITEMS/mcl_walls`
* Beds: `ITEMS/mcl_beds`
* Buckets: `ITEMS/mcl_buckets`

## Mobs
* Mobs: `ENTITIES/mods`

MineClone 2 uses Mobs Redo [`mobs`] by TenPlus1, a very powerful mod for adding mods of various types.
There are modificiations from the original mod for MineClone 2 compability. Some items have been removed or moved to other mods, but the API is identical.
You can add your own mobs, spawn eggs and spawning rules with this mod.
API documnetation is included in `ENTITIES/mobs/api.txt`.

### Help
* Item help texts: `HELP/doc/doc_items`
* Low-level help entry and category framework: `HELP/doc/doc`
* Support for lookup tool (required for all entities): `HELP/doc/doc_identifier`

### HUD
* Statbars: `HUD/hudbars`

### Utility APIs
* Select random treasures: `CORE/mcl_loot`
* Get flowing direction of liquids: `CORE/flowlib`
* `on_walk_over` callback for nodes: `CORE/walkover` 
* Get node names close to player (to reduce constant querying): `PLAYER/mcl_playerinfo`

### Unstable APIs
These APIs may be subject to change in future. You could already use these APIs but there will probably be breaking changes in the future, or the API is not as fleshed out as it should be. Use at your own risk!

* Panes (like glass panes and iron bars): `ITEMS/xpanes`
* Slabs and stairs: `ITEM/mcl_stairs` **and** `ITEMS/mcstair`
* `_on_ignite` callback: `ITEMS/mcl_fire`
* Farming: `ITEMS/mcl_farming`
* Other mods not listed above

### Planned APIs

* Flowers
* Saplings and trees
* Custom banner patterns
* Custom dimensions
* Custom portals
* Music discs
* Dispenser and dropper support
* Proper sky and weather APIs
* Explosion API
