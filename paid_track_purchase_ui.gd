extends Control

# Paid Track Purchase UI - Real Money IAP (In-App Purchase)
# Integrates with platform stores (Google Play, Apple App Store)

signal purchase_confirmed(tier: int)
signal purchase_cancelled

# UI Nodes
var overlay: ColorRect
var panel: Panel
var title_label: Label
var description_label: RichTextLabel
var cost_label: Label
var confirm_button: Button
var cancel_button: Button
var dev_test_button: Button  # For testing without payment

# Purchase data
var tier_to_unlock: int = 1
var current_price_usd: float = 4.99

# --- PRICING TIERS (USD) ---
# Scale up by $1 per tier for simplicity
const TIER_PRICES := {
	1: 4.99,
	2: 5.99,
	3: 6.99,
	4: 7.99,
	5: 8.99,
	6: 9.99,
	7: 10.99,
	8: 11.99,
	9: 12.99,
	10: 13.99
}

# Development mode - allows free unlock for testing
# SET TO FALSE FOR PRODUCTION!
const DEV_MODE := true

func _ready() -> void:
	_create_ui()

	# Apply theme
	if Engine.has_singleton("UIStyler"):
		UIStyler.apply_theme_to_node(self)

func _create_ui() -> void:
	# Full screen overlay (semi-transparent)
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.7)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	# Center panel
	panel = Panel.new()
	panel.custom_minimum_size = Vector2(340, 400)
	panel.position = Vector2(25, 220)
	add_child(panel)

	# Title
	title_label = Label.new()
	title_label.text = "🔓 UNLOCK PAID TRACK"
	title_label.position = Vector2(20, 15)
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.custom_minimum_size = Vector2(300, 30)
	panel.add_child(title_label)

	# Description
	description_label = RichTextLabel.new()
	description_label.position = Vector2(20, 55)
	description_label.custom_minimum_size = Vector2(300, 180)
	description_label.bbcode_enabled = true
	description_label.fit_content = true
	description_label.scroll_active = false
	panel.add_child(description_label)

	# Cost label
	cost_label = Label.new()
	cost_label.position = Vector2(20, 245)
	cost_label.add_theme_font_size_override("font_size", 20)
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.custom_minimum_size = Vector2(300, 35)
	panel.add_child(cost_label)

	# Confirm button (triggers IAP)
	confirm_button = Button.new()
	confirm_button.text = "Purchase with Real Money"
	confirm_button.position = Vector2(40, 295)
	confirm_button.custom_minimum_size = Vector2(260, 45)
	confirm_button.pressed.connect(_on_confirm_pressed)
	panel.add_child(confirm_button)

	# Cancel button
	cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.position = Vector2(110, 350)
	cancel_button.custom_minimum_size = Vector2(120, 40)
	cancel_button.pressed.connect(_on_cancel_pressed)
	panel.add_child(cancel_button)

	# Dev test button (only visible in DEV_MODE)
	if DEV_MODE:
		dev_test_button = Button.new()
		dev_test_button.text = "[DEV] Free Unlock"
		dev_test_button.position = Vector2(40, 350)
		dev_test_button.custom_minimum_size = Vector2(60, 40)
		dev_test_button.pressed.connect(_on_dev_test_unlock)
		panel.add_child(dev_test_button)

		# Adjust cancel button position
		cancel_button.position.x = 240

func show_purchase_dialog(tier: int) -> void:
	tier_to_unlock = tier
	current_price_usd = TIER_PRICES.get(tier, 4.99)

	# Update UI
	title_label.text = "🔓 UNLOCK TIER %d PAID TRACK" % tier

	# Get rewards info
	var rewards = MilestoneManager.get_total_rewards_for_tier(tier)

	description_label.text = """[center][b]Premium Battle Pass - Tier %d[/b][/center]

[b]Unlock the paid track to claim:[/b]

• [color=cyan]%s Quantum Cores[/color] 🔮
• [color=yellow]%s Fragments[/color] 💎
• [color=magenta]%d Data Disks[/color] 📀

[b]Plus all future paid rewards in this tier![/b]

This unlock is [b]permanent[/b] for Tier %d.
One-time purchase, keeps forever!""" % [
		tier,
		NumberFormatter.format(rewards["paid_quantum_cores"]),
		NumberFormatter.format(rewards["paid_fragments"]),
		rewards["paid_data_disks"],
		tier
	]

	# Update cost label
	cost_label.text = "Price: $%.2f USD" % current_price_usd

	visible = true

