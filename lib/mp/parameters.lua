setup_params = function(mp)

  params:add_separator()

  -- Voices
  params:add {
    type = "option",
    id = "output",
    name = "output",
    default = 1,
    options = {
      "audio", "midi", "audio + midi",
      "crow 1-4 trigs", "just friends notes", "just friends shapes"
    },
    action = function(value)
      mp.all_notes_off()
      if value == 4 then
        crow.ii.pullup(true)
        crow.output[2].action = "{to(5,0),to(0,0.25)}"
      elseif value == 5 then
        crow.ii.pullup(true)
        crow.ii.jf.mode(1)
      elseif value == 6 then
        crow.ii.pullup(true)
        crow.ii.jf.mode(0)
      end
    end
  }

  -- norns has 16 midi ports; mods such as nbout append a virtual one
  -- (midi.vports grows to 17), so size the range from the live table.
  local midi_port_count = math.max(16, #midi.vports)

  params:add{
  	type = "number",
  	id = "midi_out_device",
  	name = "midi out device",
    min = 1,
    max = midi_port_count,
    default = 1,
    formatter = function(param)
      local v = param:get()
      local port = midi.vports[v]
      local name = port and port.name
      if name and name ~= "none" then
        return v .. ": " .. name
      end
      return tostring(v)
    end,
    action = function(value)
      local device = midi.connect(value)
      if device then mp.midi_out_device = device end
		end
	}

  params:add{
  	type = "number",
  	id = "midi_out_channel",
  	name = "midi out channel",
    min = 1, max = 16, default = 1,
    action = function(value)
      mp.midi_out_channel = value
    end
  }

  params:add {
    type = "option",
    id = "clock_division",
    name = "clock division",
    options = {"1/4", "1/8", "1/12", "1/16"}
  }


  params:add {
    type = "option",
    id = "trigger_on_press",
    name = "trigger on press",
    options = {"no", "yes"}
  }

end

return setup_params