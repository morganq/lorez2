-- 3d engine

-- Use "normal" sin and cos fns rather than p8's
p8cos = cos function cos(angle) return p8cos(angle/(3.1415*2)) end
p8sin = sin function sin(angle) return -p8sin(angle/(3.1415*2)) end


----- VECTORS -----
function v_add(a,b) return {a[1] + b[1], a[2] + b[2], a[3] + b[3], 1} end
function v_sub(a,b) return {a[1] - b[1], a[2] - b[2], a[3] - b[3], 1} end
function v_mul(a,s) return {a[1] * s, a[2] * s, a[3] * s, 1} end

-- Special vector mag function which does not easily overflow on big distances
function v_mag(v)
    local d=max(max(abs(v[1]),abs(v[2])),abs(v[3]))
    local x,y,z=v[1]/d,v[2]/d,v[3]/d
    return (x*x+y*y+z*z)^0.5*d
end
function v_norm(v)
	local d = v_mag(v)
	return {v[1] / d, v[2] / d, v[3] / d, 1}
end
function v_cross(a,b)
	return {a[2] * b[3] - b[2] * a[3], a[3] * b[1] - b[3] * a[1], a[1] * b[2] - b[1] * a[2], 1}
end
function v_dot(a,b) return a[1]*b[1] + a[2] * b[2] + a[3] * b[3] end

function v_zero() return {0,0,0,1} end


----- MATRICES -----

-- Multiply two matrices. We want to use this function as *infrequently as possible!*
-- To reduce tokens we unpack the vectors and avoid lots of []
function mm4(a,b)
	local a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16 = unpack(a)
	local b1,b2,b3,b4,b5,b6,b7,b8,b9,b10,b11,b12,b13,b14,b15,b16 = unpack(b)
	return {
		a1*b1+a2*b5+a3*b9+a4*b13,
		a1*b2+a2*b6+a3*b10+a4*b14,
		a1*b3+a2*b7+a3*b11+a4*b15,
		a1*b4+a2*b8+a3*b12+a4*b16,

		a5*b1+a6*b5+a7*b9+a8*b13,
		a5*b2+a6*b6+a7*b10+a8*b14,
		a5*b3+a6*b7+a7*b11+a8*b15,
		a5*b4+a6*b8+a7*b12+a8*b16,

		a9*b1+a10*b5+a11*b9+a12*b13,
		a9*b2+a10*b6+a11*b10+a12*b14,
		a9*b3+a10*b7+a11*b11+a12*b15,
		a9*b4+a10*b8+a11*b12+a12*b16,

		a13*b1+a14*b5+a15*b9+a16*b13,
		a13*b2+a14*b6+a15*b10+a16*b14,
		a13*b3+a14*b7+a15*b11+a16*b15,
		a13*b4+a14*b8+a15*b12+a16*b16,
	}
end

-- Matrix * Vector
function mv4(m, v)
	local m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15, m16 = unpack(m)
	local vx, vy, vz, vw = unpack(v)
	return {
		m1 * vx +    m2 * vy +    m3 * vz +    m4 * vw,
		m5 * vx +    m6 * vy +    m7 * vz +    m8 * vw,
		m9 * vx +    m10 * vy +   m11 * vz +   m12 * vw,
		m13 * vx +   m14 * vy +   m15 * vz +   m16 * vw
	}
end

-- Create a transformation matrix from euler rotations
-- This is done in a particular order based on the needs of the game
function m_rot_xyz(a,b,c)
	local sa, ca, sb, cb, sc, cc = sin(a), cos(a), sin(b), cos(b), sin(c), cos(c)
	return {
		cb * cc, sa * sb - ca * cb * sc, sa * cb * sc + ca * sb, 0,
		sc, ca * cc, sa * -cc, 0,
		sb * -cc, ca * sb * sc + sa * cb, ca * cb - sa * sb * sc, 0,
		0,0,0,1
	}
end

-- Transformation matrix from fwd and up vectors
function m_look(fwd, up)
	local left = v_norm(v_cross(up, fwd))
	local new_up = v_norm(v_cross(fwd, left))
	return {
		left[1], left[2], left[3], 0,
		new_up[1], new_up[2], new_up[3], 0,
		fwd[1], fwd[2], fwd[3], 0,
		0,0,0,1
	}
end

