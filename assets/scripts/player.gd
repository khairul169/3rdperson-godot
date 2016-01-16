extends KinematicBody

const MAX_SLOPE_ANGLE = 45;

var g_Time = 0.0;
var cam = null;

var view_sensitivity = 0.2;
var focus_view_sensv = 0.1;
var walk_speed = 2.2;
var run_multiplier = 2.0;
var move_speed = walk_speed;
var jump_speed = 3;
var gravity = -9.8;
var gravity_factor = 3;
var acceleration = 4;
var deacceleration = 10;

var velocity = Vector3();
var is_moving = false;
var on_floor = false;

var focus_switchtime = 0.0;
var focus_mode = false;
var focus_right = true;

func _ready():
	get_node("ray").add_exception(self);
	
	cam = get_node("cam");
	
	if cam.has_method("set_enabled"):
		cam.set_enabled(true);
	
	cam.add_collision_exception(self);
	cam.cam_radius = 2.5;
	cam.cam_focus = Vector3(0,0.25,0);
	cam.cam_pitch_minmax = Vector2(80, -60);
	cam.cam_view_sensitivity = view_sensitivity;
	cam.cam_smooth_movement = true;
	
	set_process(true);
	set_fixed_process(true);
	set_process_input(true);

func _input(ie):
	if ie.type == InputEvent.MOUSE_BUTTON:
		if ie.pressed && ie.button_index == BUTTON_RIGHT && g_Time > focus_switchtime:
			focus_mode = !focus_mode;
			focus_switchtime = g_Time + 0.2;
			
			if focus_mode:
				cam.cam_fov = 45.0;
				cam.cam_pitch_minmax = Vector2(30, -10);
				cam.cam_view_sensitivity = focus_view_sensv;
				
			else:
				cam.cam_fov = 80.0;
				cam.cam_pitch_minmax = Vector2(80, -60);
				cam.cam_view_sensitivity = view_sensitivity;
		
	if ie.type == InputEvent.KEY:
		if ie.pressed && Input.is_key_pressed(KEY_F1):
			OS.set_window_fullscreen(!OS.is_window_fullscreen());
		
		if ie.pressed && Input.is_key_pressed(KEY_ESCAPE):
			get_tree().call_deferred("quit");

func _process(delta):
	g_Time += delta;
	
	var overview_map = get_node("/root/main/gui/map_overview");
	overview_map.player_pos = Vector2(get_global_transform().origin.x, get_global_transform().origin.z);
	overview_map.player_rot = deg2rad(cam.cam_yaw);

func _fixed_process(delta):
	check_movement(delta);
	player_on_fixedprocess(delta);

func check_movement(delta):
	var ray = get_node("ray");
	var aim = get_node("body").get_global_transform().basis;
	
	var g = gravity*gravity_factor;
	
	if on_floor:
		g = 0;
		if !is_moving:
			velocity.y = 0;
		if velocity.length() < 0.01:
			velocity = Vector3();
	
	is_moving = false;
	var direction = Vector3();
	
	if Input.is_key_pressed(KEY_W):
		is_moving = true;
		direction -= aim[2];
		
		if Input.is_key_pressed(KEY_A) && focus_mode:
			direction -= aim[0];
		if Input.is_key_pressed(KEY_D) && focus_mode:
			direction += aim[0];
	elif Input.is_key_pressed(KEY_S):
		is_moving = true;
		
		if focus_mode:
			direction += aim[2];
		else:
			direction -= aim[2];
		
		if Input.is_key_pressed(KEY_A) && focus_mode:
			direction -= aim[0];
		if Input.is_key_pressed(KEY_D) && focus_mode:
			direction += aim[0];
	elif Input.is_key_pressed(KEY_A):
		is_moving = true;
		
		if focus_mode:
			direction -= aim[0];
		else:
			direction -= aim[2];
	elif Input.is_key_pressed(KEY_D):
		is_moving = true;
		
		if focus_mode:
			direction += aim[0];
		else:
			direction -= aim[2];
	
	direction.y = 0;
	direction = direction.normalized()
	
	velocity.y += g*delta;
	
	var hvel = velocity;
	hvel.y = 0;
	
	var target = direction*move_speed;
	var accel = deacceleration;
	
	if direction.dot(hvel) > 0:
		accel = acceleration;
	
	hvel = target;
	#hvel = hvel.linear_interpolate(target,accel*delta);
	velocity.x = hvel.x;
	velocity.z = hvel.z;
	
	var motion = velocity*delta;
	motion = move(motion);
	
	on_floor = ray.is_colliding();
	
	var original_vel = velocity;
	var attempts=4;
	
	if motion.length() > 0:
		while is_colliding() && attempts:
			var n = get_collision_normal();
		
			if (rad2deg(acos(n.dot(Vector3(0,1,0))))< MAX_SLOPE_ANGLE):
				on_floor = true;
			
			motion=n.slide(motion);
			velocity=n.slide(velocity);
			
			if original_vel.dot(velocity) > 0:
				motion=move(motion);
				if motion.length() < 0.001:
					break;
			
			attempts-=1;
	
	if on_floor and Input.is_key_pressed(KEY_SPACE):
		velocity.y = jump_speed*gravity_factor;
		on_floor = false;

func player_on_fixedprocess(delta):
	if !focus_mode:
		cam.cam_target = get_global_transform().origin + Vector3(0, 2.25, 0);
	else:
		cam.cam_target = get_global_transform().origin + Vector3(0, 2.25, 0);
	
	if Input.is_key_pressed(KEY_SHIFT) && is_moving && !focus_mode:
		move_speed = max(min(move_speed+(4*delta),walk_speed*2.0),walk_speed);
	else:
		move_speed = max(min(move_speed-(4*delta),walk_speed*2.0),walk_speed);
	
	var tmp_camyaw = cam.cam_yaw;
	if is_moving && !focus_mode:
		if Input.is_key_pressed(KEY_W):
			if Input.is_key_pressed(KEY_A):
				tmp_camyaw += 45;
			if Input.is_key_pressed(KEY_D):
				tmp_camyaw -= 45;
		elif Input.is_key_pressed(KEY_S):
			if Input.is_key_pressed(KEY_A):
				tmp_camyaw += 135;
			elif Input.is_key_pressed(KEY_D):
				tmp_camyaw -= 135;
			else:
				tmp_camyaw -= 180;
		elif Input.is_key_pressed(KEY_A):
			tmp_camyaw += 90;
		elif Input.is_key_pressed(KEY_D):
			tmp_camyaw -= 90;
	
	if is_moving || focus_mode:
		var body_rot = get_node("body").get_rotation();
		body_rot.y = deg2rad(lerp(rad2deg(body_rot.y),tmp_camyaw,10*delta));
		#body_rot.y = deg2rad(tmp_camyaw);
		get_node("body").set_rotation(body_rot);
	
	if is_moving:
		var speed = (move_speed/walk_speed);
		set_anim("walkLikeMan", speed);
	else:
		set_anim("default");

func set_anim(name, speed = 1.0):
	var animplayer = get_node("body/char 2/AnimationPlayer");
	animplayer.set_speed(speed);
	var current = animplayer.get_current_animation();
	if current != name:
		animplayer.play(name);