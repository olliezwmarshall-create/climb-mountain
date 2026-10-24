extends Node2D

const W := 1152.0
const H := 720.0
const GRAVITY := 1050.0
const JUMP := -505.0
const PLAYER_SIZE := Vector2(24, 34)
const WHITE := Color("eef4ec")
const GOLD := Color("ffc578")
const INK := Color("112c38")
const MINT := Color("9ce0cd")
const START_BUTTON := Rect2(445, 478, 262, 56)

var ledges: Array[Rect2] = []
var camps: Array[int] = [0, 7, 14, 21, 28]
var pos := Vector2(576, 602)
var vel := Vector2.ZERO
var grounded := true
var standing := 0
var checkpoint := 0
var stamina := 100.0
var camera_y := 170.0
var clock := 0.0
var elapsed := 0.0
var falls := 0
var best := 0.0
var state := "title"
var coyote := 0.12
var jump_buffer := 0.0
var toast := ""
var toast_time := 0.0
var muted := false
var font: Font = ThemeDB.fallback_font
var sfx: AudioStreamPlayer
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 3741
	ledges.append(Rect2(394, 602, 364, 26))
	var x := 576.0
	var y := 602.0
	for i in range(1, 29):
		y -= 94.0 if i % 3 != 0 else 102.0
		x = clampf(x + sin(float(i) * 1.73) * 157.0, 200.0, 952.0)
		var width := 184.0 if i in camps else 132.0
		ledges.append(Rect2(x - width / 2.0, y, width, 22))
	sfx = AudioStreamPlayer.new()
	add_child(sfx)
	queue_redraw()

func new_game() -> void:
	checkpoint = 0
	falls = 0
	elapsed = 0.0
	best = 0.0
	state = "playing"
	respawn(false)
	camera_y = pos.y - 430.0
	toast = "BASE CAMP  /  Your ascent begins"
	toast_time = 3.5

func respawn(count_fall: bool = true) -> void:
	if count_fall:
		falls += 1
		toast = "Back at camp. Take a breath. Try again."
		toast_time = 3.0
		play_tone(160, 0.18)
	pos = Vector2(ledges[checkpoint].get_center().x, ledges[checkpoint].position.y)
	vel = Vector2.ZERO
	grounded = true
	standing = checkpoint
	stamina = 100.0
	coyote = 0.12
	jump_buffer = 0.0

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_M:
		muted = not muted
	if state == "title" or state == "won":
		if event.keycode in [KEY_ENTER, KEY_SPACE]:
			new_game()
	elif event.keycode in [KEY_ESCAPE, KEY_P]:
		state = "playing" if state == "paused" else "paused"
	elif event.keycode == KEY_R and state == "playing":
		respawn()
	elif event.keycode in [KEY_SPACE, KEY_W, KEY_UP] and state == "playing":
		jump_buffer = 0.14

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if state in ["title", "won"] and START_BUTTON.has_point(get_global_mouse_position()):
			new_game()
		elif state == "paused":
			state = "playing"

func _physics_process(delta: float) -> void:
	clock += delta
	if state == "playing":
		var axis := float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
		simulate(delta, axis, false, Input.is_physical_key_pressed(KEY_SHIFT))
	camera_y = lerpf(camera_y, pos.y - 430.0, 1.0 - exp(-delta * 5.0))
	queue_redraw()

func wind() -> float:
	return sin(clock * 0.75) * 37.0 * clampf((602.0 - pos.y) / 2200.0, 0.0, 1.0)

func simulate(dt: float, axis: float, jump: bool, sprint: bool) -> void:
	elapsed += dt
	toast_time = maxf(0.0, toast_time - dt)
	jump_buffer = 0.14 if jump else maxf(0.0, jump_buffer - dt)
	coyote = 0.12 if grounded else maxf(0.0, coyote - dt)
	var running := sprint and stamina > 2.0 and absf(axis) > 0.1
	var speed := 300.0 if running else 225.0
	vel.x = move_toward(vel.x, axis * speed + (wind() if not grounded else 0.0), 1500.0 * dt)
	if grounded:
		stamina = minf(100.0, stamina + (40.0 if standing in camps else 22.0) * dt)
	if running:
		stamina = maxf(0.0, stamina - 23.0 * dt)
	if jump_buffer > 0.0 and coyote > 0.0:
		vel.y = JUMP
		grounded = false
		coyote = 0.0
		jump_buffer = 0.0
		play_tone(480, 0.07)
	var previous := pos
	vel.y += GRAVITY * dt
	pos += vel * dt
	pos.x = clampf(pos.x, 40.0, W - 40.0)
	grounded = false
	if vel.y >= 0.0:
		for i in range(ledges.size()):
			var p := ledges[i]
			if previous.y <= p.position.y + 0.1 and pos.y >= p.position.y and pos.x + 10.0 > p.position.x and pos.x - 10.0 < p.end.x:
				pos.y = p.position.y
				vel.y = 0.0
				grounded = true
				standing = i
				if i in camps and i > checkpoint:
					checkpoint = i
					stamina = 100.0
					toast = "CAMP %d SECURED  /  Your progress is safe" % (i / 7)
					toast_time = 3.5
					play_tone(740, 0.18)
				if i == 28:
					state = "won"
					play_tone(990, 0.4)
				break
	best = maxf(best, 602.0 - pos.y)
	if pos.y > maxf(820.0, ledges[checkpoint].position.y + 650.0) or pos.y > camera_y + 900.0:
		respawn()

