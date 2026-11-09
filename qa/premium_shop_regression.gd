extends SceneTree

# Validate player-facing premium economy. Runs without IAP or real-money charges.
# A disposable save is used; no actual account data is touched by this script.
var stage = null
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		printerr("PREMIUM QA FAIL: " + message)

func _run() -> void:
	await process_frame
	await process_frame
	stage = root.get_node_or_null("StageDirector")
	_check(stage != null, "StageDirector autoload available")
	if stage == null:
		_finish()
		return
	stage.get_script().set("save_path_override", "user://qa_premium_shop.json")
	var path: String = stage.get_active_save_path()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	stage.dark_matter_gems = 0
	stage.beta_test_gems_granted = false
	stage.beta_test_gems_remaining = 0
	stage.unlocked_skins = ["default", "gold_veteran"]
	stage.selected_skin_id = "default"
	stage.daily_missions = []
	stage.daily_free_pack_claimed = false
	stage.daily_reset_day = int(Time.get_unix_time_from_system() / 86400)
	stage.daily_login_day = 1
	stage.daily_claimed_days = []
	stage.last_daily_calendar_claim_day = -1
	stage.attempts = 5

	_check(stage._grant_beta_test_gems_once(), "First beta grant succeeds")
	_check(stage.dark_matter_gems == 10000, "Beta grant adds exactly 10000 gems")
	_check(stage.beta_test_gems_remaining == 10000, "Beta grant is tracked separately")
	_check(not stage._grant_beta_test_gems_once(), "Second beta grant blocked")
	_check(stage.dark_matter_gems == 10000, "Beta grant cannot be duplicated")

	_check(not stage.buy_skin_with_gems("unknown_skin"), "Unknown skin cannot be bought")
	_check(stage.buy_skin_with_gems("neon_hunter"), "Cosmetic skin purchase succeeds")
	_check(stage.dark_matter_gems == 9880, "Skin purchase charges exactly 120 gems")
	_check(stage.beta_test_gems_remaining == 9880, "Beta spending subtracts tracked grant")
	_check(stage.unlocked_skins.has("neon_hunter"), "Purchased skin owned")
	_check(stage.selected_skin_id == "neon_hunter", "Purchased skin equipped")
	_check(not stage.buy_skin_with_gems("neon_hunter"), "Purchased skin cannot be charged twice")
	_check(stage.dark_matter_gems == 9880, "Duplicate click cannot drain gems")
	_check(not stage.buy_skin_with_gems("gold_veteran"), "Existing free starter skin cannot be charged")
	_check(stage.dark_matter_gems == 9880, "Invalid skin purchase leaves balance intact")

	stage.save_campaign_profile()
	stage.dark_matter_gems = 0
	stage.beta_test_gems_granted = false
	stage.unlocked_skins = ["default"]
	stage.load_campaign_profile()
	_check(stage.dark_matter_gems == 9880, "Spent balance persists after save/load")
	_check(stage.beta_test_gems_granted, "Beta granted flag persists after save/load")
	_check(stage.unlocked_skins.has("neon_hunter"), "Purchased skin persists after save/load")
	_check(not stage._grant_beta_test_gems_once(), "Relogin cannot trigger another beta grant")
	stage._revoke_unspent_beta_gems()
	_check(stage.dark_matter_gems == 0, "Public-release cleanup removes only remaining beta gems")
	_check(stage.beta_test_gems_remaining == 0, "Beta grant remainder clears after cleanup")
	_check(stage.unlocked_skins.has("neon_hunter"), "Previously purchased cosmetics persist after beta wallet cleanup")

	stage.dark_matter_gems = 50
	_check(not stage.buy_skin_with_gems("void_sniper"), "Insufficient premium balance rejected")
	_check(stage.dark_matter_gems == 50, "Failed skin purchase cannot charge gems")

	stage.dark_matter_gems = 100
	stage.attempts = 3
	_check(stage.buy_full_attempts_refill(), "Refill works via existing premium purchase method")
	_check(stage.dark_matter_gems == 40 and stage.attempts == 5, "Refill costs 60 gems, restores five attempts")
	_check(not stage.buy_full_attempts_refill(), "Cannot recharge already full attempts")
	_check(stage.dark_matter_gems == 40, "Duplicate refill cannot charge")

	stage.dark_matter_gems = 0
	stage.daily_free_pack_claimed = false
	_check(stage.claim_daily_free_shop_pack(), "Daily F2P supplies claim succeeds")
	_check(stage.dark_matter_gems == 0, "Daily F2P supplies do not grant premium gems")
	_check(not stage.claim_daily_free_shop_pack(), "Daily supplies only once per day")

	stage.dark_matter_gems = 0
	stage.daily_login_day = 1
	stage.daily_claimed_days = []
	stage.last_daily_calendar_claim_day = -1
	var calendar: Dictionary = stage.claim_daily_reward(1)
	_check(bool(calendar.get("ok", false)), "Day one login reward claim succeeds")
	_check(stage.dark_matter_gems == 0, "Login calendar does not grant premium gems")
	for reward in stage.DAILY_REWARDS_TABLE:
		_check(int(reward.get("gems", -1)) == 0, "All 7 daily login rewards give no premium gems")
	for mission in stage.DEFAULT_DAILY_MISSIONS:
		_check(int(mission.get("gems", -1)) == 0, "Daily missions give no premium gems")

	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if FileAccess.file_exists(path + ".bak"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path + ".bak"))
	_finish()

func _finish() -> void:
	if failures.is_empty():
		print("PREMIUM QA PASS: %d checks (no actual IAP tested)" % checks)
		quit(0)
	else:
		printerr("PREMIUM QA FAILED: %d of %d checks" % [failures.size(), checks])
		quit(1)
