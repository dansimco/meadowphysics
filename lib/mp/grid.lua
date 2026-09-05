-- Meadowphysics grid ops

local g = grid.connect()
local grid = {}
local glyphs = {}
local voice_count = 8

-- monobright grids (40h, series) only light leds with level > 7, so the
-- 1..4 levels used here never show. when enabled, levels >= 3 (playhead,
-- selection, status, glyphs) become full and dim hints/ranges become off.
local monobright = false
local MONO_ON_THRESHOLD = 3

-- Serial prefixes of grids without variable brightness. Monome serials are
-- model-prefixed: the 40h series and the pre-2011 m64/m128/m256 walnut and
-- greyscale editions are all monobright. Varibright grids (2011+) report
-- m1000xxx / m360xxx style serials, so anything unmatched is assumed
-- varibright and can be corrected with the "use monobright grid" param.
-- The m64/m128/m256 patterns require the hyphen the pre-2011 editions use;
-- wrongly flattening a varibright grid is worse than missing a monobright
-- one, which is one param away from being fixed.
local MONOBRIGHT_SERIAL_PATTERNS = {
  "^m40h",     -- 40h series
  "^m64%-%d",  -- 64 (walnut / greyscale)
  "^m128%-%d", -- 128 (walnut / greyscale)
  "^m256%-%d", -- 256 (walnut / greyscale)
  "^m0000",    -- early 40h-era serials
}

-- Does this grid's serial/name match a known monobright model?
-- Accepts a vport or a raw device; serial lives on the underlying .device,
-- the vport only carries a name of the form "<friendly name> <serial>".
function grid.detect_monobright(device)
  if not device then return false end
  local dev = device.device or device
  local serial = tostring(dev.serial or device.serial or ""):lower()
  local name = tostring(dev.name or device.name or ""):lower()
  for _, pattern in ipairs(MONOBRIGHT_SERIAL_PATTERNS) do
    if serial:match(pattern) or name:match(pattern) then return true end
    -- the name carries the serial appended, so also look for the model
    -- anywhere in it, not only at the start
    if name:match("%f[%w]" .. pattern:gsub("^%^", "")) then return true end
  end
  return false
end

-- Serial and name as the detector sees them, for troubleshooting from the
-- maiden repl: print(include("meadowphysics/lib/mp/grid").identify())
function grid.identify()
  local dev = g.device or g
  return string.format("serial=%q name=%q %dx%d -> %s",
    tostring(dev.serial or ""), tostring(dev.name or g.name or ""),
    tonumber(g.cols) or 0, tonumber(g.rows) or 0,
    grid.detect_monobright(g) and "monobright" or "varibright")
end

-- Apply the "use monobright grid" param: 1 = auto (detect), 2 = no, 3 = yes
function grid:set_monobright(setting)
  if setting == 2 then
    monobright = false
  elseif setting == 3 then
    monobright = true
  else
    monobright = grid.detect_monobright(g)
  end
end

function grid:is_monobright()
  return monobright
end

-- Grids attach asynchronously, so when the param is first applied g.device
-- is usually still nil and auto resolves to varibright. Re-run detection
-- whenever the attached device changes identity. Called from draw(), which
-- runs every clock tick, so this self-corrects right after the grid appears.
function grid:poll_monobright()
  local dev = g.device
  local id = dev and (dev.serial or dev.name) or nil
  if id ~= self._detected_device_id then
    self._detected_device_id = id
    local setting = (params and params.lookup and params.lookup["monobright"])
      and params:get("monobright") or 1
    self:set_monobright(setting)
  end
end

local function led(x, y, l)
  if monobright then
    l = (l >= MONO_ON_THRESHOLD) and 15 or 0
  end
  g:led(x, y, l)
end

-- local rule_icons = {
--   {0,0,0,0,0,0,0,0},-- o
--   {0,24,24,126,126,24,24,0}, -- +
--   {0,0,0,126,126,0,0,0}, -- -
--   {0,96,96,126,126,96,96,0}, -- >
--   {0,6,6,126,126,6,6,0}, -- <
--   {0,102,102,24,24,102,102,0}, -- * rnd
--   {0,120,120,102,102,30,30,0}, -- <> up/down
--   {0,126,126,102,102,126,126,0} -- [] sync2 = 12
-- }

local function base_lighting(mp)
  for i = 1, #mp.voices do
    led(1, i,  1)
    led(3, i,  1)
    led(4, i,  1)
    led(6, i,  1)
    led(7, i,  1)
  end
end


