--[[
    reveal_t
    reveal_co
    one_at_a_time
    finish_time
    fixed_angle
    scale
    x_co, y_co, z_co
    score_mul,
    homing_ratio
]]

function make_entities_map(start, end_index)
    data = {}
    for i = 0, 2047 do
        val = mget(i % 128, i \ 128)
        add(data, val \ 16)
        add(data, val % 16)
    end
    cur = start
    function unpack_nibs(nibbles, mul, positive)
        local val = positive and 0 or ((-1 << ((nibbles * 4) - 1)) + 1)
        for j = 1, nibbles do
            val += data[cur] << ((nibbles - j) * 4)
            cur += 1
        end
        return val * mul
    end
    function unpack_targets()
        len = unpack_nibs(2,1,true)
        targets = {}
        for i = 1, len do
            add(targets, unpack_nibs(2,1,true))
        end
        return targets
    end
    local prop_table = split"reveal_t,reveal_co,one_at_a_time,finish_time,fixed_angle,scale,x_co,y_co,z_co,score_mul,heal,homing_ratio,set_key,start_key,target_360"
    function unpack_props()
        len = unpack_nibs(1,1,true)
        local props = {}
        for i = 1, len do
            props[prop_table[unpack_nibs(2,1,true) + 1]] = unpack_nibs(2,0.1)
        end
        return props
    end
    local last_args2
    while cur < end_index do
        local args1, args2 = pack(
            data_models[unpack_nibs(2,1, true) + 1], -- model
            {unpack_nibs(2, 0.25), unpack_nibs(2, 0.25), -unpack_nibs(4, 0.125, true) - 40} -- pos
        )
        if data[cur] == 15 and data[cur + 1] == 15 then
            args2 = copy(last_args2)
            unpack_nibs(2,1)
        else
            args2 = pack(
                data_paths[unpack_nibs(2,1, true) + 1], -- path
                unpack_nibs(2, 0.1), -- path scale
                unpack_nibs(2, 0.1, true), -- speed
                unpack_nibs(4, 1, true), -- beats
                unpack_targets(), -- targets
                unpack_nibs(4, 1, true) -- missiles
            )
            last_args2 = copy(args2)
        end
        add(args2, unpack_props()) -- props

        make_entity(args1[1], args1[2], unpack(args2))
    end
end