func _on_confirm_pressed() -> void:
	# TODO: Integrate with platform IAP system
	# This is where you'd call Google Play Billing or Apple StoreKit

	print("💳 Initiating IAP purchase for Tier %d Battle Pass ($%.2f)" % [tier_to_unlock, current_price_usd])

	# Platform-specific IAP integration needed here:
	#
	# For Android (Google Play):
	# - Use GodotGooglePlayBilling plugin
	# - Call purchase() with SKU like "battle_pass_tier_1"
	# - Handle purchase callback
	#
	# For iOS (Apple App Store):
	# - Use SKStoreReviewController or In-App Purchase plugin
	# - Call startPayment() with product ID
	# - Handle transaction callback
	#
	# For Web (if applicable):
	# - Use PayPal, Stripe, or other web payment gateway
	# - Handle webhook for purchase confirmation

	# Example pseudocode for Google Play:
	# if OS.get_name() == "Android":
	#     var payment = GooglePlayBilling.new()
	#     payment.purchase_success.connect(_on_iap_success)
	#     payment.purchase_failed.connect(_on_iap_failed)
	#     payment.purchase("battle_pass_tier_%d" % tier_to_unlock)

	# For now, show error message in production
	if not DEV_MODE:
		print("❌ IAP not implemented yet! Contact developer to enable payments.")
		_show_error_dialog("Payment system not yet implemented.\nPlease check for updates.")
	else:
		print("⚠️ DEV_MODE enabled - use [DEV] Free Unlock button for testing")

func _on_iap_success(purchase_token: String, product_id: String) -> void:
	# Called when IAP purchase succeeds
	print("✅ IAP purchase successful: %s" % product_id)

	# TODO: Verify receipt with your backend server
	# This prevents fraudulent purchases
	# var verified = await verify_receipt_with_server(purchase_token, product_id)
	# if not verified:
	#     print("❌ Receipt verification failed!")
	#     return

	# Grant the paid track unlock
	if MilestoneManager.unlock_paid_track(tier_to_unlock):
		print("🎉 Tier %d Paid Track unlocked via IAP!" % tier_to_unlock)
		emit_signal("purchase_confirmed", tier_to_unlock)
		queue_free()
	else:
		print("❌ Failed to unlock paid track after successful payment!")
		_show_error_dialog("Purchase succeeded but unlock failed.\nContact support with transaction ID: %s" % purchase_token)

func _on_iap_failed(error_code: int, error_message: String) -> void:
	# Called when IAP purchase fails
	print("❌ IAP purchase failed: [%d] %s" % [error_code, error_message])

	# Show user-friendly error
	var user_message = "Purchase failed: %s" % error_message
	if error_code == 1:  # User cancelled
		user_message = "Purchase cancelled."
	elif error_code == 2:  # Network error
		user_message = "Network error. Please check your connection."
	elif error_code == 3:  # Already owned
		user_message = "You already own this item!"
		# Grant it anyway in case of sync issue
		MilestoneManager.unlock_paid_track(tier_to_unlock)

	_show_error_dialog(user_message)

func _show_error_dialog(message: String) -> void:
	# Simple error display (could be a popup in production)
	print("🚨 ERROR: %s" % message)
	# TODO: Show actual error dialog UI

func _on_dev_test_unlock() -> void:
	# Development-only: Free unlock for testing
	if not DEV_MODE:
		return

	print("🔓 [DEV] Free unlock for Tier %d" % tier_to_unlock)

	if MilestoneManager.unlock_paid_track(tier_to_unlock):
		emit_signal("purchase_confirmed", tier_to_unlock)
		queue_free()
	else:
		print("❌ Failed to unlock paid track")

func _on_cancel_pressed() -> void:
	emit_signal("purchase_cancelled")
	queue_free()

# --- HELPER: Product ID Generation ---
# Generate platform-specific product IDs for IAP
func get_product_id(tier: int) -> String:
	# Format: com.yourcompany.subroutinedefense.battlepass.tier1
	# Adjust based on your app's package name
	return "com.yourcompany.subroutinedefense.battlepass.tier%d" % tier
