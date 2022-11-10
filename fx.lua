-- Contains the "splash" effect when you destroy an entity

function make_splash(pt)
    local time = 0
    local f1, f2 = rnd(1) > 0.5, rnd(1) > 0.5
    local s1, s2 = rnd(1)/4 + 0.25, rnd(1)/4 + 0.25
    add(sprites, sprite(pt, function(self, x, y, size)
        pal(split"0,0,0,0,9,0,0,0,0,0,0,0,10,0,0")
        time += 1.3
        s1 *= 1.025
        s2 *= 1.025
        fillp(pat[mid(smooth(time/30, 0.5) * 14 \ 1 + 1,1,16)] | 0b0.111)
        self.background = true
        local v1 = (size + 0.2) * 30
        local v2 = v1 * 2
        sspr(96, 32, 32, 32, x-v1*s1, y-v1*s2, v2*s1, v2*s2, f1, f2)

        pal()
        if time < 20 then
            fillp()
            circ(x, y, size * (smooth(time / 40 + 0.5) * 190 - 100), 7)
        end
        if time > 60 then
            del(sprites, self)
        end
    end))
end
