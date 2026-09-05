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

## midi out and nbout

`midi out device` lists every norns midi port by number and name, including
the virtual `nb` port added by the [nbout](https://github.com/sixolet/nbout)
mod. Pick the port named `nb` (or assign `nb` to a slot in SYSTEM > DEVICES >
MIDI and pick that slot) and set `output` to `midi`. nbout only listens on
midi channel 1, so leave `midi out channel` at 1 and per-voice channels at
their default.
