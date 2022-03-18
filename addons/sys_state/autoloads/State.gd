extends "res://addons/sooty_engine/autoloads/base_state.gd"

var _C := {}
var _expr := Expression.new()

func _post_init():
	# collect state functions in a dict, so all can access them.
	for child in _children:
		for m in child.get_method_list():
			var n: String = m.name
			if n[0] != "_" and not has_method(m.name):
				_C[n] = child[n]
	super._post_init()

func do(command: String) -> Variant:
	if command.begins_with("@"):
		return _call(command.substr(1))
	elif command.begins_with("~"):
		return _eval(command.substr(1))
	else:
		return _eval(command)

func _call(call: String):
	var args := Sooty.str_to_args(call)
	var fname = args.pop_front()
	# call group node function
	if "." in fname:
		var p = fname.split(".", true, 1)
		Global.call_group_flags(SceneTree.GROUP_CALL_REALTIME, p[0], p[1], args)
	# call shortcut
	elif fname in _C:
		return UObject.callablev(_C[fname], args)
	# call scene function
	elif get_tree().current_scene.has_method(fname):
		return get_tree().current_scene.callv(fname, args)
	# alert user nothing happened
	else:
		push_error("No function %s(%s) in State." % [fname, args])

func _eval(expression: String, default = null) -> Variant:
	# assignments?
	for op in [" = ", " += ", " -= ", " *= ", " /= "]:
		if op in expression:
			var p := expression.split(op, true, 1)
			var property := p[0].strip_edges()
			if State._has(property):
				var old_val = State._get(property)
				var new_val = _eval(p[1].strip_edges())
				match op:
					" = ": State._set(property, new_val)
					" += ": State._set(property, old_val + new_val)
					" -= ": State._set(property, old_val - new_val)
					" *= ": State._set(property, old_val * new_val)
					" /= ": State._set(property, old_val / new_val)
				return State._get(property)
			else:
				push_error("No property '%s' in State." % property)
				return default
	
	# pipes
	if "|" in expression:
		var p := expression.split("|", true, 1)
		var got = _eval(p[0])
		return _pipe(got, p[1])
	
	var global = _globalize_functions(expression).strip_edges()
#	prints("(%s) >>> (%s)" %[expression, global])
	
	if _expr.parse(global, []) != OK:
		push_error(_expr.get_error_text())
	else:
		var result = _expr.execute([], State, false)
		if _expr.has_execute_failed():
			push_error("_eval(\"%s\") failed: %s." % [global, _expr.get_error_text()])
		else:
			return result
	return default

func _test(expression: String) -> bool:
	return true if _eval(expression) else false

func _pipe(value: Variant, pipes: String) -> Variant:
	for pipe in pipes.split("|"):
		var args = UString.split_on_spaces(pipe)
		var fname = args.pop_front()
		if fname in _C:
			value = UObject.callablev(_C[fname], [value] + args.map(_eval))
		else:
			push_error("Can't pipe %s. No %s." % [value, fname])
	return value

func _has(property: StringName):
	if Persistent._has(property):
		return true
	return super._has(property)

func _get(property: StringName):
	if Persistent._has(property):
		return Persistent._get(property)
	match str(property):
		"current_scene": return get_tree().current_scene
	return super._get(property)

func _set(property: StringName, value) -> bool:
	if Persistent._has(property):
		return Persistent._set(property, value)
	return super._set(property, value)

func _ready() -> void:
	super._ready()
	print("[States]")
	for script_path in UFile.get_files("res://states", ".gd"):
		var mod = install(script_path)
		print("\t- ", script_path)

func get_save_state() -> Dictionary:
	return _get_changed_states()

# x = do_something(true, custom_func(0), sin(rotation))
# BECOMES
# x = _C.do_something.call(true, _C.custom_func.call(0), sin(rotation))
# this means functions defined in one Node, are usable by all as if they are their own.
func _globalize_functions(t: String) -> String:
	var i := 0
	var out := ""
	var off := 0
	while i < len(t):
		var j := t.find("(", i)
		# find a bracket.
		if j != -1:
			var k := j-1
			var method_name := ""
			# walk backwards
			while k >= 0 and t[k] in ".abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789":
				method_name = t[k] + method_name
				k -= 1
			# if head isn't empty, it's a function not wrapping brackets.
			if method_name != "":
				out += UString.part(t, i, k+1)
				# renpy inspired translations
				if method_name == "_":
					out += "tr("
				# don't wrap property methods, since those will be globally accessible from _get
				# don't wrap built in GlobalScope methods (sin, round, randf...)
				elif "." in method_name or method_name in UObject.GLOBAL_SCOPE_METHODS:
					out += "%s(" % method_name
				else:
					out += "_C.%s.call(" % method_name
				out += UString.part(t, k+1+len(method_name), j)
				i = j + 1
				continue
		out += t[i]
		i += 1
	# add on the remainder.
	out += UString.part(t, i)
	return out