function grid:draw(mp)
  self:poll_monobright()
  g:all(0)

  if(mp.focus == "RESETS") then
    base_lighting(mp)
    -- Show status of all voices
    for i = 1, #mp.voices do
      voice = mp.voices[i]
      if (params:get(i.."_type") == 1) then
        led(6, i,  4)
      else
        led(7, i,  4)
      end
      if (voice.is_playing) then
        led(3, i,  4)
      end
      led(8 + params:get(i.."_clock_division_high"), i,  4)
      for div_i = params:get(i.."_clock_division_low"), params:get(i.."_clock_division_high") do
        led(div_i+8, i,  2)
      end
      led(8 + voice.current_clock_division, i,  4)
    end
    -- Light up the focused voice
    led(1, mp.state.selected_voice,  4)
    -- Show all the voices targeted by this voice
    for ti = 1, voice_count do
      if (params:get(mp.state.selected_voice .. "_reset_" .. ti) == 2) then
        led(4, ti,  4)
      end
      if params:get(ti .. "_running") == 2 then
        led(3, ti,  4)
      end
    end
  end

  -- just show standard ui for the other pages for now
  if (mp.focus == "HOME" or mp.focus == "ALT" or mp.focus == "CONFIG" or mp.focus == "TIME") then
	  for i = 1, #mp.voices do
	    local voice = mp.voices[i]
      -- show cycle range
      for ci = voice.get("range_low"), voice.get("range_high") do 
        led(ci, i,  2)
      end
      -- show playhead
      if voice.isRunning() then
  	    led(voice.current_step, i,  4)
      end
	  end
	end

  if (mp.focus == "RULES") then
    base_lighting(mp)

    -- Light up the focused voice
    led(1, mp.state.selected_voice,  4)
    local rule = params:get(mp.state.selected_voice .. "_rule")

    -- Draw the rule glyph
    local glyph = glyphs[rule]
    for yi = 1, 8 do
      for xi = 1, 10 do
        if(glyph[yi][xi] == 1) then
          led(xi+8, yi,  3)
        end
      end
    end

    -- Draw rule target/application indicator
    led(5,params:get(mp.state.selected_voice .. "_rule_target"),3)
    led(6,params:get(mp.state.selected_voice .. "_rule_target"),3)
    led(7,params:get(mp.state.selected_voice .. "_rule_target"),3)
    -- show rule target mode
    local rule_application = params:get(mp.state.selected_voice .. "_rule_application")
    led(4 + rule_application,params:get(mp.state.selected_voice .. "_rule_target"), 8)

end
  g:refresh()
end

glyphs[1] = {
  {0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0}
}



glyphs[2] = {
  {0,0,0,0,0,0,0,0},
  {0,0,0,1,1,0,0,0},
  {0,0,0,1,1,0,0,0},
  {0,1,1,1,1,1,1,0},
  {0,1,1,1,1,1,1,0},
  {0,0,0,1,1,0,0,0},
  {0,0,0,1,1,0,0,0},
  {0,0,0,0,0,0,0,0}
}

glyphs[3] ={
  {0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0},
  {0,1,1,1,1,1,1,0},
  {0,1,1,1,1,1,1,0},
  {0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0}
}

glyphs[4] ={
  {0,0,0,0,0,0,0,0},
  {0,0,0,0,0,1,1,0},
  {0,0,0,0,0,1,1,0},
  {0,1,1,1,1,1,1,0},
  {0,1,1,1,1,1,1,0},
  {0,0,0,0,0,1,1,0},
  {0,0,0,0,0,1,1,0},
  {0,0,0,0,0,0,0,0}
}

glyphs[5] ={
  {0,0,0,0,0,0,0,0},
  {0,1,1,0,0,0,0,0},
  {0,1,1,0,0,0,0,0},
  {0,1,1,1,1,1,1,0},
  {0,1,1,1,1,1,1,0},
  {0,1,1,0,0,0,0,0},
  {0,1,1,0,0,0,0,0},
  {0,0,0,0,0,0,0,0}
}

glyphs[6] ={
  {0,0,0,0,0,0,0,0},
  {0,1,1,0,0,1,1,0},
  {0,1,1,0,0,1,1,0},
  {0,0,0,1,1,0,0,0},
  {0,0,0,1,1,0,0,0},
  {0,1,1,0,0,1,1,0},
  {0,1,1,0,0,1,1,0},
  {0,0,0,0,0,0,0,0}
}

glyphs[7] ={
  {0,0,0,0,0,0,0,0},
  {0,0,0,1,1,1,1,0},
  {0,0,0,1,1,1,1,0},
  {0,1,1,0,0,1,1,0},
  {0,1,1,0,0,1,1,0},
  {0,1,1,1,1,0,0,0},
  {0,1,1,1,1,0,0,0},
  {0,0,0,0,0,0,0,0}
}

glyphs[8] ={
  {0,0,0,0,0,0,0,0},
  {0,1,1,1,1,1,1,0},
  {0,1,1,1,1,1,1,0},
  {0,1,1,0,0,1,1,0},
  {0,1,1,0,0,1,1,0},
  {0,1,1,1,1,1,1,0},
  {0,1,1,1,1,1,1,0},
  {0,0,0,0,0,0,0,0}
}

return grid
