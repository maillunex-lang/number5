extends Node
## HTTP client for CORE-01 online API. Never silently enters local demo.

signal session_ready(token: String)
signal request_failed(path: String, code: int, body: String)
signal wallet_synced
signal player_synced
signal sync_progress(step: String)

const DEFAULT_BASE := "https://rikagro.ru/afkgame"
const TIMEOUT_SEC := 4.0

var base_url: String = DEFAULT_BASE
var access_token: String = ""
var online: bool = false
var last_error: String = ""
var player_loaded: bool = false
var _idem_seq: int = 0

var _presence_timer: Timer
var _sync_timer: Timer
var _sync_busy := false
var _last_full_sync_msec := 0

func _ready() -> void:
	_presence_timer = Timer.new()
	_presence_timer.wait_time = 60.0
	_presence_timer.one_shot = false
	add_child(_presence_timer)
	_presence_timer.timeout.connect(_presence_tick)
	_sync_timer = Timer.new()
	_sync_timer.wait_time = 30.0
	add_child(_sync_timer)
	_sync_timer.timeout.connect(_sync_tick)
	var env_base := OS.get_environment("LUNEX_API_BASE")
	if OS.has_feature("web"):
		base_url = "https://rikagro.ru/afkgame"
	if env_base != "":
		base_url = env_base.rstrip("/")

func has_session() -> bool:
	return access_token != ""

func clear_session() -> void:
	access_token = ""
	online = false
	player_loaded = false
	DemoData.clear_player_data()
	_presence_timer.stop()
	_sync_timer.stop()
	_sync_busy = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if online and player_loaded and Time.get_ticks_msec() - _last_full_sync_msec > 5000:
			_refresh_after_resume()

func _refresh_after_resume() -> void:
	if _sync_busy:
		return
	_sync_busy = true
	var me := await _authed("GET", "/api/v1/auth/me")
	if me.get("ok", false):
		_apply_account_identity(me.get("data", {}))
		await sync_player()
	else:
		_mark_connection_issue(me)
	_sync_busy = false

func _mark_connection_issue(res: Dictionary) -> void:
	if int(res.get("code", 0)) == 401:
		clear_session()
		forget_saved_session()
	else:
		last_error = str(res.get("error", "offline"))

func _sync_tick() -> void:
	if not online or not player_loaded or _sync_busy:
		return
	_sync_busy = true
	var profile := await _authed("GET", "/api/v1/player/profile")
	if profile.get("ok", false):
		var pr: Dictionary = profile.get("data", {})
		AppState.display_name = str(pr.get("nickname", AppState.display_name))
		AppState.level = int(pr.get("level", AppState.level))
		player_synced.emit()
	else:
		_mark_connection_issue(profile)
	if online:
		await sync_wallet()
	_sync_busy = false

func _presence_tick() -> void:
	if online and player_loaded:
		var hb := await _authed("POST", "/api/v1/player/heartbeat")
		if not hb.get("ok", false):
			_mark_connection_issue(hb)

func new_idem(prefix: String = "c") -> String:
	_idem_seq += 1
	return "%s_%d_%d_%d" % [prefix, Time.get_ticks_msec(), randi() % 100000, _idem_seq]

## Guest auth against CORE-01. Returns true on success.
func guest_login() -> bool:
	var res := await _request("POST", "/api/v1/auth/guest", {}, false)
	if res.get("ok", false) != true:
		online = false
		last_error = str(res.get("error", "offline"))
		return false
	var data: Dictionary = res.get("data", {})
	access_token = str(data.get("access_token", ""))
	online = access_token != ""
	if online:
		AppState.is_guest = true
		AppState.email_hint = ""
		session_ready.emit(access_token)
		player_loaded = await sync_player()
		if not player_loaded:
			clear_session()
			last_error = "player_sync_failed"
			return false
	if online:
		_save_session()
	return online

const SESSION_PATH := "user://online_session.dat"
const WEB_SESSION_KEY := "lunex-afk.online-session"

func _web_session_storage() -> JavaScriptObject:
	if OS.has_feature("web"):
		return JavaScriptBridge.get_interface("localStorage")
	return null

