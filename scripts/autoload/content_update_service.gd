extends Node
## OTA контент-пакетов: CDN → user://content_cache → hot reload без переустановки APK.
## Не подменяет код GDScript/движок — только JSON/медиа пакета.

signal update_started
signal update_progress(done: int, total: int, label: String)
signal update_finished(ok: bool, message: String)
signal status_changed

const CONFIG_RES := "res://content/update_config.json"
const CONFIG_USER := "user://update_config.json"
const CACHE_ACTIVE := "user://content_cache/active.json"
const DOC_FILES := [
	"manifest.json", "hub.json", "campaign.json", "heroes.json", "battle_modes.json",
	"features.json", "theme.json", "shell.json", "motion.json", "strings.json", "assets.json",
	"enemies.json", "economy.json", "progression.json", "equipment.json", "loot_tables.json",
	"gacha.json", "liveops.json", "pve_modes.json",
]

var enabled: bool = true
var cdn_base: String = "http://127.0.0.1:8787/cdn"
var check_on_boot: bool = true
var check_interval_sec: float = 90.0
var timeout_sec: float = 20.0

var last_status: String = "idle"
var last_error: String = ""
var last_check_at: String = ""
var remote_version: String = ""
var busy: bool = false

var _http: HTTPRequest
var _queue: Array[Dictionary] = []
var _current: Dictionary = {}
var _pending_version: String = ""
var _pending_meta: Dictionary = {}
var _done: int = 0
var _total: int = 0
var _timer: Timer
var _silent: bool = false

func _ready() -> void:
	_load_config()
	_http = HTTPRequest.new()
	_http.timeout = timeout_sec
	_http.request_completed.connect(_on_request_completed)
	add_child(_http)
	_timer = Timer.new()
	_timer.wait_time = maxf(30.0, check_interval_sec)
	_timer.one_shot = false
	_timer.timeout.connect(func(): check_for_updates(true))
	add_child(_timer)
	if enabled and check_on_boot:
		call_deferred("check_for_updates", true)
	if enabled and check_interval_sec > 0.0:
		_timer.start()

func _load_config() -> void:
	var cfg := _read_json(CONFIG_RES)
	var user_cfg := _read_json(CONFIG_USER)
	for k in user_cfg.keys():
		cfg[k] = user_cfg[k]
	enabled = bool(cfg.get("enabled", true))
	cdn_base = str(cfg.get("cdn_base", cdn_base)).rstrip("/")
	check_on_boot = bool(cfg.get("check_on_boot", true))
	check_interval_sec = float(cfg.get("check_interval_sec", 90))
	timeout_sec = float(cfg.get("timeout_sec", 20))
	if _http:
		_http.timeout = timeout_sec

func set_cdn_base(url: String) -> void:
	cdn_base = url.rstrip("/")
	var cfg := _read_json(CONFIG_USER)
	cfg["cdn_base"] = cdn_base
	cfg["enabled"] = enabled
	_write_json(CONFIG_USER, cfg)
	status_changed.emit()

func set_enabled(v: bool) -> void:
	enabled = v
	var cfg := _read_json(CONFIG_USER)
	cfg["enabled"] = enabled
	cfg["cdn_base"] = cdn_base
	_write_json(CONFIG_USER, cfg)
	if enabled and check_interval_sec > 0.0 and not _timer.is_stopped():
		pass
	elif enabled and check_interval_sec > 0.0:
		_timer.start()
	elif not enabled:
		_timer.stop()
	status_changed.emit()

func check_for_updates(silent: bool = false) -> void:
	if not enabled:
		last_status = "disabled"
		status_changed.emit()
		return
	if busy:
		return
	_silent = silent
	busy = true
	last_status = "checking"
	last_error = ""
	_queue.clear()
	_current = {}
	_pending_version = ""
	_done = 0
	_total = 0
	status_changed.emit()
	update_started.emit()
	if not silent:
		NotificationManager.info("Проверка контента…")
	_queue.append({"kind": "active", "url": "%s/active.json" % cdn_base, "file": "active.json"})
	_pump()

func force_reload_current() -> void:
	ContentPackageLoader.reload()
	NotificationManager.success("Контент перечитан: %s" % ContentPackageLoader.package_label())

func _pump() -> void:
	if _queue.is_empty():
		if _pending_version != "":
			_finish_apply()
		else:
			_finish_ok("Актуальный пакет %s" % ContentPackageLoader.version)
		return
	_current = _queue.pop_front()
	var url := str(_current.get("url", ""))
	last_status = "downloading"
	status_changed.emit()
	update_progress.emit(_done, maxi(_total, 1), str(_current.get("file", "")))
	var err := _http.request(url)
	if err != OK:
		_fail("Не удалось начать запрос (%s): %s" % [str(err), url])

func _on_request_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if not busy:
		return
	var kind := str(_current.get("kind", ""))
	var optional := bool(_current.get("optional", false))
	if result != HTTPRequest.RESULT_SUCCESS or code < 200 or code >= 300:
		if optional and kind == "file":
			# Старые пакеты без schema 3/4 файлов — пустой объект, загрузчик терпит.
			var opt_name := str(_current.get("file", "optional.json"))
			_write_text(
				"user://content_cache/packages/%s/%s" % [_pending_version, opt_name],
				"{}\n"
			)
			_done += 1
			update_progress.emit(_done, _total, opt_name)
			_pump()
			return
		_fail("CDN недоступен (%s/%s). Укажите доступный cdn_base. Сейчас: %s" % [str(result), str(code), cdn_base])
		return
	if kind == "active":
		_handle_active(body)
		return
	if kind == "manifest":
		_handle_manifest(body)
		return
	if kind == "file":
		_handle_file(body)
		return
	_fail("Неизвестный шаг OTA")

