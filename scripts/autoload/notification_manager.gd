extends Node
## Слой кратких уведомлений / тостов.

signal toast_requested(text: String, kind: String)

var queue: Array[Dictionary] = []

func toast(text: String, kind: String = "info") -> void:
	queue.append({"text": text, "kind": kind})
	toast_requested.emit(text, kind)

func info(text: String) -> void:
	toast(text, "info")

func success(text: String) -> void:
	toast(text, "success")

func warn(text: String) -> void:
	toast(text, "warn")

func error(text: String) -> void:
	toast(text, "error")
