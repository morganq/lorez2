-- Mostly useless model viewer

function _init()
	models = {}
	sprites = {}
	camera = {
		pos={0,0,3,1},
		angles={0,0,0},
		fwd={0,0,-1,1},
	}


    mode = "color"
    label = "points"
	framenum = 0
    xr, yr, zr = 0, 0, 0
    lmx, lmy = 0,0
	model = deserialize_model(data_models["stage1"], 1, v_zero())
	add(models, model)
    ti = 1
    time = 0
    path = {}
    path2 = {}
    fftn = 0
    poke(0x5F2D, 0x1)
    fwd = v_norm({0,0,1})
end

function update_color()
    if (mb & 0b01) != 0 then
        dx = mx - lmx
        dy = my - lmy
        camera.angles[2] += dx / 30
        camera.angles[1] += dy / 30
        camera.pos = mv4(m_rot_xyz(camera.angles[1], camera.angles[2], camera.angles[3]), {0,0,3,1})
        camera.fwd = v_norm(v_sub({0,0,0}, camera.pos))
        --model.rotation = mm4(m_rot_xyz(0, dx / 30, 0), model.rotation)
	    --model.rotation = mm4(m_rot_xyz(-dy / 30, 0, 0), model.rotation)
    end
    
    lmx = mx
    lmy = my
    if btnp(1) then
        ti = (ti % #model.triangles + 1)
    end
    
end

function draw_line(a, b, color)
    local a2 = transform_point_slow(camera, a)
    local b2 = transform_point_slow(camera, b)
    line(a2[1], a2[2], b2[1], b2[2], color)
end

function _update()
	framenum += 1
    printh("vv")
    
    if btn(0) then fwd = mv4(m_rot_xyz(0,0.05,0), fwd) end
    if btn(1) then fwd = mv4(m_rot_xyz(0,-0.05,0), fwd) end
    if btn(2) then fwd = mv4(m_rot_xyz(0,0,0.05), fwd) end
    if btn(3) then fwd = mv4(m_rot_xyz(0,0,-0.05), fwd) end    
    model.rotation = m_look(fwd, v_norm({0,1,0}))
    model.update_points()
    printh("^^")
    mx, my, mb = stat(32), stat(33), stat(34)
    if mode == "color" then update_color() else update_path() end



    if btn(5) then
        label="tris"
        --mode = (mode == "color") and "path" or "color"
    else
        label = "points"
    end
	model.update_points()
end

function draw_color()
	cls()
    sprites = {}
	render(models, sprites, camera, 128, 128, function(x,y) end, 90)
    draw_line({0,0,0}, v_mul({model.rotation[9], model.rotation[10], model.rotation[11]}, 2), 6 )
    draw_line({0,0,0}, v_mul({model.rotation[1], model.rotation[2], model.rotation[3]}, 2), 8 )
    draw_line({0,0,0}, v_mul({model.rotation[5], model.rotation[6], model.rotation[7]}, 2), 12 )
    draw_line({0,0,0}, v_mul(fwd, 2), 7 )
end

function _draw()
    if mode == "color" then draw_color() else draw_path() end
    spr(1, mx, my)
    ?time, 1, 1, 8
end