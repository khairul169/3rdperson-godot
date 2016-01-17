extends Spatial

var cam_pitch = 0.0;
var cam_yaw = 0.0;
var cam_cpitch = 0.0;
var cam_cyaw = 0.0;
var cam_currentradius = 2.0;
var cam_radius = 2.0;
var cam_pos = Vector3();
var cam_ray_result = {};
var cam_smooth_movement = true;
var cam_fov = 60.0;
var cam_view_sensitivity = 0.3;
var cam_smooth_lerp = 10;
var cam_pitch_minmax = Vector2(90, -90);

var is_enabled = false;
var collision_exception = [];

export(NodePath) var cam;
export(NodePath) var pivot;

func _ready():
	cam = get_node(cam);
	pivot = get_node(pivot);
	
	cam_fov = cam.get_fov();

func set_enabled(enabled):
	if enabled:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);
		set_process(true);
		set_fixed_process(true);
		set_process_input(true);
		is_enabled = true;
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE);
		set_process(false);
		set_fixed_process(false);
		set_process_input(false);
		is_enabled = false;

func clear_exception():
	collision_exception.clear();

func add_collision_exception(node):
	collision_exception.push_back(node);

func _input(ie):
	if !is_enabled:
		return;
	
	if ie.type == InputEvent.MOUSE_MOTION:
		cam_pitch = max(min(cam_pitch+(ie.relative_y*cam_view_sensitivity),cam_pitch_minmax.x),cam_pitch_minmax.y);
		if cam_smooth_movement:
			cam_yaw = cam_yaw-(ie.relative_x*cam_view_sensitivity);
		else:
			cam_yaw = fmod(cam_yaw-(ie.relative_x*cam_view_sensitivity),360);
			cam_currentradius = cam_radius;
			cam_update();
	
	if ie.type == InputEvent.MOUSE_BUTTON:
		if ie.pressed:
			if ie.button_index == BUTTON_WHEEL_UP:
				cam_radius = max(min(cam_radius-0.2,4.0),1.0);
			elif ie.button_index == BUTTON_WHEEL_DOWN:
				cam_radius = max(min(cam_radius+0.2,4.0),1.0);

func _process(delta):
	if !is_enabled:
		return;
	
	if !cam.is_current():
		cam.make_current();
	
	if cam.get_projection() == Camera.PROJECTION_PERSPECTIVE:
		cam.set_perspective(lerp(cam.get_fov(), cam_fov, cam_smooth_lerp*delta), cam.get_znear(), cam.get_zfar());
	
	if cam_smooth_movement:
		cam_cpitch = lerp(cam_cpitch, cam_pitch, 10*delta);
		cam_cyaw = lerp(cam_cyaw, cam_yaw, 10*delta);
		cam_currentradius = lerp(cam_currentradius, cam_radius, 5*delta);
	
	cam_update();

func cam_update():
	cam_pos = pivot.get_global_transform().origin;
	
	if cam_smooth_movement:
		cam_pos.x += cam_currentradius * sin(deg2rad(cam_cyaw)) * cos(deg2rad(cam_cpitch));
		cam_pos.y += cam_currentradius * sin(deg2rad(cam_cpitch));
		cam_pos.z += cam_currentradius * cos(deg2rad(cam_cyaw)) * cos(deg2rad(cam_cpitch));
	else:
		cam_pos.x += cam_currentradius * sin(deg2rad(cam_yaw)) * cos(deg2rad(cam_pitch));
		cam_pos.y += cam_currentradius * sin(deg2rad(cam_pitch));
		cam_pos.z += cam_currentradius * cos(deg2rad(cam_yaw)) * cos(deg2rad(cam_pitch));
	
	var pos = Vector3();
	
	if cam_ray_result.size() != 0:
		var a = (cam_ray_result.position-pivot.get_global_transform().origin).normalized();
		var b = pivot.get_global_transform().origin.distance_to(cam_ray_result.position);
		#pos = cam_ray_result.position;
		pos = pivot.get_global_transform().origin+a*max(b-0.5, 0);
	else:
		pos = cam_pos;
	
	cam.look_at_from_pos(pos, pivot.get_global_transform().origin, Vector3(0,1,0));

func _fixed_process(delta):
	if !is_enabled:
		return;
	
	var ds = get_world().get_direct_space_state();
	if ds != null:
		cam_ray_result = ds.intersect_ray(pivot.get_global_transform().origin, cam_pos, collision_exception);