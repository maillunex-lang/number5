extends Node
## HTTP client for CORE-01 local/dev API. Falls back silently when offline.

signal session_ready(token: String)
signal request_failed(path: String, code: int, body: String)

const DEFAULT_BASE := "http://127.0.0.1:8080"
const TIMEOUT_SEC := 4.0

var base_url: String = DEFAULT_BASE
var access_token: String = ""
var online: bool = false
var last_error: String = ""

var _http: HTTPRequest

func _ready() -> void:
	_http = HTTPRequest.new()
	_http.timeout = TIMEOUT_SEC
	add_child(_http)
	var env_base := OS.get_environment("LUNEX_API_BASE")
	if env_base != "":
		base_url = env_base.rstrip("/")

func has_session() -> bool:
	return access_token != ""

func clear_session() -> void:
	access_token = ""
	online = false

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
		session_ready.emit(access_token)
	return online

func get_wallet() -> Dictionary:
	return await _authed("GET", "/api/v1/wallet")

func get_heroes() -> Dictionary:
	return await _authed("GET", "/api/v1/heroes/collection")

func get_campaign() -> Dictionary:
	return await _authed("GET", "/api/v1/campaign/progress")

func battle_start(stage_id: String, idem: String) -> Dictionary:
	return await _authed("POST", "/api/v1/battle/start", {
		"stage_id": stage_id,
		"idempotency_key": idem,
	})

func battle_claim(battle_id: String, idem: String) -> Dictionary:
	return await _authed("POST", "/api/v1/battle/%s/claim" % battle_id, {
		"idempotency_key": idem,
	})

func summon_roll(banner_id: String, count: int, idem: String) -> Dictionary:
	return await _authed("POST", "/api/v1/summon/roll", {
		"banner_id": banner_id,
		"count": count,
		"idempotency_key": idem,
	})

func afk_claim(idem: String) -> Dictionary:
	return await _authed("POST", "/api/v1/afk/claim", {"idempotency_key": idem})

func store_catalog() -> Dictionary:
	return await _authed("GET", "/api/v1/store/catalog")

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
	var err := _http.request(url, headers, HTTPClient.METHOD_GET if method == "GET" else HTTPClient.METHOD_POST, payload)
	if err != OK:
		last_error = "request_error_%d" % err
		request_failed.emit(path, 0, last_error)
		return {"ok": false, "error": last_error, "code": 0}
	var result: Array = await _http.request_completed
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
