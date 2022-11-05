function target_in_crosshair(ent, pti, spr)
	if #player.selected_targets < 8 and not spr.targeted then
        if btn(5) then
            qsfx(16, 2, #player.selected_targets, 1)
            add(player.selected_targets, {ent, pti, spr})
            player.last_target_time = 0
            spr.targeted = true
            
        end
    end
end

function player_spawn()
	player = {
		pos = v_zero(),
        focus = v_zero(),
        lerp_focus = v_zero(),
		cursor = {0,0},
		cursor_2d = v_zero(),
		selected_targets = {},
		model = deserialize_model(model_player4, 0.65, v_zero()),
	}
    obj_defaults(player, "theta=0;health=2;flipping=false;flip_time=0;last_target_time=30;dying=false;die_time=0;launching=false;launch_time=0;speed=0.025")
    local pm = player.model
    player.take_damage = function()
        if not player.flipping then
            player.health -= 1
            if player.health <= 0 then
                player.dying = true
            else
                player.flipping = true
            end
        end
    end    
end

function player_update()
    player.health=4
    local pm = player.model
    if game_started then
	    player.cursor[1] = mid(-1.25, player.cursor[1] + (tonum(btn(0)) + -tonum(btn(1))) * 0.045, 1.25)
	    player.cursor[2] = mid(-1.1, player.cursor[2] + (tonum(btn(2)) + -tonum(btn(3))) * 0.045, 1.1)
    end

    player.lerp_focus = v_add(v_mul(player.lerp_focus, 0.9), v_mul(player.focus, 0.1))
	player.cursor_fwd = mv4(m_rot_xyz(player.cursor[2] + player.lerp_focus[2], player.cursor[1] + player.lerp_focus[1], 0), {0,0,-1,1})
	camera.fwd = v_add(v_mul(camera.fwd, 0.85), v_mul(player.cursor_fwd, 0.15))
    if (not btn(5)) and #player.selected_targets > 0 then
        for i,t in pairs(player.selected_targets) do
            make_laser(t[2], t[3], t[1], (i-1) * -0.6)
        end
        score += 2 ^ #player.selected_targets
        player.selected_targets = {}
    end
    
    camera.pos = v_add(camera.pos, {0,0,-player.speed / (player.die_time + 1)})
    if player.launching then player.launch_time += 1 end
    --player.pos = v_add(camera.pos, {0,-2.5, max(-3.55, -0.5 + framenum / -15) - player.cursor[2] / 2 + sin(beat_ticks_8 / 4 - 1.2) ^ 8 * 0.125 - player.launch_time / 4 })
    player.pos = v_add(camera.pos, {0,-2.5, max(-3.55, -0.5 + framenum / -15) - player.cursor[2] / 2 - player.launch_time / 4 -beat_ticks_8 / 50 })
    --beat_ticks_8 / 50
    
    player.theta = player.theta * 0.95 + (player.cursor[1]) * 0.05
    local theta = player.theta
    local shake = 0
    if player.dying then
        player.die_time += 1
        for pt in all(pm.points) do
            pt[1] = pt[1] * 0.8
            pt[2] = pt[2] * 0.8
            pt[3] = pt[3] * 0.8
        end
    end
    if player.flipping then
        if player.flip_time == 0 then
            for tri in all(pm.triangles) do
                tri.color = 0x8a
            end
            player.flip_time = 0.15
        end
        player.flip_time += 0.03
        if player.flip_time >= 1 then
            player.flip_time = 0
            player.flipping = false
            for tri in all(pm.triangles) do
                tri.color = 0x17
            end            
        end
        shake = sin(player.flip_time * 50) * 0.25
        local flip = 1 - (1 - player.flip_time) ^ 2
        pm.rotation = m_rot_xyz(cos(flip * 3.14159) * -0.5 * 6.2818 + 3.14159, 0, 0)
        pm.update_points()
    end
    pm.special_rotation = m_rot_xyz(0,theta * 0.75,0)
    if player.launching then
        pm.rotation = m_rot_xyz(0, 0, sin(player.launch_time / 25) * 6)
        pm.update_points()
    end
    pm.special_offset = v_add(player.pos, {sin(theta) * 1.5 + shake, sin(framenum / 19) * 0.15, -cos(theta) * 0.5 + 0.5})
end

-- BUG: Something is wrong with laser line visibility at times
function make_laser(pti, target_spr, ent,t)
    local order = rnd() > 0.5 and split"0,1,2,3" or split"0,2,1,3"
    local to = ent.model.points[pti]
    local off = {rnd(1) - 0.5, rnd(1) - 0.5, -1}
    local jl = {
        points = {},
        lines = {},
        fired = false,
        t = t,
    }
    for i = 1, 3 do
        jl.lines[i] = make_line(v_zero(), v_zero(), 12, 0, 7)
    end
    local circle = sprite(v_zero(), function(self,x,y,size)
        if jl.t > 0 then
            circ(x, y, size * (8 + jl.t * 2), 12)
        end
    end)
    add(sprites, circle)
    jl.update = function()
        jl.t += 0.2
        local a = v_add(player.pos, off)
        circle.pos = a
        jl.points[1] = a
        local b = to
        for i = 1,3 do
            jl.lines[i].s1.pos = a
            jl.lines[i].s2.pos = a
        end
        if jl.fired then
            for i = 2,4 do
                local xo = (b[order[i]] - a[order[i]]) * mid(jl.t - (i - 2),0,1)
                jl.points[i] = {
                    jl.points[i - 1][1],
                    jl.points[i - 1][2],
                    jl.points[i - 1][3],
                    1
                }
                jl.points[i][order[i]] += xo
                
                jl.lines[i - 1].s2.pos = jl.points[i]
                jl.lines[i - 1].rad = 3
                if i < 4 then
                    jl.lines[i].s1.pos = jl.points[i]
                end
            end
          
        end
        if not jl.fired and beat_frame and jl.t >0 then
            qsfx(19, 3)
            jl.fired = true
        end
        if jl.t > 3 and jl.t - 0.2 <= 3 then
            ent.take_damage(pti, target_spr)
            qsfx(18, nil, rnd(8)\1 * 3, 2)
        end
        if jl.t > 4 then
            del(lasers, jl)
            for i = 1,3 do
                del(sprites, jl.lines[i].s1)
                del(sprites, jl.lines[i].s2)
            end
            del(sprites, circle)
        end
    end
    add(lasers, jl)
    return jl
end