func _handle_active(body: PackedByteArray) -> void:
	var raw := body.get_string_from_utf8().strip_edges()
	if not raw.begins_with("{"):
		_fail("CDN active.json не JSON")
		return
	var data = JSON.parse_string(raw)
	if typeof(data) != TYPE_DICTIONARY or not data.has("version"):
		_fail("Некорректный active.json с CDN")
		return
	remote_version = str(data["version"])
	_pending_meta = data
	last_check_at = Time.get_datetime_string_from_system(true)
	var local_active := _read_json(CACHE_ACTIVE)
	var same_ver := remote_version == ContentPackageLoader.version
	var same_pub := str(data.get("published_at", "")) != "" and str(data.get("published_at", "")) == str(local_active.get("published_at", ""))
	if same_ver and same_pub and ContentPackageLoader.from_cache:
		_pending_version = ""
		_finish_ok("Актуальный пакет %s" % remote_version)
		return
	_ensure_dir("user://content_cache/packages/%s" % remote_version)
	_pending_version = remote_version
	# Сначала manifest — из него список файлов (schema 2/3, в т.ч. enemies.json).
	_done = 0
	_total = 1
	_queue.append({
		"kind": "manifest",
		"file": "manifest.json",
		"url": "%s/packages/%s/manifest.json" % [cdn_base, remote_version],
	})
	_pump()

func _handle_manifest(body: PackedByteArray) -> void:
	var raw := body.get_string_from_utf8().strip_edges()
	if not raw.begins_with("{"):
		_fail("CDN manifest.json не JSON")
		return
	var data = JSON.parse_string(raw)
	if typeof(data) != TYPE_DICTIONARY:
		_fail("Некорректный manifest с CDN")
		return
	_write_text("user://content_cache/packages/%s/manifest.json" % _pending_version, raw + "\n")
	var files: Array = DOC_FILES.duplicate()
	var listed: Dictionary = data.get("files", {})
	for key in listed.keys():
		var fname := str(key)
		if not fname.ends_with(".json"):
			fname = "%s.json" % fname
		if fname not in files:
			files.append(fname)
	# integrity.hashes — полный список документов пакета
	var hashes: Dictionary = data.get("integrity", {}).get("hashes", {})
	for key in hashes.keys():
		var fname := str(key)
		if fname not in files:
			files.append(fname)
	files.erase("manifest.json")
	_done = 1
	_total = files.size() + 1
	for fname in files:
		_queue.append({
			"kind": "file",
			"file": fname,
			"url": "%s/packages/%s/%s" % [cdn_base, remote_version, fname],
			"optional": fname in [
				"enemies.json", "economy.json", "progression.json", "equipment.json",
				"loot_tables.json", "gacha.json", "liveops.json", "pve_modes.json",
			],
		})
	_pump()

func _handle_file(body: PackedByteArray) -> void:
	var fname := str(_current.get("file", "file.json"))
	var raw := body.get_string_from_utf8().strip_edges()
	if fname.ends_with(".json") and not raw.begins_with("{") and not raw.begins_with("["):
		_fail("CDN вернул не JSON для %s" % fname)
		return
	var dest := "user://content_cache/packages/%s/%s" % [_pending_version, fname]
	var f := FileAccess.open(dest, FileAccess.WRITE)
	if f == null:
		_fail("Не удалось записать %s" % dest)
		return
	f.store_string(raw + "\n")
	_done += 1
	update_progress.emit(_done, _total, fname)
	_pump()

func _finish_apply() -> void:
	var ok := ContentPackageLoader.apply_cached_active(_pending_version, _pending_meta)
	if not ok:
		_fail("Пакет скачан, но не загрузился")
		return
	# package_loaded → DemoData / ThemeManager / экраны сами перечитают
	_finish_ok("Контент обновлён: %s (без переустановки APK)" % _pending_version)

func _finish_ok(msg: String) -> void:
	busy = false
	var updated := msg.findn("обновлён") >= 0 or msg.findn("updated") >= 0
	last_status = "ok" if updated else "up_to_date"
	last_error = ""
	_pending_version = ""
	_current = {}
	_queue.clear()
	status_changed.emit()
	update_finished.emit(true, msg)
	if updated or not _silent:
		NotificationManager.success(msg)
	print("ContentUpdate: ", msg)

func _fail(msg: String) -> void:
	busy = false
	last_status = "error"
	last_error = msg
	_queue.clear()
	_current = {}
	_pending_version = ""
	_total = 0
	_done = 0
	status_changed.emit()
	update_finished.emit(false, msg)
	NotificationManager.warn(msg)
	push_warning("ContentUpdate: " + msg)

func _ensure_dir(user_path: String) -> void:
	var abs := ProjectSettings.globalize_path(user_path)
	DirAccess.make_dir_recursive_absolute(abs)

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var data = JSON.parse_string(f.get_as_text())
	return data if typeof(data) == TYPE_DICTIONARY else {}

func _write_json(path: String, data: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "  ") + "\n")

func _write_text(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(text)
