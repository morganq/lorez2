-- Interpolation along the path data.
-- entities each have a path which determines how they move
-- Paths have x,y,z,yaw,pitch,roll for each keyframe/waypoint
-- interp gets you the interpolated 6-vector for any given t from 0-1

function interp(path, keyframes, t)
    local prev_frame, next_frame = keyframes[#keyframes], keyframes[#keyframes]
    local ta = t * next_frame
    for i,kt in pairs(keyframes) do
        if kt > ta then
            prev_frame = keyframes[max(1, i - 1)]
            next_frame = kt
            break
        end
    end
    local sub_t = (ta - prev_frame) / max(next_frame - prev_frame, 1)
    local result = {}
    for i = 1,6 do
        result[i] = path[next_frame][i] * sub_t + path[prev_frame][i] * (1 - sub_t)
    end
    return result
end
