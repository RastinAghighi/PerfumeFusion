extends Node

signal ad_completed(success: bool)
signal ad_started

const COMMERCIAL_BREAK_COOLDOWN_SEC: float = 180.0

var is_test_mode: bool = true
var ad_ready: bool = true

var _platform: String = ""
var _initialized: bool = false
var _last_commercial_break_ms: int = -1000000
var _pending_rewarded_callback: Callable
var _cb_refs: Array = []


func detect_platform() -> String:
	if _platform != "":
		return _platform
	if OS.has_feature("android"):
		_platform = "admob"
		return _platform
	if not OS.has_feature("web"):
		_platform = "none"
		return _platform
	var js_window: Variant = JavaScriptBridge.get_interface("window")
	if js_window == null:
		_platform = "none"
		return _platform
	if js_window.PokiSDK:
		_platform = "poki"
	elif js_window.CrazyGames and js_window.CrazyGames.SDK:
		_platform = "crazygames"
	else:
		_platform = "none"
	return _platform


func init_web_sdk() -> void:
	if is_test_mode or _initialized:
		return
	var platform := detect_platform()
	if platform == "admob":
		_init_admob()
		_initialized = true
		return
	if not OS.has_feature("web"):
		return
	var js_window: Variant = JavaScriptBridge.get_interface("window")
	if js_window == null:
		return
	match platform:
		"poki":
			_init_poki(js_window)
		"crazygames":
			_init_crazygames(js_window)
		_:
			push_warning("AdManager: no supported web SDK detected.")
			return
	_initialized = true


func init_poki() -> void:
	init_web_sdk()


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

	var platform := detect_platform()
	if platform == "admob":
		_pending_rewarded_callback = callback
		_admob_rewarded()
		return
	if not OS.has_feature("web"):
		_finish_rewarded(false, callback)
		return
	var js_window: Variant = JavaScriptBridge.get_interface("window")
	if js_window == null:
		_finish_rewarded(false, callback)
		return

	_pending_rewarded_callback = callback
	match platform:
		"poki":
			_poki_rewarded(js_window)
		"crazygames":
			_crazygames_rewarded(js_window)
		_:
			_pending_rewarded_callback = Callable()
			_finish_rewarded(false, callback)


func show_commercial_break() -> void:
	if is_test_mode:
		return
	var now_ms: int = Time.get_ticks_msec()
	if now_ms - _last_commercial_break_ms < int(COMMERCIAL_BREAK_COOLDOWN_SEC * 1000.0):
		return
	var platform := detect_platform()
	if platform == "admob":
		_last_commercial_break_ms = now_ms
		_admob_interstitial()
		return
	if not OS.has_feature("web"):
		return
	var js_window: Variant = JavaScriptBridge.get_interface("window")
	if js_window == null:
		return
	match platform:
		"poki":
			if js_window.PokiSDK:
				_last_commercial_break_ms = now_ms
				js_window.PokiSDK.commercialBreak()
		"crazygames":
			if js_window.CrazyGames and js_window.CrazyGames.SDK and js_window.CrazyGames.SDK.ad:
				_last_commercial_break_ms = now_ms
				var on_started := func(_a): pass
				var on_finished := func(_a): pass
				var on_error := func(_a): pass
				var started_cb: Variant = JavaScriptBridge.create_callback(on_started)
				var finished_cb: Variant = JavaScriptBridge.create_callback(on_finished)
				var error_cb: Variant = JavaScriptBridge.create_callback(on_error)
				_cb_refs.append_array([started_cb, finished_cb, error_cb])
				var callbacks: Variant = JavaScriptBridge.create_object("Object")
				callbacks.adStarted = started_cb
				callbacks.adFinished = finished_cb
				callbacks.adError = error_cb
				js_window.CrazyGames.SDK.ad.requestAd("midgame", callbacks)


func is_ad_available() -> bool:
	if is_test_mode:
		return true
	return _initialized and detect_platform() != "none"


