--❎🅾️⬆️⬇️⬅️➡️⧗

-- themes: land sea air? - mastery + control over nature, contradiction and conflict
-- land: key: seed, tree (fires missiles), wheel, 
-- sea: key: sail. swarms? coral, jellyfish, boats, rig
-- air: key: gear. propeller. bombs.

function qsfx(ind, channel, offset, length) add(sound_queue, {ind, channel, offset, length}) end

cartdata("lorez2")
stage_names = split"cel [tyrant],nethuns [monarch],tin [magnate]"
poke(0X5F5C, 255)
function _init()
	--make_entities_map()
	camera = {
		pos=v_zero(),
		angles=v_zero(),
		fwd={0,0,-1,1},
	}
	focuses = {}
	sprites, entities, sculptures, lasers, score = {}, {}, {}, {}, 0

	player_spawn()
	player.cursor, player.speed = split"0.55,-0.25", 0
	framenum, last_tick, selected_stage, game_started, level_keys = 0, 0, 1, false, {}
	
	beat_frame, beat_num, beat_ticks_16, beat_ticks_8, beat_ticks_4 = false, 0, 0, 0, 0
	_update, _draw = _title_update, _title_draw
	set_stage(1)
end

function start()
	was_pressed = false
	player_spawn()
	
	sound_queue = {}
	_update, _draw = _game_update, _game_draw
	-- z1, z2, model, x1, x2, xo, y1, y2, yo, zi, xco
	--sculptures = {make_models_sculpture("0,-90,s_curb,-4,4,8,-3,-3,1,8,1")}
	--sculptures= {}
	focuses=split("0,0,0,0/-36,0.7,0,0/-64.5,0,0,0","/")
	for mss in all(split([[-40,-50,s_zig,-18,-18,1,-4,-4,1,24,-1
	-40,-50,s_zig,18,18,1,-4,-4,1,24,-1
	-90,-180,s_zig,-18,-18,1,-4,-4,1,24,-1
	-10,-350,s_curb,-4,4,8,-3,-3,1,8,1
	-400,-500,s_column,-13,13,26,3,3,1,22,1.2]], "\n")) do
		add(sculptures, make_models_sculpture(mss))
	end
	--
	--sculptures = {make_models_sculpture("0,-90,s_column,-12,12,24,2,2,1,12,1")}
	--sculptures = {make_models_sculpture("0,-90,s_hex,-2,-2,1,-3,-3,1,6,-1")}
	framenum, game_started, title_model = 0, true, nil
	make_entities_map(map_indices[selected_stage], map_indices[selected_stage + 1])
	pal()	
	camera.fwd = split"0,0,-1"
end

function set_stage(i)
	stage_models = split"6,3,2"
	title_model = deserialize_model(data_models[stage_models[i]], 7, split"-6,-2,-20")
	for t in all(title_model.triangles) do t.color = 0x63 end
	selected_stage = i
end

function _title_draw()
	cls(7)
	pal(split"6,13,3,4,13,6,0,8,9,10,11,12,1,14,15,7",1)
	draw_game()
	--clip(0,0,128,framenum * 4)
	if not player.launching then
		?"\^w\^t\f7lo-rez\b\b\b\b\b\b\f3\-flo-rez \fd\^j1n\^h\^-w\^-t-instructions-\n\fd⬆️⬇️⬅️➡️ to aim\nhold ❎ to target\nrelease ❎ to fire\^j16\^h",42, 10
		for i = 1,3 do
			if i == selected_stage then
				ps = "\^h\f0\^#\#3[stage " .. i .. "]\^-#\f7"
				
			else
				ps = "\^h\fd stage " .. i
			end
			ps ..= "\n \fcbest: " .. dget(i)
			?ps .. "\n" 
		end
	end
end

function _title_update()
	framenum += 1
	player_update()
	title_model.rotation = m_rot_xyz(0, framenum/120, 0)
	title_model.update_points()
	if btnp(2) and selected_stage > 1 then set_stage(selected_stage - 1) end
	if btnp(3) and selected_stage < 3 then set_stage(selected_stage + 1) end
	if btnp(5) and not player.launching then
		player.launching = true
		player.dying = true
		sfx(20)
		
	end
	if player.launch_time > 75 then
		sfx(-1)
		music(1, nil, 1 | 2 | 3 | 4)
		start()
		_update()
		
	end
end

function _game_update()
	framenum += 1

	if btnp(5) then sfx(17,2,0,3); was_pressed = true end
	if not btn(5) and was_pressed then was_pressed = false; sfx(17,2,4,3) end

	if btn(4) then
		--for e in all(entities) do 
		--	if e.time > 0 then e.dying = true end
		--end
	end
	if btnp(4) then
		local n = stat(53) + 1
		poke(0x3200 + 68 * 8 + n * 2, 188)
		poke(0x3201 + 68 * 8 + n * 2, 51)
	end
	--player.speed = 0.025 + (btn(4) and 1 or 0)

	player_update()
	foreach(lasers, function(l) l.update() end)
	
	if #focuses > 0 then
		local cf = split(focuses[1])
		if camera.pos[3] < cf[1] then
			player.focus = {cf[2], cf[3], cf[4], 1}
			deli(focuses,1)
		end
	end

	beat_ticks_16 += 1
	beat_ticks_8 += 1
	beat_ticks_4 += 1
	local tick = stat(56) / 15 + 0.25 --* 16 / 480
	if tick % 1 < last_tick % 1 then
		while #sound_queue > 0 do
			sfx(unpack(sound_queue[1]))
			deli(sound_queue, 1)
		end
		beat_num = (beat_num + 1) % 32
		if beat_num % 2 == 0 then
			beat_ticks_16 = 0
			beat_frame = true
		end
		if beat_num % 4 == 0 then
			beat_ticks_8 = 0
		end
		if beat_num % 8 == 0 then
			beat_ticks_4 = 0
		end		
	else
		beat_frame = false
	end
	last_tick = tick

	update_entities(beat_num)

	if player.die_time >= 120 and btnp(5) then
		run()
	end

	if #entities == 0 and not player.dying then
		if not player.launching then
			player.launching = true
			dset(selected_stage, max(dget(selected_stage), score))
		end
		if player.launch_time > 240 then
			run()
		end
	end
