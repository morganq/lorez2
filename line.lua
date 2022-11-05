function make_line(p1, p2, color, sphere_rad, sphere_color)
    local other_rendered, other_pos, l = false, {}, {rad = sphere_rad}
    for p in all({p1, p2}) do
        local s = sprite(p, function(self,x,y,size)
            if not other_rendered then
                other_rendered = true
                other_pos = {x,y,size}
            else
                other_rendered = false
                if true then -- abs(other_pos[1] - x) >= 1 or abs(other_pos[2] - y) >= 1 then
                    line(other_pos[1], other_pos[2], x, y, color)
                    if l.rad then
                        circfill(x, y, l.rad * size, sphere_color or color)
                        circfill(other_pos[1], other_pos[2], l.rad * size, sphere_color or color)
                    end
                end
            end
        end)
        add(sprites, s)
    end
    l.s1, l.s2 = sprites[#sprites-1], sprites[#sprites]
    return l
end