extends SceneTree
func _aa(instance: Node3D, root_x: Transform3D) -> AABB:
	var result := AABB()
	var first := true
	var stack: Array = [[instance, Transform3D.IDENTITY]]
	while stack.size() > 0:
		var e: Array = stack.pop_back()
		var n: Node = e[0]
		var acc: Transform3D = e[1]
		if n is Node3D and n != instance:
			acc = acc * (n as Node3D).transform
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			var c: AABB = root_x * acc * (n as MeshInstance3D).mesh.get_aabb()
			if first:
				result = c
				first = false
			else:
				result = result.merge(c)
		for ch in n.get_children():
			stack.append([ch, acc])
	return result

func _initialize() -> void:
	for path in ["res://models/town/roads/road-straight.glb", "res://models/town/roads/road-bend.glb", "res://models/town/industrial/building-g.glb"]:
		var inst: Node3D = (load(path) as PackedScene).instantiate()
		root.add_child(inst)
		var a: AABB = _aa(inst, Transform3D.IDENTITY)
		var lay := Transform3D(Basis(Vector3(1, 0, 0), -PI / 2), Vector3.ZERO)
		var b: AABB = _aa(inst, lay)
		print("PATH ", path.get_file(), " raw=", a, " baked=", b)
		inst.queue_free()
	quit()