-- Perspective transform
function m_perspective(near, far, width, height)
	return {
		(2 - near) / width, 0, 0, 0,
		0, (2-near) / height, 0, 0,
		0, 0, -(far + near) / (far - near), (-2 * far * near) / (far - near),
		0,0,-1,0
	}
end

function m_identity()
	local m = split"1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1"
	m.is_identity = true
	return m
end

-- Stolen from the BBS somewhere...
function polyfill(p,col)
	color(col)
	local p0,nodes=p[#p],{}
	local x0,y0=p0[1],p0[2]

	for i=1,#p do
		local p1=p[i]
		local x1,y1=p1[1],p1[2]
		local _x1,_y1=x1,y1
		if(y0>y1) x0,y0,x1,y1=x1,y1,x0,y0
		local cy0,cy1,dx=y0\1+1,y1\1,(x1-x0)/(y1-y0)
		if(y0<0) x0-=y0*dx y0=0
	   	x0+=(-y0+cy0)*dx
		for y=cy0,min(cy1,127) do
			local x=nodes[y]
			if x then
				local x,x0=x,x0
				if(x0>x) x,x0=x0,x
				rectfill(x0+1,y,x,y)
			else
			 nodes[y]=x0
			end
			x0+=dx					
		end			
		x0,y0=_x1,_y1
	end
end

----- 3D -----

-- Clip a list of points at the close Z plane
-- This is based on a common algorithm but with the other 5 planes
-- removed beacuse they're not very important to clip and it's expensive.
function geo_clip(points)
	local new_points = {}	
	for i = 1, #points do
		local s,e = points[i], points[i % #points + 1]

		local s_in, e_in = s[3] <= -s[4], e[3] <= -e[4]
		if s_in != e_in then
			local t = (-s[4]-s[3])/(e[3]-s[3]+e[4]-s[4])
			add(new_points, {
				s[1] + (e[1] - s[1]) * t,
				s[2] + (e[2] - s[2]) * t,
				s[3] + (e[3] - s[3]) * t,
				s[4] + (e[4] - s[4]) * t,
			})
		end
		if e_in then
			add(new_points, e)
		end
	end
	return new_points
end

--gray = split"1,2,5,4,13,13,6,6,6,15,15,7"
gray = split"0,5,13,6,10,7,7"
distance_colors = split"7,10,9,4,2"

-- Necessary sometimes to do a one-off transformation of a point to get its
-- 2d position
function transform_point_slow(camera, point)
	local hp = mv4(frame_matrix, v_sub(point, camera.pos))
	return {hp[1] / hp[4] * 64 + 64, hp[2] / hp[4] * 64 + 64, 0, 1}
end

-- Big ol render function which wants a list of models, sprites,
-- a camera definition, screen width and height, a callback for drawing
-- the skybox, and a field of view value
function render(models, sprites, camera, w, h, draw_skybox, fov)
	local hw, hh, nbins, znear, zfar, fv = w\2,h\2,512,-0.5,90,3.2 * (fov / 90)
	--local up = v_norm({sin(framenum / 30) / 25,1,0,1})
	local m = mm4(m_perspective(znear, -zfar, fv, fv), m_look(camera.fwd, {0,1,0,1}))
	frame_matrix = m
	local tris, zbins = 0, {}
	for i = 1,nbins do add(zbins, {}) end

	local m1,m2,m3,m4,m5,m6,m7,m8,m9,m10,m11,m12,m13,m14,m15,m16 = unpack(m)
	local cpx, cpy, cpz = camera.pos[1], camera.pos[2], camera.pos[3]

	local reject = false

	local sundir = v_norm({-0.33,1,0.13,1})

	for mi = 1, #models do
		local model = models[mi]
		local m_sr = m
		if model.special_rotation then
			m_sr = mm4(m, model.special_rotation)
			m1,m2,m3,m4,m5,m6,m7,m8,m9,m10,m11,m12,m13,m14,m15,m16 = unpack(m_sr)
		end
		local spx, spy, spz = model.special_offset[1], model.special_offset[2], model.special_offset[3]
		local homog_points = {}
		for ti = 1,#model.triangles do
			local t = model.triangles[ti]
			tris += 1
			local indices = t.point_indices
			local norm = t.normal
			local dirx, diry, dirz = t.center[1] - cpx + spx, t.center[2] - cpy + spy, t.center[3] - cpz + spz
			local dot = dirx * norm[1] + diry * norm[2] + dirz * norm[3]   
			reject = dirz > 6
			if not reject and (t.skip_cull or dot < 0 or model.special_rotation) then
				tp = {}
				homp = {}
				local all_within = true
				local all_without = true		
				for i = 1,#indices do
					local index = indices[i]
					local cached = homog_points[index]
					if not cached then
						local mpi = model.points[index]
						local x = mpi[1] - cpx + spx
						local y = mpi[2] - cpy + spy
						local z = mpi[3] - cpz + spz
						local w2 = m13 * x + m14 * y + m15 * z
						local x2 = (m1 * x + m2 * y + m3 * z)
						local y2 = (m5 * x + m6 * y + m7 * z)
						local z2 = (m9 * x + m10 * y + m11 * z + m12)
						
						local pt_within = x2 <= -w2 and x2 >= w2 and y2 <= -w2 and y2 >= w2 and z2 <= -w2 and z2 >= w2						
						homog_points[index] = {x2, y2, z2, w2, pt_within}
					end
					homp[i] = homog_points[index]
					all_within = all_within and homp[i][5]
					all_without = all_without and not homp[i][5]
				end
				if not reject then
					if not all_within and not all_without then
						homp = geo_clip(homp)
					end
					if not all_without and #homp > 2 then
						local minz = 1
						for i = 1, #homp do
							local pt = homp[i]
							homp[i] = {pt[1] / pt[4] * (hw+1) + hw - 0.5, pt[2] / pt[4] * (hh+1) + hh - 0.5, pt[3] / pt[4]}
							minz = min(homp[i][3], minz)
						end
						t.min_dist = minz + (abs(t.center[1]) + abs(t.center[2])) / 3
						local distsq = dirx * dirx + diry * diry + dirz * dirz
						local bin = nbins - flr(sqrt(distsq) / zfar * nbins + 1)
						add(zbins[bin], {
							1,
							homp,
							t
						})
					end
				end
			end
		end
		if model.special_rotation then
			m1,m2,m3,m4,m5,m6,m7,m8,m9,m10,m11,m12,m13,m14,m15,m16 = unpack(m)
		end
	end

	for si = 1, #sprites do
		local s = sprites[si]
		local x = (s.pos[1] - cpx)
		local y = (s.pos[2] - cpy)
		local z = (s.pos[3] - cpz) 
		local w2 = m13 * x + m14 * y + m15 * z
		local x2 = (m1 * x + m2 * y + m3 * z)
		local y2 = (m5 * x + m6 * y + m7 * z)
		local z2 = (m9 * x + m10 * y + m11 * z + m12) 
		aw2 = abs(w2) * 2
		if abs(z2) < abs(w2) and abs(x2) < aw2 and abs(y2) < aw2 then
			local scalex = 1
			local distsq = x * x + y * y + z * z
			local bin = nbins - flr(distsq / (zfar * zfar) * nbins + 1)
			--local size = 18 / (distsq ^ 0.70)
			local size = 5 / sqrt(distsq)
			if s.background then bin = 1 end
			local fx = x2 / w2 * hw + hw
			local fy = y2 / w2 * hh + hh
			add(zbins[bin], { 2, {fx, fy, size}, s })
		end        
	end
	--printh("tris: " .. tris .. " / within: " .. within .. " / without: " .. without .. " / clipped: " .. clipped .. " / rejected: " .. rejected)

	local horizon_pt = {0, 0, camera.pos[3] - 500, 1}
	local h2d = mv4(m, horizon_pt)
	h2d[1] = h2d[1] / h2d[4]
	h2d[2] = h2d[2] / h2d[4]
	draw_skybox(h2d[1] * hw + hw, h2d[2] * hh + hh)

	for bin = 1, nbins do   
		local contents = zbins[bin]
		for j = 1, #contents do
			local render_type, points, o = unpack(contents[j])
			if render_type == 1 then
				local norm, c = o.normal, o.color
				local fill = 0b0
				if bin < nbins * 0.1 then
					fill = 0b1111101011111010.1
				end				
				if c == "distance" then
					c = distance_colors[mid(points[1][3] * 3.5 \ 1, 1, 5)]
				end				
				local c1, c2 = c, c
				if c > 15 then
					c1 = c \ 16
					c2 = c % 16
				end
				
				local too_close = o.min_dist < 0.8

				if o.color < 0 then
					local vd = mid((v_dot(norm, sundir) + 0.5) * 5, 1, 7)
					c1 = gray[vd\1] * 16 + gray[(vd + 0.5)\1]
					c2 = c % 16
					fill = fill | 0b0101101001011010.01
				end
				if o.fill != 0 and not too_close then
					--color(c1)
					fillp(o.fill | fill)
					polyfill(points, c1)
				end
				if o.fill == 0 or abs(c) > 15 or too_close then
					color(c2)
					-- Wireframe
					fillp()
					for i = 1, #points do
						line(points[i][1] + 0.5, points[i][2] + 0.5, points[i % #points + 1][1] + 0.5, points[i % #points + 1][2] + 0.5)
					end
				end
				fillp()
			elseif render_type == 2 then
				o:render(points[1], points[2], points[3]) -- p1 = x, y, size
			end
			
		end
	end
	
end

----- MODELS -----

function deserialize_model(s, scale, pos)
	local scale, points, triangles, default_color, default_fill = scale or 1, {}, {}, 0, 0
	local s_verts, s_faces = unpack(split(s,"\n",false))
	
	function rhn(data, i, n)
		local val = 0
		for q = 0, n-1 do
			val += tonum(data[i+q], 0x1) << ((n - q - 1) * 4)
		end
		return val
	end
	local vd = s_verts[1]
	local max = 2 ^ (vd * 4 - 1)
	scale = scale / (2 ^ (vd * 2))
	for i = 2, #s_verts, (vd * 3) do
		add(points, {
			(rhn(s_verts, i, vd) - max) * scale,
			(rhn(s_verts, i + vd, vd) - max) * scale,
			(rhn(s_verts, i + vd * 2, vd) - max) * scale,
		})
	end
	local faces = split(s_faces, "/", false)
	for i = 1, #faces do
		local parts, extra = split(faces[i], "!", false), {}
		local face = parts[1]
		if parts[2] then extra = split(parts[2], ",") end
		default_color = extra[1] or default_color
		default_fill = extra[2] or default_fill
		local indices = {}
		if face[1] == "#" then
			for j = 2, #face, 2 do
				add(indices, rhn(face, j, 2))
			end			
		else
			for j = 1, #face, 1 do
				add(indices, ord(face, j) - 96)
			end
		end
		
		add(triangles, {point_indices = indices, color = default_color, fill = default_fill})
	end    
	return model(pos, points, triangles)
end

function update_tri(model, tri)
	local t1, t2, t3 = 
		model.points[tri.point_indices[1]],
		model.points[tri.point_indices[2]],
		model.points[tri.point_indices[3]]

	--printh(v2s(tri.point_indices))
	
	local d1, d2 = v_sub(t2, t1), v_sub(t3, t2)
	local norm = v_norm(v_cross(d1, d2))
	--printh(tri.point_indices[1] .. "," .. tri.point_indices[2] .. "," .. tri.point_indices[3] .. "," .. v2s(v_cross(d1, d2)) .. "," .. v2s(d1) .. "," .. v2s(d2))
	tri.normal = norm
	local center = {0,0,0}
	for pti in all(tri.point_indices) do
		center = v_add(center, model.points[pti])
	end
	center = v_mul(center, 1 / #tri.point_indices)
	tri.center = center
end

function model(pos, points, tris)
	local m = {
		points = {},
		base_points = points,
		triangles = tris,
		pos = pos,
		rotation = m_identity(),
		shadow = false,
		special_offset = v_zero(),
	}
	for p in all(points) do add(m.points, {p[1], p[2], p[3]}) end
	m.update_points = function()
		local m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, m11, m12, m13, m14, m15, m16 = unpack(m.rotation)
		for i = 1, #m.base_points do
			local x,y,z = unpack(m.base_points[i]) -- opt: is unpack slow?
			m.points[i][1] = m1 * x +    m5 *  y +   m9 *  z + m.pos[1]
			m.points[i][2] = m2 * x +    m6 *  y +   m10 *  z + m.pos[2]
			m.points[i][3] = m3 * x +    m7 * y +   m11 * z + m.pos[3]
		end
		for i = 1, #m.triangles do
			update_tri(m, m.triangles[i])
		end
	end
	m.update_points()
	return m
end

function sprite(pos, render)
	local s = {
		pos = pos,
		render = render
	}
	return s
end