extends SceneTree

var failures := 0
var checks := 0

func check(ok: bool, description: String) -> void:
	checks += 1
	if ok:
		print("PASS: " + description)
	else:
		push_error("FAIL: " + description)
		failures += 1

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	game.muted = true
	check(game.state == "title", "game opens on title screen")
	check(game.ledges.size() == 29, "base, 27 ledges and summit exist")
	game.new_game()
	check(game.grounded and game.checkpoint == 0, "new game starts safely at base")
	game.simulate(1.0 / 60.0, 0.0, true, false)
	check(game.vel.y < -450 and not game.grounded, "jump lifts the climber")
	for frame in range(90):
		game.simulate(1.0 / 60.0, 0, false, false)
	check(game.grounded and game.standing == 0, "climber lands back on platform")
	game.new_game()
	# Walk the entire generated route using normal physics and steering. No teleporting.
	for target in range(1, 29):
		var reached := false
		for frame in range(180):
			var dx: float = game.ledges[target].get_center().x - game.pos.x
			var axis := clampf(dx / 30.0, -1.0, 1.0)
			game.clock += 1.0 / 60.0
			game.simulate(1.0 / 60.0, axis, frame == 0, false)
			if game.grounded and game.standing == target:
				reached = true
				break
		check(reached, "route ledge %d reachable through gameplay" % target)
		if not reached:
			break
	check(game.state == "won", "landing on summit wins the game")
	check(game.checkpoint == 28 and game.falls == 0, "all camps activate during full ascent")
	game.checkpoint = 7
	game.state = "playing"
	game.pos.y = game.ledges[7].position.y + 1000
	game.simulate(1.0 / 60.0, 0, false, false)
	check(game.falls == 1 and game.pos.y == game.ledges[7].position.y, "fall returns player to latest camp")
	check(game.stamina == 100, "camp return restores stamina")
	game.new_game()
	game.stamina = 10.0
	game.grounded = false
	game.pos.y -= 100
	game.simulate(0.1, 1, false, true)
	check(game.stamina < 10, "sprint consumes stamina")
	game.respawn(false)
	game.stamina = 50
	game.simulate(0.1, 0, false, false)
	check(game.stamina > 50, "resting recovers stamina")
	game.state = "paused"
	var old_pos: Vector2 = game.pos
	game._physics_process(0.1)
	check(game.pos == old_pos, "pause freezes gameplay")
	game.new_game()
	check(game.falls == 0 and game.elapsed == 0 and game.checkpoint == 0, "restart resets run")
	print("RESULT: %d checks, %d failures" % [checks, failures])
	game.free()
	quit(0 if failures == 0 else 1)
