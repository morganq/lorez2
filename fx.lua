--[[explosion_colors = split"7,7,10,8,6,5"
function make_explosion(pt)
    local time,bs = 0,rnd(2) + 1
    add(sprites, sprite(pt, function(self, x, y, size)
        time += 1
        circfill(x, y, size * max(7 - time / 3, 0) * bs, explosion_colors[min(time \ 4 + 1, 6)])
        if time > 20 then
            del(sprites, self)
        end
    end))
end
]]
num_splashes = 4
function make_splash(pt)
    local time = 0
    num_splashes += 1
    add(sprites, sprite(pt, function(self, x, y, size)
        pal(split"1,2,3,4,3,10,7,8,9,10,11,12,11,14,15")
        time += 1.3
        
        self.background = true
        
        x2 = x \ 8 * 8
        y2 = y \ 8 * 8
        size = mid(size * 2, 0.35, 1.25)
        local rad = 96 / num_splashes
        local s1 = 16 * size
        local sv = sin(time / 20) * 13.5 / size
        for ix = x2 - rad, x2 + rad, 8 do
            for iy = y2 - rad, y2 + rad, 8 do
                local dx, dy = (ix - x) / rad, (iy - y) / rad
                spr(mid(sv * (1-sqrt(dx ^ 2 + dy ^ 2)) + 1,1,11)\1, ix, iy)
            end
        end
        
        pal()
        circ(x, y, (size * 20) + 20 - time * 2, 11)
        if time > 60 then
            del(sprites, self)
            num_splashes -= 1
        end
    end))
end