function make_entity(model_str, pos, path_str, path_scale, movement_speed, dance, target_points, missile_times, props)
    local e = {
        initial_pos = pos,
        model = deserialize_model_and_sprites(model_str, props.scale, {pos[1], pos[2], pos[3]}),
        movement_speed = movement_speed,
        dance = dance,
        target_points = target_points,
        has_health = #target_points > 0,
        path_scale = path_scale,
        props = props,
        missile_times = missile_times,
        path_co = {props.x_co or 1, props.y_co or 1, props.z_co or 1},
        smoothed_forward = {0,0,1},
        keyframes={},
        path={},
        current_euler = v_zero(),
    }
    local model = e.model
    local last = split"0,0,0,0,0,0"
    for frame in all(split(path_str, "/")) do
        local kf, data = unpack(split(frame, ":"))
        data = split(data, ";")
        add(e.keyframes, kf)
        for i = 1,6 do
            if data[i] == "" then
                data[i] = last[i]
            end
            last[i] = data[i]
        end
        e.path[kf] = data
    end
    e.props.finish_time = e.props.finish_time or 1
    local starting_health = #target_points
    populate_table(e, "key_started=true;active=false;time=0;t=0;t2=0;alive=true;dying=false;death_time=0;hit_time=0;in_range=false;in_range_time=0;time_till_delete=10")
    for n, pti in pairs(target_points) do
        local s = sprite(model.points[pti], function(self, x, y, size)
            local time_alive = -((e.props.reveal_t or 0) + n * (e.props.reveal_co or 0) - e.time / 30)
            if time_alive < 0 or (e.props.one_at_a_time and (n-1) != (starting_health - #e.target_points)) then return end

            local s1, s2 = size * 4 + 1, size * 2 + 1

            if self.pos[3] < e.model.pos[3] and not self.targeted and not e.props.target_360 then
                return
            end

            c2 = framenum % 2 == 0 and 12 or 7
            ovalfill(x - s1, y - s1, x + s1, y + s1, self.targeted and c2 or 7)
            oval(x - s2, y - s2, x + s2, y + s2, self.targeted and c2 or 8)
            if self.targeted then
                local s8 = mid(size * 25, 4, 20)
                rect(x - s8, y - s8, x + s8, y + s8, c2)
            end
            -- If just appeared then we want a targeting reticle
            if time_alive < 1 and ((time_alive * 16 \ 1) % 2 == 0 or time_alive < 0.25) then
                local d1 = max(50 - time_alive * 150, 6)
                local d2 = d1 * 3 - 10
                for dx,dy in fourway() do
                    line(x + dx * d1, y + dy * d1, x + dx * d2, y + dy * d2, 7)
                end
            end
            -- inside targeting zone
            if abs(x - player.cursor_2d[1]) <= 5 and abs(y - player.cursor_2d[2]) <= 5 then
                target_in_crosshair(e, pti, self)
            end
        end)
        s.target_triangle_index = tri
        add(model.sprites, s)
    end

    function e.kill()
        if e.props.set_key then level_keys[e.props.set_key] = true end
        del(entities, e)
    end

    function e.take_damage(pti, target_sprite)
        e.hit_time += 3
        if model.triangle_colors == nil then
            model.triangle_colors = mapfilter(model.triangles, function(t) return t.color end)
        end
        del(e.target_points, pti)
        del(model.sprites, target_sprite)
        if #e.target_points == 0 then
            score += #model.triangles * 5 * (e.props.score_mul or 1)
            e.dying = true
            if e.props.heal then player.health = min(player.health + 1, 4) end
            make_splash(v_add(model.pos, {0,0,0}))
        end
    end

    add(entities, e)
    return e
end

function entities_in_range()
    return mapfilter(entities, function(ent)
        if (not ent.props.start_key or level_keys[ent.props.start_key]) and (ent.active or abs(ent.model.pos[3] - player.pos[3]) < 40) then
            if ent.props.start_key and not ent.active then
                ent.initial_pos[3] = player.pos[3] - 40
            end
            ent.active = true
            return ent
        end
    end)
end

function update_entities(beat_num)
    --local t1 = stat(1)
    local order = {1,3,2}
    local beat_bit = 1 << (15 - beat_num\2)
    for en,e in pairs(entities_in_range()) do
        --e.indicator = 49
        e.time += 1
        -- Only move if the dance bit for this beat is set!
        -- Or, we also move when we're hit
        if (beat_bit & e.dance != 0) or e.dying or e.time == 1 then
            local m, dt = e.model, 0
            delta = e.movement_speed
            local mt1, mt2 = ((e.t - delta) % 128) \ 8, e.t \ 8
            if mt2 != mt1 and (e.missile_times & 0b1000000000000000 >>> mt2) != 0 then
                make_entity(
                    data_models["missile"],
                    copy(m.pos),
                    data_paths["missile"],
                    3,0.15,-1,{2},0,
                    {
                        homing_ratio=1,
                        x_co = (rnd(1) > 0.5) and 1 or -1,
                        y_co = rnd(0.5) + 0.5,
                        score_mul = 0
                    }
                )
            end
            e.t = (e.t + delta) % 128
            e.t2 = e.t2 + delta
            if e.props.finish_time and e.t2 + e.movement_speed >= 128 * e.props.finish_time then
                e.kill()
            end
            local paths = e.motion
            local n = 128
            local i = e.t
            local update_pos = false
            local update_rot = false
            local euler = v_zero()
            
            local old_pos = {m.pos[1], m.pos[2], m.pos[3]}
            local result = interp(e.path, e.keyframes, i / 128)
            for q = 1,6 do
                if q <= 3 then
                    local qo = order[q]
                    m.pos[qo] = result[q] * e.path_scale * e.path_co[qo] + e.initial_pos[qo]
                    update_pos = true
                else
                    if result[q] != e.current_euler[q - 3] then
                        euler[q - 3] = result[q]
                        e.current_euler[q - 3] = result[q]
                        update_rot = true
                    end
                end
            end

            if e.props.homing_ratio then
                --local ht = mid((30 - abs(m.pos[3] - camera.pos[3])) / 30, 0, 1) * e.props.homing_ratio
                local ht = mid(e.time / 240 * e.props.homing_ratio, 0, 1)
                m.pos[1] = m.pos[1] * (1-ht) + camera.pos[1] * ht
                m.pos[2] = m.pos[2] * (1-ht) + camera.pos[2] * ht
                update_pos = true
            end

            local up = {0,1,0}
            if update_pos or update_rot then
                if not e.props.fixed_angle and update_pos then
                    local delta = v_sub(old_pos, m.pos)
                    local rotrate = e.time == 2 and 1 or 0.2
                    if delta[1] != 0 or delta[2] != 0 or delta[3] != 0 then
                        local r = rnd(0.0001)
                        local tf = v_norm(v_add(delta, {r,r,r}))
                        if abs(tf[1] - e.smoothed_forward[1]) + abs(tf[2] - e.smoothed_forward[2]) + abs(tf[3] - e.smoothed_forward[3]) > 0.1 then
                            e.smoothed_forward = v_norm(v_add(v_mul(tf, rotrate), v_mul(e.smoothed_forward, 1 - rotrate)))
                            m.rotation = m_look(v_norm(e.smoothed_forward), up)
                            update_rot = true
                        end
                    end
                end            
                if update_rot and (e.current_euler[1] != 0 or e.current_euler[2] != 0 or e.current_euler[3] != 0) then
                    m.rotation = mm4(m_rot_xyz(unpack(e.current_euler)), m_look(v_norm(e.smoothed_forward), up))
                    update_rot = true
                end
                if update_pos and not update_rot then
                    --e.indicator = 50
                    local delta = v_sub(m.pos, old_pos)
                    for i = 1, #m.points do
                        m.points[i][1] = m.points[i][1] + delta[1]
                        m.points[i][2] = m.points[i][2] + delta[2]
                        m.points[i][3] = m.points[i][3] + delta[3]
                    end
                    for tri in all(m.triangles) do
                        tri.center = v_add(tri.center, delta)
                    end
                else
                    --e.indicator = 51
                    m.update_points()
                end       
            end
            
            if e.hit_time > 1 or e.dying then
                for t in all(e.model.triangles) do
                    t.color = rnd(split"0,7,8")
                end
            end
            if e.hit_time == 1 then
                for i,t in pairs(e.model.triangles) do
                    t.color = e.model.triangle_colors[i]
                end
            end                
            e.hit_time = max(e.hit_time - 1, 0)
            if e.dying then
                e.death_time += 1
                if e.death_time > e.time_till_delete then
                    e.kill()
                end
            end

            if not player.dying and not e.dying and abs(m.pos[3] - player.pos[3] - 2) < 2 and abs(m.pos[2] - player.pos[2]) < 3 and abs(m.pos[1] - player.pos[1]) < 3 then
                player.take_damage()
                if not player.dying then
                    e.dying = true
                end
            end
        end
    end
    --printh(stat(1) - t1)
end