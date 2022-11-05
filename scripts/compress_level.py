from operator import indexOf
import os

os.system("cp lorez2.p8 lorez2_base.p8")

# TODO: use FF on path to copy everything until props

models = ["seed", "tree", "wheel", "sarc", "gorgon1", "zig", "gorgon2"]
paths = ["none", "flower1", "tree", "wheel", "seed1", "flower2", "wheel2", "seed2", "seed3", "tree2", "sarc", "gorgon2", "zig"]
prop_names = ["reveal_t", "reveal_co", "one_at_a_time", "finish_time", "fixed_angle", "scale", "x_co", "y_co", "z_co", "score_mul", "heal", "homing_ratio", "set_key", "start_key"]

current_z = -45
last_args = None

def compress(line):
    model, x, y, z, path, pathscale, speed, beats, targets, missiles, props = line.split(",")
    def pack(value, nibbles, smallest, centered_on_zero = True):
        pv = round(value / smallest)
        if centered_on_zero: pv += 2 ** (nibbles * 4 - 1) - 1
        if len(hex(pv)) > nibbles + 2: raise Exception("hex result too big: " + str(value) + " pv=" + str(pv))
        return hex(pv)[2:].rjust(nibbles, "0")
    def lookup(value, look_in):
        return pack(look_in.index(value), 2, 1, False)        
    def parse_possible_binary(s):
        if s == "-1":
            return 0xffff
        if s.startswith("0b"):
            return int(s[2:],2)
        return int(s)
    def pack_props(props):
        if props:
            s = pack(len(props.split(";")),1,1,False)
            for prop in props.split(";"):
                k,v = prop.split("=")
                s += lookup(k, prop_names)
                s += pack(float(v),2,0.1,True)
        else:
            s = pack(0, 1, 1, False)
        return s
    def pack_targets(targets):
        if targets:
            s = pack(len(targets.split(";")),2,1,False)
            for target in targets.split(";"):
                s += pack(int(target), 2, 1, False)
        else:
            s = pack(0, 2, 1, False)
        return s

    sep = ""
    global current_z, last_args
    current_z -= float(z)
    ret = \
        lookup(model, models) + sep + \
        pack(float(x), 2, 0.25) + sep + \
        pack(float(y), 2, 0.25) + sep + \
        pack(-current_z - 40, 4, 0.125, False) + sep

    cur_args = \
        lookup(path, paths) + sep + \
        pack(float(pathscale), 2, 0.1) + sep + \
        pack(float(speed), 2, 0.1, False) + sep + \
        pack(parse_possible_binary(beats), 4, 1, False) + sep + \
        pack_targets(targets) + sep + \
        pack(parse_possible_binary(missiles), 4, 1, False) + sep

    if cur_args == last_args:
        ret += "ff"
        print("[copy]")
    else:
        ret += cur_args

    last_args = cur_args

    ret += pack_props(props)
    return ret

out = ""
with open("level.txt") as f:
    s = ""
    for line in f:
        print(line.strip())
        if line.startswith("--"): break
        if len(line) > 1:
            #print()
            #print(line.strip())
            cline = compress(line.strip())
            print(cline)
            s += cline
    s += "f"
    s = s.ljust(8192, "f")
    for i in range(32):
        out += s[i * 256:(i + 1) * 256] + "\n"

with open("lorez2_base.p8") as fi:
    with open("lorez2.p8", "w") as fo:
        in_map = False
        for line in fi:
            if line.strip() == "__map__":
                in_map = True
                fo.write("__map__\n")
                fo.write(out + "\n")
            elif line.strip().startswith("__"):
                in_map = False
            if not in_map:
                fo.write(line)

os.system("python3 ~/Downloads/shrinko8-main/shrinko8.py lorez2.p8 lorez2-min.p8 --minify --preserve \"*.*\"")