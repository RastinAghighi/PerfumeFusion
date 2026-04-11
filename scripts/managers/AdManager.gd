extends Node

signal ad_completed(success: bool)
signal ad_started

const COMMERCIAL_BREAK_COOLDOWN_SEC: float = 180.0

var is_test_mode: bool = true
var ad_ready: bool = true

var _poki_initialized: bool = false
var _last_commercial_break_ms: int = -1000000
var _pending_rewarded_callback: Callable
var _poki_rewarded_done_ref: Variant = null


func init_poki() -> void:
	if is_test_mode:
		return
	if _poki_initialized:
		return
	if not OS.has_feature("web"):
		return
	var js_window: Variant = JavaScriptBridge.get_interface("window")
	if js_window == null or not js_window.PokiSDK:
		push_warning("AdManager: PokiSDK not present on window; did the shell load the script?")
		return
	var on_loaded := func(_args):
		js_window.PokiSDK.gameLoadingFinished()
	var loaded_cb: Variant = JavaScriptBridge.create_callback(on_loaded)
	var init_promise: Variant = js_window.PokiSDK.init()
	if init_promise != null and init_promise.then:
		init_promise.then(loaded_cb, loaded_cb)
	else:
		js_window.PokiSDK.gameLoadingFinished()
	_poki_initialized = true


func show_rewarded_ad(callback: Callable) -> void:
	emit_signal("ad_started")
	if is_test_mode:
		print("TEST MODE: Simulating rewarded ad...")
		await get_tree().create_timer(1.0).timeout
		print("TEST MODE: Ad completed successfully")
		emit_signal("ad_completed", true)
		if callback.is_valid():
			callback.call(true)
		return

	if not OS.has_feature("web"):
		_finish_rewarded(false, callback)
		return
	var js_window: Variant = JavaScriptBridge.get_interface("window")
	if js_window == null or not js_window.PokiSDK:
		_finish_rewarded(false, callback)
		return

	_pending_rewarded_callback = callback
	var on_success := func(_args):
		var cb: Callable = _pending_rewarded_callback
		_pending_rewarded_callback = Callable()
		_finish_rewarded(true, cb)
	var on_fail := func(_args):
		var cb: Callable = _pending_rewarded_callback
		_pending_rewarded_callback = Callable()
		_finish_rewarded(false, cb)
	var success_cb: Variant = JavaScriptBridge.create_callback(on_success)
	var fail_cb: Variant = JavaScriptBridge.create_callback(on_fail)
	_poki_rewarded_done_ref = [success_cb, fail_cb]
	var promise: Variant = js_window.PokiSDK.rewardedBreak()
	if promise != null and promise.then:
		promise.then(success_cb, fail_cb)
	else:
		_finish_rewarded(false, callback)
		_pending_rewarded_callback = Callable()


func show_commercial_break() -> void:
	if is_test_mode:
		return
	if not OS.has_feature("web"):
		return
	var now_ms: int = Time.get_ticks_msec()
	if now_ms - _last_commercial_break_ms < int(COMMERCIAL_BREAK_COOLDOWN_SEC * 1000.0):
		return
	var js_window: Variant = JavaScriptBridge.get_interface("window")
	if js_window == null or not js_window.PokiSDK:
		return
	_last_commercial_break_ms = now_ms
	js_window.PokiSDK.commercialBreak()


func is_ad_available() -> bool:
	if is_test_mode:
		return true
	return _poki_initialized and OS.has_feature("web")


func _finish_rewarded(success: bool, callback: Callable) -> void:
	emit_signal("ad_completed", success)
	if callback.is_valid():
		callback.call(success)
