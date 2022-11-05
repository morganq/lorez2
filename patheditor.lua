--[[
reference values on z
]]

function _init()
    pobj = {
        x=0,y=0,z=0,
        ax=0,ay=0,az=0
    }

	framenum = 0
    pz = 0
    ax, ay, az = 0, 0, 0
    lmx, lmy = 0,0
    time = 0
    path = {}
    path2 = {}
    fftn = 4
    mode = "draw"
    poke(0x5F2D, 0x1)
    edit_locked = false
    show_path2 = false
    ship_angle = 0
    fractime = 0
    rate = 0.5

    keyframes = {}
end

function update_path()
    if mode == "draw" then
        if (mb & 0b01) != 0 then
            local lp = path[#path]
            add(path, {mx, my, 0, 0, 0, 0})
        end
        if (mb & 0b10) != 0 then
            if #path > 0 then
                local lx, ly = path[1][1], path[1][2]
                local path2 = {{lx, ly, 0, 0, 0, 0}}
                local in_eq_sub = 0
                for i = 2, #path do
                    local cx, cy = path[i][1], path[i][2]
                    if in_eq_sub > 0 then
                        if i < #path and lx == cx and ly == cy then
                            in_eq_sub += 1
                        else
                            local start = i - in_eq_sub
                            for j = start, i do
                                local t = (j - start) / (i - start)
                                local ix = path[start][1] + (cx - path[start][1]) * t
                                local iy = path[start][2] + (cy - path[start][2]) * t
                                --printh(j .. " " .. ix .. " " .. iy .. " " .. t)
                                path2[j] = {ix, iy, 0, 0, 0, 0}
                            end
                            in_eq_sub = 0
                        end
                    else
                        if lx == cx and ly == cy then
                            in_eq_sub = 1
                        else
                            path2[i] = path[i]
                        end
                    end
                    lx, ly = path[i][1], path[i][2]
                end
                
                path = path2
                mode = "edit"
                add(keyframes, 1)
                add(keyframes, #path)
                update_path2()
            end
        end
    end

    if mode == "edit" then
        if btn(5) then
            show_path2 = true
        else
            show_path2 = false
        end
        if (mb & 0b01) != 0 then
            if edit_locked then
                if edit_locked == 3 then
                    path[time + 1][edit_locked] = mid(mx - 35, -20, 20)
                else
                    i = edit_locked - 3
                    local dx, dy = mx - 35, my - (28 + 18 * (i - 1))
                    local ang = atan2(dx, dy) * 6.2818
                    if ang > 3.14159 then ang -= 6.2818 end
                    path[time + 1][edit_locked] = ang
                end
            else
                for i = 1,3 do
                    local dx, dy = mx - 35, my - (28 + 18 * (i - 1))
                    if dx * dx + dy * dy <= 8 * 8 then
                        edit_locked = i + 3
                    end
                end
                if mx >= 15 and mx <= 55 and my >= 10 and my <= 14 then
                    edit_locked = 3
                end
            end
        else
            edit_locked = false
        end
    end

	if stat(30) then
		local symbol = stat(31)
        if symbol == "1" then rate = 0.125 end
        if symbol == "2" then rate = 0.25 end
        if symbol == "3" then rate = 0.5 end
        if symbol == "4" then rate = 1 end
        if symbol == "5" then rate = 2 end
        if symbol == "6" then rate = 4 end
        if symbol == "7" then rate = 8 end
        if symbol == "8" then rate = 16 end
        if symbol == "0" then rate = 0; time = 0; fractime = 0 end
        if symbol == "s" then
            save()
        end
        if symbol == "k" then
            add_keyframe(time)
            printh("--")
            for kf in all(keyframes) do
                printh(kf)
            end         
            printh(" > ")   
            update_path2()
        end
        if symbol == "l" then
            keyframes = {1, #path}
        end
        if symbol == "z" then
            update_path2()
        end
        if symbol == "r" then
            mode = "draw"
            path2 = {}
            time = 0
            fractime = 0
            path = {}
            keyframes = {}
        end
    end    
end

function save()
    transformers = {
        function(x) return (x - 64) / 6.4 end,
        function(y) return (y - 64) / 6.4 end,
        function(z) return z end,
        function(yaw) return yaw end,
        function(pitch) return pitch end,
        function(roll) return roll end,
    }
    local s = ""
    local last = {0,0,0,0,0,0}
    for i,kt in pairs(keyframes) do
        s ..= kt .. ":"
        local cur = path[kt]
        for j = 1,6 do
            if last[j] != cur[j] then
                s ..= transformers[j](cur[j])
            end
            if j != 6 then s ..= ";" end
        end
        if i != #keyframes then
            s ..= "/"
        end
    end
    printh(s)
end

function add_keyframe(v)
    for i = 1, #keyframes do
        if v < keyframes[i] then
            add(keyframes, v, i)
            return
        end
    end
    add(keyframes, v)
end

function update_path2()
    path2 = {}
    for i = 0,100 do
        path2[i] = interp_smooth(path, keyframes, i / 100)
    end
end

function _update()
	framenum += 1
    if #path > 0 then
        fractime = (fractime + rate) % #path
        time = fractime \ 1
    end
    mx, my, mb = stat(32), stat(33), stat(34)
    
    update_path()
end

function draw_ship(off)
    local dx, dy = cos(pobj.ay + off), -sin(pobj.ay + off)
    local sx, sy = -dy, dx
    local fx, fy = pobj.x + dx * 3, pobj.y + dy * 3
    local b1x, b1y = pobj.x + sx * 2 - dx * 2, pobj.y + sy * 2 - dy * 2
    local b2x, b2y = pobj.x - sx * 2 - dx * 2, pobj.y - sy * 2 - dy * 2
    color(12)
    polyfill({{fx, fy}, {b1x, b1y}, {b2x, b2y}}, 12)
    pset(fx, fy, 7)
end

function draw_path()
    cls()
    for x = 4, 127, 8 do
        line(x, 0, x, 128, 1)
    end
    for y = 4, 127, 8 do
        line(0, y, 128, y, 1)
    end    
    line(64, 0, 64, 128, 7)
    line(0,64, 128, 64, 7)
    factor = 5 / 128
    line(0, 64 - time * factor, 128, 64 - time * factor, 6)

    for p in all(path) do
        pset(p[1], p[2], 11)
    end

    for p in all(path2) do
        pset(p[1], p[2], 8)
    end    

    if #path > 0 and time < #path then
        local pt = path[time + 1]
        --local pt2 = path[((time + 5) % (#path+1)) + 1]
        local pt2 = path[(time + 5) % #path + 1]
        if show_path2 then
            local ratio = #path2 / #path
            local n =mid((time * ratio) \ 1 + 1, 1, #path2)
            ?n, 20, 1, 12
            pt = path2[n]
            pt2 = path2[n % #path2 + 1]
        end
        pobj.x, pobj.y, pobj.z, pobj.ax, pobj.ay, pobj.az = unpack(pt)
        x2, y2 = pt2[1], pt2[2]
        local dx, dy = x2 - pobj.x, y2 - pobj.y
        if dx != 0 or dy != 0 then
            local sa = atan2(dx, dy) * 6.2818
            local rd = sqrt(dx * dx + dy * dy) / 20
            local ad = angledelta(sa, ship_angle)
            if ad > rd then
                ship_angle -= rd
            elseif ad < -rd then
                ship_angle += rd
            end
        end
        draw_ship(ship_angle)
    end
end

function draw_meter(x, y, val, c)
    rect(x, y, x + 40, y + 4, 7)
    rectfill(x + 19 + val, y, x + 21 + val, y + 4, c)
end

function draw_angle_meter(x, y, val, c)
    circ(x, y, 7, 7)
    local dx, dy = cos(val), -sin(val)
    line(x, y, x + dx * 7, y + dy * 7, c)
end

function _draw()
    draw_path()
    spr(1, mx, my)
    if mode == "edit" then
        c = 10
        if show_path2 then
            c = 12
        end
        ?"z", 1, 10, 7
        draw_meter(15, 10, pobj.z, c)
        ?"pitch", 1, 28, 7
        draw_angle_meter(35, 30, pobj.ax, c)
        ?"yaw", 1, 46, 7
        draw_angle_meter(35, 48, pobj.ay, c)
        ?"roll", 1, 64, 7
        draw_angle_meter(35, 66, pobj.az, c)
    end

    line(0,0,128,0,6)
    line(0,0,128 * (time-1) / #path,0,7)
    pset(128 * (time-1) / #path,0,11)
    for kf in all(keyframes) do
        pset((kf-1) / #path * 128, 1, 8)
    end

    ?time, 1, 2, 8
end