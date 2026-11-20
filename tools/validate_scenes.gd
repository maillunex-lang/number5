extends SceneTree

func _init() -> void:
	var paths := []
	_collect("res://scenes", paths)
	var errors := 0
	for p in paths:
		var res := load(p)
		if res == null:
			push_error("LOAD FAIL: " + p)
			errors += 1
			continue
		if res is PackedScene:
			var n = res.instantiate()
			if n == null:
				push_error("INSTANTIATE FAIL: " + p)
				errors += 1
			else:
				print("OK ", p)
				n.free()
	print("DONE errors=", errors, " scenes=", paths.size())
	quit(1 if errors > 0 else 0)

func _collect(dir_path: String, out: Array) -> void:
	var d := DirAccess.open(dir_path)
	if d == null:
		return
	d.list_dir_begin()
	var f := d.get_next()
	while f != "":
		if f.begins_with("."):
			f = d.get_next()
			continue
		var full := dir_path.path_join(f)
		if d.current_is_dir():
			_collect(full, out)
		elif f.ends_with(".tscn"):
			out.append(full)
		f = d.get_next()