func _save_session() -> void:
	var storage := _web_session_storage()
	if storage != null:
		storage.setItem(WEB_SESSION_KEY, access_token)
	var file := FileAccess.open(SESSION_PATH, FileAccess.WRITE)
	if file:
		file.store_string(access_token)
		file.close()

func forget_saved_session() -> void:
	var storage := _web_session_storage()
	if storage != null:
		storage.setItem(WEB_SESSION_KEY, "")
	if FileAccess.file_exists(SESSION_PATH):
		var removed := DirAccess.remove_absolute(SESSION_PATH)
		if removed == OK and OS.has_feature("web"):
			JavaScriptBridge.force_fs_sync()

func restore_session() -> bool:
	var storage := _web_session_storage()
	var saved = storage.getItem(WEB_SESSION_KEY) if storage != null else null
	if saved is String:
		access_token = saved.strip_edges()
	else:
		var file := FileAccess.open(SESSION_PATH, FileAccess.READ)
		access_token = file.get_as_text().strip_edges() if file else ""
	if access_token == "":
		return false
	var me := await _authed("GET", "/api/v1/auth/me")
	if not me.get("ok", false):
		clear_session()
		if int(me.get("code", 0)) == 401:
			forget_saved_session()
		return false
	online = true
	_apply_account_identity(me.get("data", {}))
	player_loaded = await sync_player()
	if not player_loaded:
		clear_session()
		return false
	return true

func credentials_login(email: String, password: String, register_new: bool = false) -> bool:
	var endpoint := "/api/v1/auth/register" if register_new else "/api/v1/auth/login"
	var res := await _request("POST", endpoint, {"email": email, "password": password}, false)
	if not res.get("ok", false):
		return false
	access_token = str(res.get("data", {}).get("access_token", ""))
	online = access_token != ""
	if not online:
		return false
	var me := await _authed("GET", "/api/v1/auth/me")
	if not me.get("ok", false):
		clear_session()
		return false
	_apply_account_identity(me.get("data", {}))
	player_loaded = await sync_player()
	if not player_loaded:
		clear_session()
		return false
	_save_session()
	return true

func link_guest(email: String, password: String) -> bool:
	var res := await _authed("POST", "/api/v1/auth/link", {"email": email, "password": password})
	if not res.get("ok", false):
		return false
	# AUTH-04 / UI-SYNC-HEROES: after bind, refresh identity + server player state.
	var me := await _authed("GET", "/api/v1/auth/me")
	if not me.get("ok", false):
		return false
	_apply_account_identity(me.get("data", {}))
	player_loaded = await sync_player()
	if not player_loaded:
		return false
	_save_session()
	return true

## Revoke server session then clear local state (settings logout).
func logout_remote() -> void:
	if access_token != "":
		await _authed("POST", "/api/v1/auth/logout", {})
	clear_session()
	forget_saved_session()

func _apply_account_identity(data: Dictionary) -> void:
	AppState.is_guest = bool(data.get("is_guest", true))
	AppState.email_hint = "" if AppState.is_guest else str(data.get("email", ""))

func has_saved_token() -> bool:
	var storage := _web_session_storage()
	if storage != null:
		var saved = storage.getItem(WEB_SESSION_KEY)
		if saved is String and str(saved).strip_edges() != "":
			return true
	return FileAccess.file_exists(SESSION_PATH)

