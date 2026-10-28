# Map walk helper (Gaia Family server)

`reach.lua` walks the map like a player would, for self-tests: which squares
can be reached from a starting point, and which closed doors stop the way.
Used to check that a quest place, NPC or boss room can really be reached on
our map before a quest is built on it.

In a self-test (see `tools/family/selftest.sh`), inside `run()`:

```lua
local Reach = dofile("tools/family/reach/reach.lua")
local r = Reach.walk({ { 33213, 32454, 7 } }, {
	box = { 32950, 32150, 33400, 32600 }, -- x1, y1, x2, y2 (all floors)
	openAids = { [45150] = true },        -- quest doors to treat as open
})
print(r.count, r.has(33123, 32239, 12))
for _, d in ipairs(r.closed) do print(d.x, d.y, d.z, d.id, d.aid) end
```

It follows walking (8 directions), stairs and holes, ladders, rope spots,
sewer grates, holes a shovel opens (loose stone piles), and teleports with a
destination. Doors with an action or unique id are closed unless listed in
`openAids` (or `openAll = true`). House squares are never entered. Scripted
teleports (a quest step that moves the player) are not followed: add the
place they lead to as another start.

Speed: a city area takes a few seconds; the whole world (all temples) about
8 minutes, so always pass a `box`.
