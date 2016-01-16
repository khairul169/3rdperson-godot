extends Control

const SCALE = 13.275;

var player_pos = Vector2();
var player_rot = 0.0;

var object_list = [];
onready var obj_viewcone = load("res://assets/scenes/object_viewcone.scn");

func _ready():
	set_process(true);

func _process(delta):
	var vp = get_node("vp");
	var cam = get_node("vp/cam");
	
	cam.set_pos(player_pos*SCALE);
	cam.set_rot(player_rot);
	
	for i in object_list:
		var vc = get_node(str("vp/object_", i.get_name()));
		if vc == null:
			object_list.erase(i);
			continue;
		
		vc.set_pos(Vector2(i.get_global_transform().origin.x, i.get_global_transform().origin.z)*SCALE);
		vc.set_rot(i.get_rotation().y);
	
	var render = vp.get_render_target_texture();
	get_node("overview").set_texture(render);

func add_object(obj):
	if obj == null || is_available(obj) != null:
		return;
	
	object_list.append(obj);
	var inst = obj_viewcone.instance();
	inst.set_name(str("object_", obj.get_name()));
	inst.set_pos(Vector2(obj.get_global_transform().origin.x, obj.get_global_transform().origin.z)*SCALE);
	inst.set_rot(obj.get_rotation().y);
	
	get_node("vp").add_child(inst);

func is_available(obj):
	for i in object_list:
		if i == obj:
			return i;
	return null;