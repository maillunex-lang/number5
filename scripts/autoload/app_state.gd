extends Node
## Локальное состояние прототипа. НЕ является серверным источником истины.

signal guest_entered(display_name: String)
signal graphics_changed(preset: String)
signal currencies_changed

const VERSION := "0.1.0"
const BUILD_LABEL := "UI Prototype v0.1 (локальное демо)"

var is_guest: bool = true
var display_name: String = "Странник"
var email_hint: String = "" # never store real passwords
var world_id: String = "eliorian-1"
var world_name: String = "Элиориан"

var level: int = 12
var vip_level: int = 0
var gold: int = 12540
var diamonds: int = 320
var power: int = 48500

var session_active: bool = false
var first_boot_done: bool = false

func enter_as_guest(name_override: String = "") -> void:
	is_guest = true
	display_name = name_override if name_override != "" else "Гость-%04d" % (randi() % 10000)
	email_hint = ""
	session_active = true
	first_boot_done = true
	guest_entered.emit(display_name)

func enter_as_local_demo(email: String) -> void:
	# Local prototype only — no real auth, no password storage.
	is_guest = false
	email_hint = email.strip_edges()
	display_name = email_hint.split("@")[0] if "@" in email_hint else "Командир"
	session_active = true
	first_boot_done = true
	guest_entered.emit(display_name)

func logout() -> void:
	session_active = false
	is_guest = true
	email_hint = ""
	display_name = "Странник"

func add_demo_rewards(g: int, d: int) -> void:
	gold += g
	diamonds += d
	currencies_changed.emit()

func spend_demo_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	currencies_changed.emit()
	return true
