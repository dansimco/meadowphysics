# meadowphysics(norns)
https://monome.org/docs/modular/meadowphysics/

https://monome.org/docs/modular/ansible/

--
--   m e a d o w p h y s i c s
--
--   a grid-enabled
--   rhizomatic
--   cascading counter
--
--
--   *----
--        *-----
--            *---
--      *-----
--
--

## monobright grids

Monobright hardware (40h, pre-2011 series 64/128/256) only lights leds above
a brightness threshold, so the dim levels this script draws never show.
PARAMS > `use monobright grid` defaults to `auto`, which
detects those models from the grid's serial. If detection misses your grid,
set it to `yes`; `no` forces varibright drawing. In monobright mode the
playhead, selection, status and rule glyphs are drawn at full brightness and
dim hints/ranges are turned off. Varibright drawing is otherwise untouched.