func _init_poki(js_window: Variant) -> void:
	var on_loaded := func(_args):
		js_window.PokiSDK.gameLoadingFinished()
	var loaded_cb: Variant = JavaScriptBridge.create_callback(on_loaded)
	_cb_refs.append(loaded_cb)
	var init_promise: Variant = js_window.PokiSDK.init()
	if init_promise != null and init_promise.then:
		init_promise.then(loaded_cb, loaded_cb)
	else:
		js_window.PokiSDK.gameLoadingFinished()


func _init_crazygames(js_window: Variant) -> void:
	var sdk: Variant = js_window.CrazyGames.SDK
	var on_ready := func(_args):
		if sdk.game and sdk.game.sdkGameLoadingStop:
			sdk.game.sdkGameLoadingStop()
	var ready_cb: Variant = JavaScriptBridge.create_callback(on_ready)
	_cb_refs.append(ready_cb)
	if sdk.game and sdk.game.sdkGameLoadingStart:
		sdk.game.sdkGameLoadingStart()
	var init_promise: Variant = sdk.init()
	if init_promise != null and init_promise.then:
		init_promise.then(ready_cb, ready_cb)


func _poki_rewarded(js_window: Variant) -> void:
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
	_cb_refs.append_array([success_cb, fail_cb])
	var promise: Variant = js_window.PokiSDK.rewardedBreak()
	if promise != null and promise.then:
		promise.then(success_cb, fail_cb)
	else:
		var cb: Callable = _pending_rewarded_callback
		_pending_rewarded_callback = Callable()
		_finish_rewarded(false, cb)


func _crazygames_rewarded(js_window: Variant) -> void:
	var sdk: Variant = js_window.CrazyGames.SDK
	if sdk == null or not sdk.ad:
		var cb: Callable = _pending_rewarded_callback
		_pending_rewarded_callback = Callable()
		_finish_rewarded(false, cb)
		return
	var on_started := func(_args):
		pass
	var on_finished := func(_args):
		var cb: Callable = _pending_rewarded_callback
		_pending_rewarded_callback = Callable()
		_finish_rewarded(true, cb)
	var on_error := func(_args):
		var cb: Callable = _pending_rewarded_callback
		_pending_rewarded_callback = Callable()
		_finish_rewarded(false, cb)
	var started_cb: Variant = JavaScriptBridge.create_callback(on_started)
	var finished_cb: Variant = JavaScriptBridge.create_callback(on_finished)
	var error_cb: Variant = JavaScriptBridge.create_callback(on_error)
	_cb_refs.append_array([started_cb, finished_cb, error_cb])
	var callbacks: Variant = JavaScriptBridge.create_object("Object")
	callbacks.adStarted = started_cb
	callbacks.adFinished = finished_cb
	callbacks.adError = error_cb
	sdk.ad.requestAd("rewarded", callbacks)


func _finish_rewarded(success: bool, callback: Callable) -> void:
	emit_signal("ad_completed", success)
	if callback.is_valid():
		callback.call(success)


# --- AdMob (Android) skeleton ---
# These stubs exist so platform routing compiles today. Wire them to
# godot-admob-plugin singletons (MobileAds / RewardedAd / InterstitialAd)
# when the plugin is installed. See documents/ANDROID_EXPORT.md.

func _init_admob() -> void:
	push_warning("AdManager: AdMob init not yet implemented (see ANDROID_EXPORT.md).")
	# TODO: MobileAds.initialize()
	# TODO: preload first rewarded + interstitial


func _admob_rewarded() -> void:
	push_warning("AdManager: AdMob rewarded not yet implemented.")
	# TODO: load rewarded ad with REWARDED_AD_UNIT_ID
	# TODO: on user_earned_reward -> _finish_rewarded(true, cb)
	# TODO: on failed_to_load / dismissed_without_reward -> _finish_rewarded(false, cb)
	var cb: Callable = _pending_rewarded_callback
	_pending_rewarded_callback = Callable()
	_finish_rewarded(false, cb)


func _admob_interstitial() -> void:
	push_warning("AdManager: AdMob interstitial not yet implemented.")
	# TODO: load + show interstitial with INTERSTITIAL_AD_UNIT_ID
	# TODO: respect existing 180s cooldown (already enforced by show_commercial_break)
