extends Node
## Локальное состояние прототипа. НЕ является серверным источником истины.

signal guest_entered(display_name: String)
signal graphics_changed(preset: String)
signal currencies_changed

const VERSION := "0.5.5"
const BUILD_LABEL := "Lunex AFK v" + VERSION

var is_guest: bool = true
var display_name: String = "Странник"
var email_hint: String = "" # never store real passwords
var world_id: String = "bashkortostan-razlom-1"
var world_name: String = "Башкортостан: Разлом эпох"

var level: int = 1
var vip_level: int = 0
var gold: int = 0
var diamonds: int = 0
var power: int = 0

var session_active: bool = false
var first_boot_done: bool = false

func enter_as_guest(name_override: String = "") -> void:
	is_guest = true
	display_name = name_override if name_override != "" else "Гость-%04d" % (randi() % 10000)
	email_hint = ""
	session_active = true
	first_boot_done = true
	guest_entered.emit(display_name)

func logout() -> void:
	session_active = false
	is_guest = true
	email_hint = ""
	display_name = "Странник"

func add_demo_rewards(_g: int, _d: int) -> void:
	push_warning("Local reward mutation disabled: server is authoritative")

func spend_demo_gold(_amount: int) -> bool:
	push_warning("Local wallet spending disabled: server is authoritative")
	return false
