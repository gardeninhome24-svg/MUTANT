extends RefCounted
class_name MSAttemptOfferRules
## Non-invasive proposal; existing StageDirector remains sole owner of attempts and wallet.
const MAX_ATTEMPTS: int = 5
const REGEN_SECONDS: int = 1800
const FULL_REFILL_GEMS_PROPOSED: int = 60
const SINGLE_REFILL_GEMS_PROPOSED: int = 18
const REVIVE_GEMS_EXISTING: int = 30

static func can_start_campaign(attempts: int, is_practice: bool) -> bool:
    return is_practice or attempts > 0

static func can_buy_full_refill(attempts: int, gems: int) -> bool:
    return attempts < MAX_ATTEMPTS and gems >= FULL_REFILL_GEMS_PROPOSED

static func can_buy_single(attempts: int, gems: int) -> bool:
    return attempts < MAX_ATTEMPTS and gems >= SINGLE_REFILL_GEMS_PROPOSED

static func can_revive(already_revived: bool, gems: int) -> bool:
    return not already_revived and gems >= REVIVE_GEMS_EXISTING

static func quote_full_refill(attempts: int) -> Dictionary:
    return {"cost": FULL_REFILL_GEMS_PROPOSED, "gained": maxi(0, MAX_ATTEMPTS - clampi(attempts, 0, MAX_ATTEMPTS))}

static func safe_rewarded_ad_allowed(verified_callback_received: bool, server_reward_id_unique: bool) -> bool:
    return verified_callback_received and server_reward_id_unique
