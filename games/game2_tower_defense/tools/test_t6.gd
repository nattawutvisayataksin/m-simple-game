extends SceneTree
# T6: verify the mage tower counters the new armored stone golem.

var _main: Node2D
var _golem: Node2D
var _timer := 0.0
var _phase := 0

func _initialize() -> void:
	_main = load("res://scenes/main.tscn").instantiate()
	root.add_child(_main)
	if _main._gold != 0:
		_fail("game should start with zero gold")
		return
	_main._gold = 180
	_main._update_gold()

func _fail(message: String) -> void:
	print("TEST_T6 FAIL ", message)
	quit(1)

func _process(delta: float) -> bool:
	_timer += delta
	if _phase == 0 and _timer >= 0.1:
		var mage_cost := int(_main.TOWER_DEFS["mage"]["cost"])
		_main._open_menu(2)
		var layout: VBoxContainer = _main._menu.get_child(0)
		var options: HBoxContainer = layout.get_child(1)
		if options.get_child_count() != 4:
			_fail("build menu does not show all four towers (archer/cannon/mage/barracks)")
			return true
		var mage_option: VBoxContainer = options.get_child(2)
		var mage_label: Label = mage_option.get_child(1)
		if not mage_label.text.ends_with("ป้อมเวท"):
			_fail("mage tower missing from purchase menu")
			return true
		var mage_button: TextureButton = mage_option.get_child(0)
		mage_button.pressed.emit()
		var mage: Node2D = _main._towers[2]
		if mage == null or mage.kind != _main.TowerScript.MAGE or _main._gold != 180 - mage_cost:
			_fail("mage tower purchase failed")
			return true

		var EnemyScript: GDScript = load("res://scripts/enemy.gd")
		var probe: Node2D = EnemyScript.new()
		probe.texture = load("res://assets/art/gen/stone_golem.png")
		probe.max_hp = 100.0
		probe.damage_resist = 0.65
		probe.waypoints = PackedVector2Array([Vector2(1050, 100)])
		_main.add_child(probe)
		probe.take_damage(20.0)
		if not is_equal_approx(probe._hp, 93.0):
			_fail("physical damage did not respect armor: hp=%.1f" % probe._hp)
			return true
		probe.take_damage(20.0, true)
		if not is_equal_approx(probe._hp, 73.0):
			_fail("magic damage did not bypass armor: hp=%.1f" % probe._hp)
			return true
		probe.queue_free()

		_main._wave_idx = 0
		_main._spawn_kind("stone_golem")
		for enemy in get_nodes_in_group("enemies"):
			if enemy is Node2D and not enemy.is_queued_for_deletion() and enemy.max_hp == _main.GOLEM_HP:
				_golem = enemy
				break
		if _golem == null or _golem.max_hp != _main.GOLEM_HP or _golem.base_scale <= 1.5:
			_fail("golem spawn stats or sprite scale incorrect")
			return true

		_golem.max_hp = 36.0
		_golem._hp = 36.0
		mage.fire_interval = 0.08
		mage.damage = 18.0
		mage.shot_speed = 1000.0
		_timer = 0.0
		_phase = 1
		print("TEST_T6 setup PASS mage_cost=%d golem_hp=%.0f armor=%.0f%%" % [
			mage_cost, _main.GOLEM_HP, _main.GOLEM_RESIST * 100.0,
		])
	elif _phase == 1:
		if _golem.dead:
			print("TEST_T6 mage-piercing PASS golem_defeated")
			print("TEST_T6 ALL PASS")
			quit(0)
			return true
		if _timer > 1.5:
			_fail("mage projectile could not defeat armored golem, hp=%.1f" % _golem._hp)
			return true
	return false
