function make_sculpture(callback, max_p, max_f)
    local m, reverse_index, forward_index = model(v_zero(), {}, {}), {}, {}
    local s = {m = m, pn = 1, max_p = max_p, fn = 1, max_f = max_f}
    
    s.add_poly = function(points, normal, color, fill)
        local indices = {}
        local center = v_zero()
        for i,p in pairs(points) do
            local key = p[1] .. "," .. p[2] .. "," .. p[3]
            --local key = p[1] + p[2] + p[3]
            --local key = (p[1] & 0x3f.f) << 9 | (p[2] & 0x3f.f) >>> 1 | (p[3] & 0x3f.f) >>> 11
            center = v_add(v_mul(p, 1 / #points), center)
            local index = reverse_index[key]
            if index == nil then
                add(indices, s.pn)
                m.points[s.pn] = p
                reverse_index[key] = s.pn
                add(forward_index, key)
                s.pn = (s.pn % s.max_p + 1)
            else
                add(indices, index)
            end
        end
        m.triangles[s.fn] = {
            point_indices = indices,
            center = center,
            normal = normal,
            color = color,
            fill = fill
        }
        s.fn = (s.fn % s.max_f + 1)
        return indices
    end

    m.compute = function()       
        while #forward_index > 32 do
            local ind = forward_index[1]
            deli(forward_index, 1)
            reverse_index[ind] = nil
        end 
        m.special_offset[3] -= -min(0.1 + player.launch_time / 25,0.7) * (player.speed * 40)
        callback(s)
    end
    
    return m
end

--[[
function make_terrain_sculpture()
    local next_z = 0
    local colors = {13, 14, 14, 14, 15}
    function callback(s)
        if camera.pos[3] - s.m.special_offset[3] > next_z + 25 then
            return
        end
        local xn = 2 + sin(next_z / 30) * 2
        for i = -xn\1, xn\1 do
            local tlx1, tlx2, tlz2 = (i - 0.5) * 3, (i + 0.5) * 3, next_z - 4
            function get_y(x,z)
                return -4 - cos(x / 4 - 3 - z / 20) * 1.5 + sin(z / 6 + x/3) * 0.5
            end
            local y1 = get_y(tlx1, next_z)
            s.add_poly({
                {tlx1, y1, next_z},
                {tlx2, get_y(tlx2, next_z), next_z},
                {tlx2, get_y(tlx2, tlz2), tlz2},
                {tlx1, get_y(tlx1, tlz2), tlz2},
            },
            {0,1,0,1},
            colors[mid(((y1 + 4.5) * 4) \ 1, 1, 5)],
            0)
        end
        next_z -= 4
    end
    return make_sculpture(callback, 128, 128, 0.1, 25)
end
]]
--[[
function make_city_sculpture()
    local next_z = 0
    local side = 1
    function callback(s)
        if camera.pos[3] - s.m.special_offset[3] > next_z + 35 then
            return
        end
        side = -side
        local i = 1
        local h1 = -0.75
        for j = 1, rnd(3) \ 1 + 1 do
            local h2 = h1 + rnd(5) + 1
            local size = rnd(1.5) + 0.5
            local sd = side * (sin(next_z / 25) * 2 + 4.65)
            for dx, dy in fourway() do
                local xs, ys = dx * size, dy * size
                s.add_poly({
                    {sd + xs + ys, h1, next_z + ys + xs},
                    {sd + xs - ys, h1, next_z + ys - xs},
                    {sd + xs - ys, h2, next_z + ys - xs},
                    {sd + xs + ys, h2, next_z + ys + xs},
                }, {dx, 0, dy, 1}, 0x12, 0b0.1)
                i += 1
            end
            h1 = h2
        end
        next_z -= 4
    end
    return make_sculpture(callback, 200, 96)
end
]]

function make_models_sculpture(def)
    local next_z = camera.pos[3]
    local x = 1
    local model = deserialize_model(data_models[split(def)[3]], 1, v_zero())
    local tris_needed, fills_needed, co = {}, {}, 1
    function callback(s)
        if framenum % 2 == 0 then
            if #tris_needed > 0 then
                local points, normal, color, fill = unpack(tris_needed[1])
                add(fills_needed, {framenum + 5, s.fn, color, fill})
                s.add_poly(points, normal, 7, 0b0.01)
                deli(tris_needed, 1)
            end
        end
        if #fills_needed > 0 then
            local time, index, color, fill = unpack(fills_needed[1])
            if framenum > time then
                local t =s.m.triangles[index]
                t.color = color
                t.fill = fill
                deli(fills_needed, 1)
            end
        end

        if beat_ticks_8 == 0 and #s.m.triangles > 0 then
            for i = 1, 2 do
                local ind = rnd(#s.m.triangles)\1 + 1
                add(fills_needed, {framenum + 5, ind, -1, 0b0.01})
                s.m.triangles[ind].color = -0x19
            end
        end

        if camera.pos[3] - s.m.special_offset[3] > next_z + 45 then
            return
        end

        prev_z = next_z
        local z1, z2, _, x1, x2, xo, y1, y2, yo, zi, xco = unpack(split(def))
        if next_z < z1 and next_z >= z2 then
            for x = x1, x2, xo do
                for y = y1, y2, yo do
                    for tri in all(model.triangles) do
                        local points = {}
                        for pi in all(tri.point_indices) do
                            add(points, v_add(model.points[pi], {x * co, y, next_z}))
                        end
                        add(tris_needed, {points, tri.normal, tri.color, tri.fill})
                    end
                end
            end
            co *= xco
            next_z -= zi
        end
        if prev_z == next_z then next_z -= 1 end
    end
    return make_sculpture(callback, 200, 96)
end


--[[
function make_billboards_sculpture()
    local next_z = 0
    local moving = {}
    local colors = split"6,13,14,13,15,13"
    local running_angle = 3.14
    function callback(s)
        function set_pos(mov)
            for j,i in pairs(mov.indices) do
                s.m.points[i] = {
                    mov.target[j][1] * mov.time,
                    mov.target[j][2] * mov.time,
                    mov.target[j][3]
                }
            end            
        end
        for mov in all(moving) do
            if mov.time >= 1 then del(moving, mov)
            else
                set_pos(mov)
                mov.time += 0.025
            end
        end
        if camera.pos[3] - s.m.special_offset[3] > next_z + 45 then
            return
        end
        local angle = running_angle--rnd(6.2818)
        running_angle += sin(next_z / 50) / 2
        local width = rnd(6) + 2
        for i = 1, 2 do
            
            local dist = rnd(3) + 6 + i * 3
            
            local a1, a2 = angle - width / dist, angle + width / dist 
            local dx1, dy1, dx2, dy2 = sin(a1) * dist, cos(a1) * dist, sin(a2) * dist, cos(a2) * dist
            local target = {
                {dx1, dy1, next_z},
                {dx2, dy2, next_z},
                {dx2, dy2, next_z - 4},
                {dx1, dy1, next_z - 4}
            }
            local q = mid(next_z \ 30 % 3, 0,2) * 2
            local indices = s.add_poly(target, {-dx1 / dist, -dy1 / dist, 0, 1}, colors[q + i], i == 1 and 0 or 0b1111000011110000.1)
            local mov = {indices = indices, time=0, target = target}
            add(moving, mov)
            set_pos(mov)
            
        end
        next_z -= width * 1
        
    end
    return make_sculpture(callback, 200, 54)
end
]]