end

function draw_skybox(x,y)
	cls(0)
	--local cols, fills = split"1,5,1,5", split"0b0,0b1111000011110000.1,0b0,0b0,0b0"
	local cols, fills = split"1,5,1,5", split"0b0,0b1101000001110000.1,0b0,0b0,0b0"
	--local cols, fills = split"1,5,1,5", split"0b0,0b1111101101011011.1,0b0,0b0,0b0"
	for i = 1, 4 do
		fillp(fills[i])
		circfill(x, y, 160 / (i + 1) + sin(beat_ticks_4 / 8) ^ 9 * 3, cols[i])
		fillp()
		local rad = 150 - i * 30
		circ(x, y, rad, 1)
	end
	--line(0, y, 128, y, 1)
	for i = 1,4 do
		local co = 1 + i / 5
		circ(64 - (64 - x) * co, 64 - (64 - y) * co, 1 + i * 4, 1)
	end	
	for i = 1, 100 do
		local a, r = sin(i * 160.37) * 50, sin(i * 190) * 150
		circfill(x + sin(a) * r, y + cos(a) * r, abs(sin(a) * 1.15), 2)
	end
	--fillp(0b0000111100001111.1)

	--fillp()

	if player.dying or player.launching then
		circfill(x, y, (player.die_time + player.launch_time) * 2, 0)
	end
end

function draw_game()
	cls()
	local models = {title_model} or {}
	local frame_sprites = copy(sprites)
	for e in all(entities_in_range()) do
		if player.dying then
			e.movement_speed *= 0.8
		end
		if e.time > 1 then
			for s in all(e.model.sprites) do add(frame_sprites, s) end
			add(models, e.model)
		end
	end
	if player.die_time < 60 then
		add(models, player.model)
	end
	for s in all(sculptures) do
		if not player.dying then
			s.compute()
		end
		add(models, s)
	end

	--local time1 = stat(1)
	render(models, frame_sprites, camera, 128, 128, draw_skybox, min(70 + player.launch_time,180))
end

function _game_draw()
	draw_game()

	local cursor_center = v_add(player.cursor_fwd, camera.pos)
	player.cursor_2d = transform_point_slow(camera, cursor_center)
	local c2dx, c2dy = unpack(player.cursor_2d)

	if not player.dying and not player.launching then
		spr(btn(5) and 70 or 17, c2dx - 7, c2dy - 7, 2, 2)
		spr(19 + beat_num\2 % 2, player.cursor_2d[1] - 1, player.cursor_2d[2] - 1)
	end

	for i = 0,3 do
		local x = i * 12 + 5
		rect(x, 120, x + 10, 126, 9)
		if i < player.health then
			local h = 0.5 + ((framenum - i) % 15) ^ 1.5 * 0.065
			rectfill(x+1, 122 - h, x + 9, 125 + h, 7)
		end
	end
	local st = #player.selected_targets
	player.last_target_time += 1
	if player.last_target_time < 30 and st > 0 then
		
		if player.last_target_time < 3 then pal({[7]=12}) end
		if st == 8 then
			spr(44, player.cursor_2d[1] - 10, player.cursor_2d[2] - 16, 3, 1)
		else
			spr(35 + st, player.cursor_2d[1] - 3, player.cursor_2d[2] - 16)
		end
		pal()
	end

	--pal({[1]=130, [5]=141, [10]=135, [4]=136}, 1)
	pal(split"130,142,3,136,141,6,7,8,9,10,11,12,13,14,15,0", 1)
	if player.dying and player.die_time > 30 then
		local w = mid((player.die_time - 30) * 2, 0, 64)
		local w2 = cos(w / 64 * 3.14159) * -32 + 32
		rectfill(64 - w2, 54, 64 + w2, 74, 7)
		if w >= 64 then
			local o1, o2 = -52, 0
			if player.die_time < 65 then
				o1, o2 = rnd(40) - 72, rnd(4) - 2
			end
			?"\^w\^taccess denied", 64 + o1, 59 + o2, 8
		end
		if player.die_time > 120 then
			?"❎ to try again", 36, 78, 7 + framenum \ 4 % 2
		end
	end

	?"-" .. score .. "-", 64 - #tostr(score)*2 - 2, 2,7

	if player.launching then
		?sub(stage_names[selected_stage] .. "\nhas been captured\n⁘ virus neutralized ⁘\nyou have reached\nthe end of this\nsub-system\n\n\^w\^tstage ".. selected_stage .." log out",0,player.launch_time\1.5) .. "■", 4, 40 - min((player.launch_time \ 30),4) * 6,10
	end

	--?camera.pos[3]\1,114,110,7
	--?framenum\30,114,120,7
	

	-- waterify
	--pal(split"140,2,3,4,12,6,7,8,9,10,7,11,13,14,15,1",1)

	--print(stat(56) / 15, 1, 1, 7)
end