extends PanelContainer

var _shell: Node
var _buttons: Dictionary = {}

func setup(shell: Node) -> void:
	_shell = shell
	_buttons = {
		"map": $Pad/Row/Map,
		"heroes": $Pad/Row/Heroes,
		"hub": $Pad/Row/Hub,
		"battle": $Pad/Row/Battle,
	}
	_buttons["map"].pressed.connect(func(): _shell.on_nav("map"))
	_buttons["heroes"].pressed.connect(func(): _shell.on_nav("heroes"))
	_buttons["hub"].pressed.connect(func(): _shell.on_nav("hub"))
	_buttons["battle"].pressed.connect(func(): _shell.on_nav("battle"))
	set_active("hub")

func set_active(tab: String) -> void:
	for k in _buttons:
		var b: Button = _buttons[k]
		var on: bool = (str(k) == tab)
		b.modulate = Color(1.15, 1.05, 0.85) if on else Color(0.75, 0.8, 0.88)
		b.disabled = false
