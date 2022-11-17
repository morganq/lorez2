function make_models_sculpture(def)
    local next_z = camera.pos[3]
    local x = 1
    local base_model = deserialize_model(data_models[split(def)[3]], 1, v_zero())
    local tris_needed, fills_needed, co = {}, {}, 1
    local sculpture_models = {}
    local special_offset = 0

    return function()
        special_offset -= -min(0.1 + player.launch_time / 25,0.7) * (player.speed * 40)
        if #tris_needed > 0 then
            tris_needed[1][1].fill = tris_needed[1][3]
            add(fills_needed, {framenum + 5, tris_needed[1]})
            deli(tris_needed, 1)
        end
        if #fills_needed > 0 and framenum > fills_needed[1][1] then
            fills_needed[1][2][1].color = fills_needed[1][2][2]
            deli(fills_needed, 1)
        end
        for sm in all(sculpture_models) do
            sm.special_offset[3] = special_offset
            if sm.pos[3] + special_offset > camera.pos[3] + 5 then
                del(sculpture_models, sm)
            end
        end
        if camera.pos[3] - special_offset > next_z + 45 then
            return sculpture_models
        end

        prev_z = next_z
        local z1, z2, _, x1, x2, xo, y1, y2, yo, zi, xco = unpack(split(def))
        if next_z < z1 and next_z >= z2 then
            for x = x1, x2, xo do
                for y = y1, y2, yo do
                    local points, tris = {}, {}
                    for i,t in pairs(base_model.triangles) do
                        local t2 = {point_indices = t.point_indices, color = 7, fill = 0b1111111111111111.1}
                        add(tris, t2)
                        add(tris_needed, {t2, t.color, t.fill})
                    end
                    local m = model({x * co, y, next_z}, base_model.base_points, tris)
                    add(sculpture_models, m)
                end
            end
            co *= xco
            next_z -= zi
        end
        if prev_z == next_z then next_z -= 1 end

        return sculpture_models
    end
end
