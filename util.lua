--[[sint = {}
cost = {}
for i = 0, 1023 do
    sint[i] = sin(i * 0.006134)
    cost[i] = cos(i * 0.006134)
end]]

function obj_defaults(o, s)
	for kv in all(split(s,";")) do
		local k,v = unpack(split(kv, "="))
		if v == "false" then o[k] = false
		elseif v == "true" then o[k] = true
		else
			o[k] = v
		end
	end
end

function v2s(v)
	return v[1] .. "," .. v[2] .. "," .. v[3]
end

function fourway()
	local parts, i = {{-1,0},{0,-1},{1,0},{0,1}}, 0
	return function()
		if i < 4 then
			i+=1
			return parts[i][1], parts[i][2]
		end
	end
end

function deserialize_model_and_sprites(s, scale, pos)
	local m = deserialize_model(s, scale, pos)
	m.sprites = {}
	for pair in all(split(split(s, "\n")[3], "/")) do
		local vert, spri = unpack(split(pair, "="))
		local sp = sprite(m.points[vert], function(self, x, y, size)
			local a1, a2 = size * 24, size * 48
			sspr(spri % 16 * 8, spri \ 16 * 8, 16, 16, x - a1, y - a1, a2, a2)
		end)
		add(m.sprites, sp)
	end
	return m
end