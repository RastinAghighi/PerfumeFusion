extends Node

signal ad_completed(success: bool)
signal ad_started

var is_test_mode: bool = true
var ad_ready: bool = true


func show_rewarded_ad(callback: Callable) -> void:
	emit_signal("ad_started")
	if is_test_mode:
		print("TEST MODE: Simulating rewarded ad...")
		await get_tree().create_timer(1.0).timeout
		print("TEST MODE: Ad completed successfully")
		emit_signal("ad_completed", true)
		if callback.is_valid():
			callback.call(true)
	else:
		# TODO: Phase 7 — wire up JavaScript bridge for Poki/CrazyGames/AdMob.
		# On success: emit ad_completed(true) and callback.call(true)
		# On fail/skip: emit ad_completed(false) and callback.call(false)
		emit_signal("ad_completed", false)
		if callback.is_valid():
			callback.call(false)


func is_ad_available() -> bool:
	if is_test_mode:
		return true
	# TODO: Phase 7 — query ad network readiness.
	return ad_ready
