pat=split"0b1111111111111111,0b0111111111111111,0b0111111111011111,0b0101111111011111,0b0101111101011111,0b0101101101011111,0b0101101101011110,0b0101101001011110,0b0101101001011010,0b0001101001011010,0b0001101001001010,0b0000101001001010,0b0000101000001010,0b0000001000001010,0b0000001000001000,0b0"

function smooth(t, pow)
	return cos(t * 3.14159) ^ (pow or 1) * -0.5 + 0.5
end

function populate_table(o, s)
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
			local a1, a2 = size * 48, size * 96
			sspr(spri % 16 * 8, spri \ 16 * 8, 16, 16, x - a1, y - a1, a2, a2)
		end)
		add(m.sprites, sp)
	end
	return m
end

function mapfilter(l, f)
	local res = {}
	for item in all(l) do
		local ret = f(item)
		if ret != nil then add(res, ret) end
	end
	return res
end

function copy(l) return mapfilter(l, function(i) return i end) end