func play_tone(hz: float, duration: float) -> void:
	if muted or DisplayServer.get_name() == "headless":
		return
	var sound := AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = 22050
	var data := PackedByteArray()
	data.resize(int(duration * 22050) * 2)
	for i in range(data.size() / 2):
		var envelope := (1.0 - float(i) / float(data.size() / 2)) * 0.12
		data.encode_s16(i * 2, int(sin(float(i) * TAU * hz / 22050.0) * envelope * 32767))
	sound.data = data
	sfx.stream = sound
	sfx.play()

func label_at(text: String, at: Vector2, size: int, color: Color = WHITE) -> void:
	draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func centered(text: String, y: float, size: int, color: Color = WHITE) -> void:
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	label_at(text, Vector2((W - width) / 2, y), size, color)

func mountain(points: PackedVector2Array, color: Color) -> void:
	draw_colored_polygon(points, color)

func _draw() -> void:
	# Layered alpine scenery, all drawn in-engine. No external art dependencies.
	for i in range(24):
		var t := float(i) / 23.0
		draw_rect(Rect2(0, i * 30, W, 31), Color("102c3b").lerp(Color("749caa"), t))
	draw_circle(Vector2(906, 139), 50, Color("d9e7dc"))
	draw_circle(Vector2(906, 139), 67, Color(0.84, 0.93, 0.87, 0.04))
	for layer in range(3):
		var offset := fposmod(camera_y * (0.04 + layer * 0.025), 100.0)
		var color := Color("4b6e82").lerp(Color("213f50"), float(layer) / 2.0)
		for j in range(5):
			var x := float(j * 340 - 150 + layer * 90)
			var peak := 235.0 + sin(j * 2.4 + layer) * 90.0 + layer * 72 + offset
			mountain(PackedVector2Array([Vector2(x - 260, 800), Vector2(x, peak), Vector2(x + 320, 800)]), color)
			mountain(PackedVector2Array([Vector2(x - 48, peak + 103), Vector2(x, peak), Vector2(x + 58, peak + 103), Vector2(x + 17, peak + 78), Vector2(x - 5, peak + 100), Vector2(x - 22, peak + 79)]), color.lightened(0.25))
	# The climbing route.
	for i in range(ledges.size()):
		var p := ledges[i]
		var sy := p.position.y - camera_y
		if sy < -100 or sy > H + 250:
			continue
		var x := p.position.x
		var width := p.size.x
		mountain(PackedVector2Array([Vector2(x, sy + 5), Vector2(x + width, sy + 5), Vector2(x + width - 19, sy + 44), Vector2(x + width * 0.56, sy + 73), Vector2(x + 15, sy + 36)]), Color("244655"))
		draw_rect(Rect2(x, sy, width, 8), Color("d8e8df"))
		draw_rect(Rect2(x + 8, sy + 8, width - 16, 6), Color("85b3b5"))
		if i in camps:
			var tent_x := x + width - 50
			mountain(PackedVector2Array([Vector2(tent_x - 25, sy), Vector2(tent_x, sy - 42), Vector2(tent_x + 25, sy)]), GOLD)
			mountain(PackedVector2Array([Vector2(tent_x - 7, sy), Vector2(tent_x, sy - 26), Vector2(tent_x + 12, sy)]), INK)
			draw_line(Vector2(x + 22, sy), Vector2(x + 22, sy - 63), WHITE, 3)
			mountain(PackedVector2Array([Vector2(x + 24, sy - 63), Vector2(x + 53, sy - 55), Vector2(x + 24, sy - 45)]), MINT if i <= checkpoint else GOLD)
			label_at("SUMMIT" if i == 28 else ("BASE CAMP" if i == 0 else "CAMP %d" % (i / 7)), Vector2(x, sy + 98), 14, MINT)
		else:
			label_at("%02d" % i, Vector2(x + 9, sy + 29), 12, Color("82a7b4"))
	# Rope and climber.
	var py := pos.y - camera_y
	var anchor := ledges[checkpoint].get_center() - Vector2(0, camera_y)
	if pos.distance_to(ledges[checkpoint].get_center()) < 290:
		draw_polyline(PackedVector2Array([anchor, Vector2((anchor.x + pos.x) / 2, maxf(anchor.y, py) + 32), Vector2(pos.x, py - 15)]), Color(1, 0.77, 0.47, 0.35), 2, true)
	draw_circle(Vector2(pos.x, py - 30), 8, Color("f2c6a0"))
	draw_style_box(body_style(), Rect2(pos.x - 11, py - 26, 22, 19))
	draw_line(Vector2(pos.x - 5, py - 8), Vector2(pos.x - 8, py), INK, 5, true)
	draw_line(Vector2(pos.x + 5, py - 8), Vector2(pos.x + 9, py), INK, 5, true)
	draw_line(Vector2(pos.x - 10, py - 23), Vector2(pos.x - 16, py - 12), GOLD, 4, true)
	draw_line(Vector2(pos.x + 10, py - 23), Vector2(pos.x + 16, py - 16), GOLD, 4, true)
	draw_rect(Rect2(pos.x - 9, py - 39, 18, 6), Color("dc725b"))
	# Drifting snow.
	for i in range(65):
		var sx := fposmod(float(i * 197) + clock * (11 + i % 5) + sin(clock + i) * 12, W)
		var sy := fposmod(float(i * 103) + clock * (17 + i % 13) - camera_y * 0.15, H)
		draw_circle(Vector2(sx, sy), 1.0 + (i % 3) * 0.4, Color(0.9, 0.98, 1.0, 0.3))
	if state != "title":
		draw_hud()
	if toast_time > 0.0 and state == "playing":
		draw_rect(Rect2(275, 113, 602, 42), Color(0.05, 0.15, 0.19, 0.88))
		centered(toast, 140, 17, MINT)
	if state == "title":
		draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.09, 0.13, 0.67))
		centered("A LITTLE COURAGE. A LONG WAY UP.", 203, 18, MINT)
		centered("S U M M I T", 299, 82)
		centered("THE LONG WAY UP", 340, 20, GOLD)
		centered("One climber. Twenty-eight ledges. A sky worth reaching.", 404, 20)
		centered("Find your footing, rest at camps, and follow the flags to the top.", 438, 17, Color("aac3ca"))
		button("BEGIN THE ASCENT  >")
		centered("A / D  move     SPACE  jump     SHIFT  sprint", 586, 17)
		centered("R  return to camp     ESC  pause     M  sound", 615, 15, Color("aac3ca"))
		centered("No timer pressure. Every camp is a fresh start.", 670, 14, MINT)
	elif state == "paused":
		draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.09, 0.13, 0.8))
		centered("TAKE A BREATH", 319, 45)
		centered("Press ESC or click to continue", 378, 21, GOLD)
	elif state == "won":
		draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.09, 0.13, 0.83))
		centered("2,688 METERS OF COURAGE", 215, 18, MINT)
		centered("YOU MADE IT.", 306, 66)
		centered("The mountain stays. You are a little different.", 365, 22, GOLD)
		centered("Time  %s     /     Returns to camp  %d" % [format_time(), falls], 417, 20)
		button("CLIMB AGAIN  >")
		centered("Press ENTER for another ascent", 575, 17, MINT)

