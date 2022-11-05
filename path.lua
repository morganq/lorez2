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
--[[
function interp_smooth(path, keyframes, t, var)
    var = var or 0.025
    local res_1 = interp(path, keyframes, max(t - var, 0))
    local res_2 = interp(path, keyframes, t)
    local res_3 = interp(path, keyframes, min(t + var, 1))
    local res = {}
    for i = 1, 6 do
        --res[i] = res_1[i] * 0.25 + res_2[i] * 0.5 + res_3[i] * 0.25
        res[i] = res_1[i] * 0.5 + res_3[i] * 0.5
    end
    --printh("path " .. v2s(res))
    return res
end
]]