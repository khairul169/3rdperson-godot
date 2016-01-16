extends Label

var update = 0.0;

func _ready():
	set_process(true);

func _process(delta):
	if update < 1.0:
		update += delta;
	else:
		update = 0.0;
		var txt = str("FPS: ", int(OS.get_frames_per_second()), "/s");
		txt += str("\nDrawn Vertices: ", Performance.get_monitor(Performance.RENDER_VERTICES_IN_FRAME));
		txt += str("\nDrawn Objects: ", Performance.get_monitor(Performance.RENDER_OBJECTS_IN_FRAME));
		txt += str("\nDraw Calls: ", Performance.get_monitor(Performance.RENDER_DRAW_CALLS_IN_FRAME));
		
		set_text(txt);