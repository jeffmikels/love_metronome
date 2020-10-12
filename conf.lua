-- Configuration
function love.conf(t)
	t.title = "Jeff's Metronome" -- The title of the window the game is in (string)
	t.version = "11.3"         -- The LÖVE version this game was made for (string)
	t.window.width = 640
	t.window.height = 200
	t.window.borderless = false
	t.window.fullscreen = false
	t.window.fullscreentype = 'desktop'

	t.modules.joystick = false
	t.modules.physics = false
	t.modules.mouse = true

	-- For Windows debugging
	t.console = false
end