func sync_player() -> bool:
	if not online:
		return false
	# Parallel fan-out via raw HTTPRequest (Godot 4.7 forbids calling coroutines without await).
	sync_progress.emit("Загружаем кошелёк, героев, кампанию…")
	var paths := PackedStringArray([
		"/api/v1/wallet",
		"/api/v1/heroes/collection",
		"/api/v1/campaign/progress",
		"/api/v1/player/profile",
		"/api/v1/formations/campaign",
	])
	var batch: Array = await _parallel_authed_gets(paths)
	if batch.size() != paths.size():
		return false
	var wallet: Dictionary = batch[0]
	var owned: Dictionary = batch[1]
	var campaign: Dictionary = batch[2]
	var profile: Dictionary = batch[3]
	var formation: Dictionary = batch[4]
	if not wallet.get("ok", false) or not owned.get("ok", false) or not campaign.get("ok", false) or not profile.get("ok", false) or not formation.get("ok", false):
		return false
	var w: Dictionary = wallet.get("data", {})
	var h: Dictionary = owned.get("data", {})
	var c: Dictionary = campaign.get("data", {})
	var f: Dictionary = formation.get("data", {})
	if not h.has("heroes") or not c.has("current_stage") or not f.has("slots"):
		return false
	sync_progress.emit("Собираем профиль…")
	var pr: Dictionary = profile.get("data", {})
	AppState.display_name = str(pr.get("nickname", "Командир"))
	AppState.level = int(pr.get("level", 1))
	_apply_wallet(w)
	DemoData.apply_server_player(h, c, f)
	player_loaded = true
	player_synced.emit()
	_presence_timer.start()
	_sync_timer.start()
	_last_full_sync_msec = Time.get_ticks_msec()
	# Heartbeat off the critical path — shell can open immediately.
	_heartbeat_after_sync()
	return true

func _heartbeat_after_sync() -> void:
	if not online or access_token == "":
		return
	await _authed("POST", "/api/v1/player/heartbeat")

func _parallel_authed_gets(paths: PackedStringArray) -> Array:
	var n := paths.size()
	var results: Array = []
	results.resize(n)
	var pending := n
	var gate := { "done": false }
	for i in n:
		var idx := i
		var path := paths[i]
		var headers := PackedStringArray(["Content-Type: application/json", "Accept: application/json"])
		if access_token != "":
			headers.append("Authorization: Bearer %s" % access_token)
		var http := HTTPRequest.new()
		http.timeout = TIMEOUT_SEC
		add_child(http)
		http.request_completed.connect(func(http_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray):
			var response_body := body.get_string_from_utf8()
			var parsed: Variant = {}
			if response_body != "":
				parsed = JSON.parse_string(response_body)
				if parsed == null:
					parsed = {"raw": response_body}
			if http_result != HTTPRequest.RESULT_SUCCESS or code < 200 or code >= 300:
				last_error = "http_%d" % code if http_result == HTTPRequest.RESULT_SUCCESS else "http_result_%d" % http_result
				request_failed.emit(path, code, last_error)
				results[idx] = {"ok": false, "error": last_error, "code": code, "data": parsed}
			else:
				results[idx] = {"ok": true, "code": code, "data": parsed}
			http.queue_free()
			pending -= 1
			if pending <= 0:
				gate["done"] = true
		)
		var err := http.request(base_url + path, headers, HTTPClient.METHOD_GET, "")
		if err != OK:
			http.queue_free()
			results[idx] = {"ok": false, "error": "request_error_%d" % err, "code": 0}
			pending -= 1
			if pending <= 0:
				gate["done"] = true
	while not gate["done"]:
		await get_tree().process_frame
	return results

func sync_wallet() -> bool:
	if not online:
		return false
	var res := await get_wallet()
	if res.get("ok", false) != true:
		return false
	_apply_wallet(res.get("data", {}))
	wallet_synced.emit()
	return true

func _apply_wallet(data: Variant) -> void:
	if typeof(data) != TYPE_DICTIONARY:
		return
	var balances: Array = data.get("balances", [])
	for b in balances:
		if typeof(b) != TYPE_DICTIONARY:
			continue
		var rid := str(b.get("resource_id", ""))
		var amt := int(b.get("amount", 0))
		match rid:
			"gold":
				AppState.gold = amt
			"diamonds":
				AppState.diamonds = amt
			"vip_xp":
				# rough VIP display from xp buckets later; keep level if present
				pass
	AppState.currencies_changed.emit()

func get_wallet() -> Dictionary:
	return await _authed("GET", "/api/v1/wallet")

func get_heroes() -> Dictionary:
	return await _authed("GET", "/api/v1/heroes/collection")

func get_campaign() -> Dictionary:
	return await _authed("GET", "/api/v1/campaign/progress")

func battle_start(stage_id: String, idem: String = "") -> Dictionary:
	if idem == "":
		idem = new_idem("bat")
	return await _authed("POST", "/api/v1/battle/start", {
		"stage_id": stage_id,
		"idempotency_key": idem,
	})

