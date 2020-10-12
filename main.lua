-- Simple Graphic Metronome
-- local luamidi require ("LuaMidi")
-- local NoteEvent = luamidi.NoteEvent

bpm_bar = {}
master_bar = {}
clicks = {}
subclicks = {}
bpm = 120
max_bpm = 300
subdivision = 1
maintimer = 0
subtimer = 0
maindelay = 60.0/bpm
subdelay = maindelay / subdivision
mainvolume=1
subvolume=0.2
current_click = 0
current_subclick = 0
num_clicks = 5
taps = {}
do_flash = false
paused = false
pendulum = {x = 0, rightward = true}
flash_intensity = 0
flash_fade_rate = 18
enable_flash = true

presets = {}
for i=1,9 do presets[i] = {bpm=120,subdivision=1} end
selected_preset = 1


function love.load(arg)
	-- LOAD FIVE CLICKS
	for i=1,num_clicks do
		clicks[i] = love.audio.newSource('assets/click.wav', 'static')
		clicks[i]:setVolume(mainvolume)
		clicks[i]:setLooping(false)
	end

	for i=1,num_clicks do
		subclicks[i] = love.audio.newSource('assets/click.wav', 'static')
		subclicks[i]:setVolume(subvolume)
		subclicks[i]:setLooping(false)
	end
	
	love.audio.setPosition(0,0,0)
	
	set_bpm(presets[selected_preset].bpm, presets[selected_preset].subdivision)
	master_bar.height = love.graphics.getHeight()
	love.audio.setVolume(height_to_volume(master_bar.height))
	love.graphics.setNewFont(48)
end

function love.update(dt)
	maintimer = maintimer + dt
	subtimer = subtimer + dt
	width = love.graphics.getWidth()
	pct = (maintimer / maindelay)
	if not pendulum.rightward then
		pct = 1-pct
	end
	pendulum.x = width * pct
	handle_mouse()
	
	-- main click
	if maintimer >= maindelay then
		maintimer = maintimer - maindelay
		subtimer = subtimer - subdelay
		pendulum.rightward = not pendulum.rightward
		if not paused then
			flash_intensity = 255
			play_click()
			-- play_sub_click()
		end
	-- subdivision click
	elseif subtimer >= subdelay then
		subtimer = subtimer - subdelay
		if not paused then
			flash_intensity = 0
			play_sub_click()
		end
	end
end

function love.draw()
	draw_flash()
	
	-- bpm bar
	local x, y, width, height = get_bpm_bar()
	love.graphics.setColor(0, 0, 255)
	love.graphics.rectangle('fill',x, y, width, height)


	-- master volume
	local x, y, width, height = get_master_bar()
	love.graphics.setColor(0,255,0)
	love.graphics.rectangle('fill',x, y, width, height)
	
	-- bpm text
	love.graphics.printf( selected_preset .. ' : ' .. bpm .. ' / ' .. subdivision, 0, love.graphics.getHeight() / 3, love.graphics.getWidth(), 'center' )
	
	draw_pendulum()
end

function love.keypressed(key, scancode, isrepeat)
	local new_bpm = bpm
	local new_sub = subdivision
	local new_preset = 0
	if key == 'space' then
		paused = not paused
	elseif key == '1' then
		new_preset = tonumber(key)
	elseif key == '2' then
		new_preset = tonumber(key)
	elseif key == '3' then
		new_preset = tonumber(key)
	elseif key == '4' then
		new_preset = tonumber(key)
	elseif key == '5' then
		new_preset = tonumber(key)
	elseif key == '6' then
		new_preset = tonumber(key)
	elseif key == '7' then
		new_preset = tonumber(key)
	elseif key == '8' then
		new_preset = tonumber(key)
	elseif key == '9' then
		new_preset = tonumber(key)
	elseif key == 'up' then
		new_bpm = new_bpm + 1
	elseif key == 'down' then
		new_bpm = new_bpm - 1
	elseif key == 'right' then
		new_sub = math.min(3,new_sub + 1)
	elseif key == 'left' then
		new_sub = math.max(1,new_sub - 1)
	elseif key == 'pageup' then
		new_bpm = new_bpm + 10
	elseif key == 'pagedown' then
		new_bpm = new_bpm - 10
	elseif key == 'f' then
		enable_flash = not enable_flash
	elseif key == 't' and not isrepeat then
		do_tap_flash = true
		table.insert(taps,love.timer.getTime())
		new_bpm = compute_taps()	
	elseif key == 'escape' or key == 'esc' or key == 'q' then
		love.event.quit()
	end
	
	if new_preset > 0 then
		selected_preset = new_preset
		new_bpm = presets[selected_preset].bpm
		new_sub = presets[selected_preset].subdivision
	end
	
	set_bpm(new_bpm, new_sub)
	maintimer = maindelay
	subtimer = subdelay
end

function select_preset(key)
	selected_preset = tonumber(key)
	return presets[selected_preset]
