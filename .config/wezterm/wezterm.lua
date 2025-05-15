local wezterm = require 'wezterm';
return {
    	color_scheme = 'Gruvbox (Gogh)',
	font = wezterm.font_with_fallback({
		{family="Menlo", weight="Regular"},
		{family="FiraCode Nerd Font", weight="Regular"}
	}),
	send_composed_key_when_left_alt_is_pressed = false,
	font_size = 14.0
}