func body_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("dc725b")
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	return style

func button(text: String) -> void:
	var hovered := START_BUTTON.has_point(get_global_mouse_position())
	draw_rect(START_BUTTON, Color("ffe1a8") if hovered else GOLD)
	centered(text, 513, 18, INK)

func format_time() -> String:
	return "%02d:%02d" % [int(elapsed) / 60, int(elapsed) % 60]

func draw_hud() -> void:
	draw_rect(Rect2(0, 0, W, 94), Color(0.035, 0.1, 0.14, 0.94))
	label_at("SUMMIT", Vector2(30, 38), 24)
	label_at("THE LONG WAY UP", Vector2(30, 62), 12, MINT)
	var altitude := clampi(int((602.0 - pos.y) / (602.0 - ledges[28].position.y) * 2688.0), 0, 2688)
	label_at("%s m" % altitude, Vector2(264, 39), 26, GOLD)
	label_at("ALTITUDE", Vector2(264, 63), 11, MINT)
	label_at("STAMINA", Vector2(444, 31), 11, MINT)
	draw_rect(Rect2(444, 44, 150, 7), Color("38515d"))
	draw_rect(Rect2(444, 44, stamina * 1.5, 7), GOLD if stamina < 25 else MINT)
	label_at("CAMP  %d / 4" % (checkpoint / 7), Vector2(637, 37), 17)
	label_at("WIND  %s" % ("CALM" if absf(wind()) < 12 else (">>>" if wind() > 0 else "<<<")), Vector2(637, 62), 12, MINT)
	label_at(format_time(), Vector2(842, 40), 24)
	label_at("M: %s   ESC: PAUSE" % ("MUTED" if muted else "SOUND"), Vector2(943, 38), 11, MINT)
	draw_rect(Rect2(0, H - 34, W, 34), Color(0.035, 0.1, 0.14, 0.88))
	centered("A / D or arrows  MOVE     SPACE / W / UP  JUMP     SHIFT  SPRINT     R  RETURN TO CAMP", H - 12, 13, Color("b3cbd0"))
	# Vertical progress marker.
	draw_line(Vector2(1119, 148), Vector2(1119, 621), Color("466775"), 3)
	for i in range(5):
		draw_circle(Vector2(1119, 621 - i * 118.25), 5, MINT if i * 7 <= checkpoint else Color("6d8b95"))
	var progress := clampf((602 - pos.y) / (602 - ledges[28].position.y), 0, 1)
	draw_circle(Vector2(1119, 621 - progress * 473), 7, GOLD)
