bl_info = {
    "name": "Export PICO-8",
    "blender": (2, 80, 0),
    "category": "Object",
}

colors = [
    (0, 0, 0),
    (29, 43, 83),
    (126, 37, 83),
    (0, 135, 81),
    (171, 82, 54),
    (95, 87, 79),
    (194, 195, 199),
    (255, 241, 232),
    (255, 0, 77),
    (255, 163, 0),
    (255, 236, 39),
    (0, 228, 54),
    (41, 173, 255),
    (131, 118, 156),
    (255, 119, 168),
    (255, 204, 170),
]
ext_colors = [
    (41,24,20),
    (17,29,53),
    (66,33,54), 
    (18,83,89),
    (116,47,41),
    (73,51,59),
    (162,136,121),
    (243,239,125),
    (190,18,80),
    (255,108,36),
    (168,231,46),
    (0,181,67),
    (6,90,181),
    (117,70,101),
    (255,110,89),
    (255,157,129),
]

charmap = ['spacer', 'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','{','|','}','~','○','█','▒','🐱','⬇️','░','✽','●','♥','☉','웃','⌂','⬅️','😐','♪','🅾️','◆','…','➡️','★','⧗','⬆️','ˇ','∧','❎','▤','▥','あ','い','う','え','お','か','き','く','け','こ','さ','し','す','せ','そ','た','ち','つ','て','と','な','に','ぬ','ね','の','は','ひ','ふ','へ','ほ','ま','み','む','め','も','や','ゆ','よ','ら','り','る','れ','ろ','わ','を','ん','っ','ゃ','ゅ','ょ','ア','イ','ウ','エ','オ','カ','キ','ク','ケ','コ','サ','シ','ス','セ','ソ','タ','チ','ツ','テ','ト','ナ','ニ','ヌ','ネ','ノ','ハ','ヒ','フ','ヘ','ホ','マ','ミ','ム','メ','モ','ヤ','ユ','ヨ','ラ','リ','ル','レ','ロ','ワ','ヲ','ン','ッ','ャ','ュ','ョ','◜','◝']

target_file = "~/Desktop/Projects/pico8/lorez2/temp.lua"

use_ints = True

vert_depth = 3
scale = 2 ** (vert_depth * 2)

import bpy

def print(data):
    for window in bpy.context.window_manager.windows:
        screen = window.screen
        for area in screen.areas:
            if area.type == 'CONSOLE':
                override = {'window': window, 'screen': screen, 'area': area}
                bpy.ops.console.scrollback_append(override, text=str(data), type="OUTPUT")


def execute(context):
    # The original script
    scene = context.scene
    n = 1
    verts = []
    faces = []
    for obj in scene.objects:
        for vert in obj.data.vertices:
            world_pos = obj.matrix_world @ vert.co
            verts.append(world_pos)
        
    
        for poly in obj.data.polygons:
            face = {"points":[], "fill":"0b0.01", "color":"0"}
            
            
            best_ci = None
            best_sqd = float("inf")
            try:
                mat = obj.material_slots[poly.material_index].material
                inputs = mat.node_tree.nodes["Toon BSDF"].inputs
                mc = inputs["Color"].default_value
            except Exception:
                mc = [255,255,255]
            for i,rc in enumerate(colors):
                sqd = (mc[0] * 255 - rc[0]) ** 2 + \
                    (mc[1] * 255 - rc[1]) ** 2 + \
                    (mc[2] * 255 - rc[2]) ** 2
                if sqd < best_sqd:
                    best_ci = i
                    best_sqd = sqd
            #print("%f,%f,%f" % (mc[0] * 255, mc[1] * 255, mc[2]*255))
            print(best_ci)
            face["color"] = str(best_ci)
            for loop_index in range(poly.loop_start, poly.loop_start + poly.loop_total):
                ind = n + obj.data.loops[loop_index].vertex_index
                face["points"].append(ind)
            faces.append(face)
            
        n += len(obj.data.vertices)
        
    def num_str(x):
        fmt_st = "%0" + str(vert_depth) + "x"
        max = 2 ** (vert_depth * 4 - 1)
        if x * scale > max or x * scale < -max:
            print("TOO BIG!!")
        return fmt_st % int(x * scale + max)
    
    def face_str(face):
        for pt in face["points"]:
            if v > 158:
                return "#" + "".join(["%02x" % v for v in face["points"][::-1]])
        return "".join([charmap[v] for v in face["points"][::-1]])
            
        
        
    #verts_s = "/".join(["%s,%s,%s" % (num_str(v.x), num_str(v.z), num_str(v.y)) for v in verts])
    verts_s = str(vert_depth)
    for v in verts:
        verts_s += num_str(v.x) + num_str(v.z) + num_str(v.y)
    
    prepped_faces = []
    faces.sort(key=lambda x:x['color'])
    last_color = None
    last_fill = None
    for face in faces:
        s = "".join(face_str(face))
        if (face['fill'] != "0" or face['color'] != "0") and (last_color != face["color"] or last_fill != face["fill"]):
            s += "!" + face.get('color',"0") + "," + face.get('fill', "0")
            last_color = face["color"]
            last_fill = face["fill"]
        prepped_faces.append(s)
    faces_s = "/".join(prepped_faces)
    
    with open(target_file, "w") as f:
        f.write("[[" + verts_s + "\n" + faces_s + "]]")
        
        

class ExportPico(bpy.types.Operator):
    """Exports a Scene as a custom PICO-8 format"""      # Use this as a tooltip for menu items and buttons.
    bl_idname = "object.export_pico"        # Unique identifier for buttons and menu items to reference.
    bl_label = "Export PICO-8"         # Display name in the interface.
    bl_options = {'REGISTER'}  # Enable undo for the operator.

    def execute(self, context):        # execute() is called when running the operator.
        execute(context)
        return {'FINISHED'}            # Lets Blender know the operator finished successfully.

def menu_func(self, context):
    self.layout.operator(ExportPico.bl_idname)

def register():
    bpy.utils.register_class(ExportPico)
    bpy.types.VIEW3D_MT_object.append(menu_func)  # Adds the new operator to an existing menu.

def unregister():
    bpy.utils.unregister_class(ExportPico)


# This allows you to run the script directly from Blender's Text editor
# to test the add-on without having to install it.
if __name__ == "__main__":
    execute(bpy.context)