func battle_get(battle_id: String) -> Dictionary:
	return await _authed("GET", "/api/v1/battle/%s" % battle_id)

func battle_claim(battle_id: String, idem: String = "") -> Dictionary:
	# Stable per battle so a lost response can be safely replayed (H6 device verify).
	if idem == "":
		idem = "claim:%s" % battle_id
	return await _authed("POST", "/api/v1/battle/%s/claim" % battle_id, {
		"idempotency_key": idem,
	})

func summon_roll(banner_id: String, count: int, idem: String = "") -> Dictionary:
	if idem == "":
		idem = new_idem("sum")
	return await _authed("POST", "/api/v1/summon/roll", {
		"banner_id": banner_id,
		"count": count,
		"idempotency_key": idem,
	})

func summon_pity() -> Dictionary:
	return await _authed("GET", "/api/v1/summon/pity")

func afk_status() -> Dictionary:
	return await _authed("GET", "/api/v1/afk")

func afk_claim(idem: String = "") -> Dictionary:
	if idem == "":
		idem = new_idem("afk")
	return await _authed("POST", "/api/v1/afk/claim", {"idempotency_key": idem})

func mail_list() -> Dictionary:
	return await _authed("GET", "/api/v1/mail")

func mail_claim(mail_id: String, idem: String = "") -> Dictionary:
	if idem == "":
		idem = new_idem("mail")
	return await _authed("POST", "/api/v1/mail/%s/claim" % mail_id, {
		"idempotency_key": idem,
	})

func mail_claim_all(idem: String = "") -> Dictionary:
	if idem == "":
		idem = new_idem("mall")
	return await _authed("POST", "/api/v1/mail/claim-all", {
		"idempotency_key": idem,
	})

func store_catalog() -> Dictionary:
	return await _authed("GET", "/api/v1/store/catalog")

func store_order(sku: String, idem: String = "") -> Dictionary:
	if idem == "":
		idem = new_idem("ord")
	return await _authed("POST", "/api/v1/store/orders", {
		"sku": sku,
		"idempotency_key": idem,
	})

func store_confirm(order_id: String, idem: String = "") -> Dictionary:
	if idem == "":
		idem = new_idem("ocf")
	return await _authed("POST", "/api/v1/store/orders/%s/confirm-test" % order_id, {
		"idempotency_key": idem,
	})

func health() -> Dictionary:
	return await _request("GET", "/api/v1/health", {}, false)

func _authed(method: String, path: String, body: Dictionary = {}) -> Dictionary:
	return await _request(method, path, body, true)

func _request(method: String, path: String, body: Dictionary, use_auth: bool) -> Dictionary:
	var headers := PackedStringArray(["Content-Type: application/json", "Accept: application/json"])
	if use_auth and access_token != "":
		headers.append("Authorization: Bearer %s" % access_token)
	var payload := ""
	if method != "GET" and not body.is_empty():
		payload = JSON.stringify(body)
	var url := base_url + path
	var http_method := HTTPClient.METHOD_GET if method == "GET" else HTTPClient.METHOD_POST
	var http := HTTPRequest.new()
	http.timeout = TIMEOUT_SEC
	add_child(http)
	var err := http.request(url, headers, http_method, payload)
	if err != OK:
		http.queue_free()
		last_error = "request_error_%d" % err
		request_failed.emit(path, 0, last_error)
		return {"ok": false, "error": last_error, "code": 0}
	var result: Array = await http.request_completed
	http.queue_free()
	var http_result: int = result[0]
	var code: int = result[1]
	var response_body: String = (result[3] as PackedByteArray).get_string_from_utf8()
	if http_result != HTTPRequest.RESULT_SUCCESS:
		last_error = "http_result_%d" % http_result
		request_failed.emit(path, code, last_error)
		return {"ok": false, "error": last_error, "code": code}
	var parsed: Variant = {}
	if response_body != "":
		parsed = JSON.parse_string(response_body)
		if parsed == null:
			parsed = {"raw": response_body}
	if code < 200 or code >= 300:
		last_error = "http_%d" % code
		request_failed.emit(path, code, response_body)
		return {"ok": false, "error": last_error, "code": code, "data": parsed}
	return {"ok": true, "code": code, "data": parsed}