end

function draw_flash()
	if flash_intensity <= 0 or not enable_flash then
		return
	end
	
	if do_tap_flash then
		love.graphics.setColor(255,128,128,flash_intensity)
		do_tap_flash = false
	else
		love.graphics.setColor(255,255,255,flash_intensity)
	end
	love.graphics.rectangle('fill',0,0,love.graphics.getWidth(), love.graphics.getHeight())
	love.graphics.setColor(0,0,0)
	flash_intensity = flash_intensity - flash_fade_rate
	-- if flash_intensity or do_tap_flash then
	-- 	if do_click_flash then
	-- 		do_click_flash = false
	-- 	end
	-- 	if do_tap_flash then
	-- 		do_tap_flash = false
	-- 		love.graphics.setColor(255,128,128)
	-- 	end
	-- 	love.graphics.rectangle('fill',0,0,love.graphics.getWidth(), love.graphics.getHeight())
	-- 	love.graphics.setColor(0,0,0)
	-- end
end

function draw_pendulum()
	-- draw the pendulum background
	love.graphics.setColor(0,0,0)
	love.graphics.rectangle('fill',0, 0, love.graphics.getWidth(), 20)
	
	-- draw main pendulum
	love.graphics.setColor(255,255,0)
	love.graphics.rectangle('fill',pendulum.x-15, 0, 30, 20)
	
	-- draw secondary pendulums
	local xinc
	local opacity
	local px
	
	local tail_length = 3
	for i=0,tail_length do
		xinc = i*15
		if pendulum.rightward then
			xinc = -xinc
		end
		opacity = 1 - i / tail_length
		px = pendulum.x - 15 + xinc
		-- print(pendulum.x .. ' ' .. opacity .. ' ' .. px)
		love.graphics.setColor(255,255,0, 255*opacity)
		love.graphics.rectangle('fill',px, 0, 30, 20)
	end
end

function handle_mouse()
	if not love.mouse.isDown(1,2) then
		return
	end

	-- determine which slider is selected
	x, y = love.mouse.getPosition()
	local bar_width = love.graphics.getWidth() / 11
	local bar = math.floor(x / bar_width) + 1

	-- flip the y value
	local height = love.graphics.getHeight() - y

	if bar == 11 then
		master_bar.height = height
		love.audio.setVolume(height_to_volume(master_bar.height))
	elseif bar == 1 then
		bpm_bar.height = height
		set_bpm(height_to_bpm(height))
	end
end


-- helper functions
function set_bpm(n, sub)
	bpm = n
	subdivision = sub or 1
	presets[selected_preset].bpm = bpm
	presets[selected_preset].subdivision = subdivision
	maindelay = 60.000 / bpm
	subdelay = maindelay / subdivision
	bpm_bar.height = bpm * (love.graphics.getHeight()-20) / max_bpm
end


function get_bpm_bar()
	local width = love.graphics.getWidth() / 11
	local xpos = 0
	local height = bpm_bar.height
	local ypos = love.graphics.getHeight() - height

	return xpos, ypos, width, height
end

function compute_taps()
	local new_bpm = bpm
	
	-- clear out all but the last four taps
	while #taps > 4 do
		table.remove(taps,1)
	end
	
	if #taps == 4 then
		-- figure out the average timediff
		local avg_timediff = (taps[4] - taps[1]) / 3
		new_bpm = math.floor(60.0 / avg_timediff)
	end
	
	return new_bpm
end

function get_master_bar()
	local width = love.graphics.getWidth() / 11
	local xpos = width * (10)
	local height = master_bar.height
	local ypos = love.graphics.getHeight() - height

	return xpos, ypos, width, height
end


function volume_to_height(v)
	local h_ratio = v * love.graphics.getHeight() - 30

	-- linear easing
	local h = h_ratio

	-- sinusoidal easing
	local h = math.acos(math.pi * h_ratio + math.pi * .5)

	return h
end

function height_to_volume(h)
	-- apply an easing function to make the volume curve parabolic.
	local h_ratio = h/love.graphics.getHeight()

	-- linear easing
	local v = h_ratio

	-- quadratic easing
	local v = math.pow(h_ratio, 3)
	return v
end

function height_to_bpm(h)
	local new_bpm = math.floor(max_bpm * h / love.graphics.getHeight())
	return new_bpm
end

function play_click()
	local next_click = (current_click % num_clicks) + 1
	clicks[next_click]:stop() -- also rewinds to the beginning since v11.0
	-- clicks[next_click]:seek(0)
	clicks[next_click]:play()
	current_click = next_click
end

function play_sub_click()
	local next_subclick = (current_subclick % num_clicks) + 1
	subclicks[next_subclick]:stop() -- also rewinds to the beginning since v11.0
	-- subclicks[next_subclick]:seek(0)
	subclicks[next_subclick]:play()
	current_subclick = next_subclick
end