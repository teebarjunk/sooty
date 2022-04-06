@tool
extends EditorPlugin

const AUTOLOADS := ["Global", "Mods", "Settings", "Scene", "Saver", "Persistent", "State", "StringAction", "Music", "SFX", "Dialogues", "DialogueStack"]
const SOOT_HIGHLIGHTER = preload("res://addons/sooty_engine/dialogue/DialogueHighlighter.gd")
const DATA_HIGHLIGHTER = preload("res://addons/sooty_engine/data/DataHighlighter.gd")
var soot_highlighter := SOOT_HIGHLIGHTER.new()
var data_highlighter := DATA_HIGHLIGHTER.new()

func _enter_tree() -> void:
	# load all autoloads in order.
	for id in AUTOLOADS:
		add_autoload_singleton(id, "res://addons/sooty_engine/autoloads/%s.gd" % id)
	
	# add .soot to the allowed textfile extensions.
	var es: EditorSettings = get_editor_interface().get_editor_settings()
	var fs = es.get_setting("docks/filesystem/textfile_extensions")
	if not ",soot" in fs:
		es.set_setting("docks/filesystem/textfile_extensions", fs + ",soot")
	if not ",soda" in fs:
		es.set_setting("docks/filesystem/textfile_extensions", fs + ",soda")
	
	var se: ScriptEditor = get_editor_interface().get_script_editor()
	# register syntax highlighter for drop down.
	se.register_syntax_highlighter(soot_highlighter)
	se.register_syntax_highlighter(data_highlighter)
	# track scripts opened/closed to can add highliter.
	se.editor_script_changed.connect(_editor_script_changed)

func _editor_script_changed(s):
	# auto add highlighters
	for e in get_editor_interface().get_script_editor().get_open_script_editors():
		if e.has_meta("_edit_res_path") and not e.has_meta("_soot_hl"):
			# set a flag so we don't constantly call apply the highlighters.
			e.set_meta("_soot_hl", true)
			
			e = e as ScriptEditorBase
			var c: CodeEdit = e.get_base_editor()
			var rpath: String = e.get_meta("_edit_res_path")
			if rpath.ends_with(Soot.EXT_DIALOGUE):
				c.syntax_highlighter = soot_highlighter
			elif rpath.ends_with(Soot.EXT_DATA):
				c.syntax_highlighter = data_highlighter
			elif rpath.ends_with(Soot.EXT_LANG):
				c.syntax_highlighter = soot_highlighter

func _exit_tree() -> void:
	# remove .soot highlighter.
	get_editor_interface().get_script_editor().unregister_syntax_highlighter(soot_highlighter)
	get_editor_interface().get_script_editor().unregister_syntax_highlighter(data_highlighter)
	
	for id in AUTOLOADS:
		remove_autoload_singleton(id)
	
