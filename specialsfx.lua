sfx_callback_table = {}
for i = 1, 32 do add(sfx_callback_table, {}) end

local sfx_pattern_mem = 0x3200 + 68 * 8

function add_sfx(bstring, callback)
    local n = (stat(53) + 1) % 32
    local b1, b2 = unpack(split(bstring))
    poke(sfx_pattern_mem + n * 2, b1)
    poke(sfx_pattern_mem + 1 + n * 2, b2)
    add(sfx_callback_table[n], callback)
end

last_beat_num = 0
function update_sfx()
    local n = stat(53)
    if n != last_beat_num then
        last_beat_num = n
        for cb in all(sfx_callback_table[n]) do
            cb()
        end
        poke(sfx_pattern_mem + n * 2, 0)
        poke(sfx_pattern_mem + 1 + n * 2, 0)        
        sfx_callback_table[n] = {}
    end
end