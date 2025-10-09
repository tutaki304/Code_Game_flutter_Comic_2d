import 'dart:async'; // Async/await support

import 'package:cosmic_havoc/my_game.dart'; // Game instance access
import 'package:flame/components.dart'; // Flame components
import 'package:flame/events.dart'; // Touch event handling

/**
 * ShootButton - Touch control button cho mobile laser firing
 * 
 * 🎯 CHỨC NĂNG CHÍNH:
 * - Touch-based shooting control cho mobile devices
 * - Press & hold mechanics: Hold để continuous firing
 * - Visual feedback: Button sprite indicates tap area
 * - Responsive controls: Works với different screen sizes
 * 
 * 🎮 CONTROL MECHANICS:
 * - onTapDown: Start continuous laser firing
 * - onTapUp: Stop laser firing (finger lift)
 * - onTapCancel: Stop firing (touch interrupted)
 * - Player.startShooting(): Begins continuous fire cycle
 * - Player.stopShooting(): Ends fire cycle
 * 
 * 📱 MOBILE OPTIMIZATION:
 * - Size: 80x80 pixels (easy to tap)
 * - Touch target: Large enough cho comfortable use
 * - Visual feedback: Clear button sprite cho user guidance
 * - Position: Managed by parent game layout system
 * 
 * 🔫 INTEGRATION với PLAYER:
 * - Calls Player.startShooting() → activates _isShooting flag
 * - Player update loop handles actual laser spawning
 * - Automatic fire rate limiting trong Player component
 * - Laser level system: Uses current player laser level
 * 
 * 🎨 UI DESIGN:
 * - Simple sprite button (shoot_button.png)
 * - No animation effects (keeps performance high)
 * - Clear visual indication of interactive area
 * - Consistent với other UI elements
 */
class ShootButton extends SpriteComponent
    with
        HasGameReference<MyGame>, // Truy cập game instance
        TapCallbacks {
  // Xử lý sự kiện chạm

  /**
   * Constructor - Tạo shoot button với fixed size
   * 
   * Size: 80x80 pixels - optimal cho mobile touch targets
   * Positioning: Handled by parent layout system
   */
  ShootButton() : super(size: Vector2.all(80));

  // ===============================================
  // 🔄 INITIALIZATION
  // ===============================================

  /**
   * onLoad() - Load button sprite graphic
   * 
   * Simple initialization:
   * 1. Load shoot_button.png từ assets
   * 2. No animations hoặc effects (performance focused)
   * 3. Button ready for touch interaction
   * 
   * Design principle: Minimal overhead cho responsive controls
   */
  @override
  FutureOr<void> onLoad() async {
    // ===== SPRITE LOADING =====
    sprite = await game.loadSprite('shoot_button.png'); // Load hình ảnh button

    return super.onLoad();
  }

  // ===============================================
  // 👆 TOUCH EVENT HANDLING
  // ===============================================

  /**
   * onTapDown() - Handle button press (start shooting)
   * 
   * Triggered when: User finger touches button area
   * Action: Start continuous laser firing
   * 
   * Flow: Touch down → Player.startShooting() → _isShooting = true
   * → Player.update() begins spawning lasers every _fireCooldown
   */
  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);

    // ===== START CONTINUOUS FIRING =====
    game.player.startShooting(); // Activate player shooting state
  }

  /**
   * onTapUp() - Handle button release (stop shooting)
   * 
   * Triggered when: User lifts finger from button
   * Action: Stop laser firing
   * 
   * Flow: Touch up → Player.stopShooting() → _isShooting = false
   * → Player.update() stops spawning lasers
   */
  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);

    // ===== STOP FIRING ON RELEASE =====
    game.player.stopShooting(); // Deactivate player shooting state
  }

  /**
   * onTapCancel() - Handle touch interruption (stop shooting)
   * 
   * Triggered when: Touch gesture interrupted (drag outside, system interrupt)
   * Action: Stop laser firing (safety fallback)
   * 
   * Purpose: Prevent stuck firing khi touch events disrupted
   * Examples: Notification pull-down, app switching, drag outside button
   */
  @override
  void onTapCancel(TapCancelEvent event) {
    super.onTapCancel(event);

    // ===== SAFETY STOP ON CANCEL =====
    game.player.stopShooting(); // Đảm bảo dừng bắn khi bị gián đoạn
  }
}

// ===============================================
// 📝 IMPLEMENTATION NOTES
// ===============================================
//
// 🎮 TOUCH CONTROL DESIGN:
// - Press & hold: Natural mobile control pattern
// - Immediate response: No delay between touch và firing
// - Safety handling: Touch cancel prevents stuck firing
//
// 🔫 SHOOTING INTEGRATION:
// - Player handles actual laser creation/timing
// - Button only controls shooting state flag
// - Laser level system automatic (current player level)
// - Fire rate controlled by Player._fireCooldown
//
// 📱 MOBILE UX CONSIDERATIONS:
// - 80px size: Meets mobile touch target guidelines
// - Clear visual feedback: Button sprite shows tap area
// - Reliable events: All touch scenarios handled
//
// 🔧 PERFORMANCE OPTIMIZATION:
// - No visual effects on button (CPU efficient)
// - Direct method calls (minimal overhead)
// - Simple sprite (fast rendering)
//
// 🎯 ALTERNATIVE CONTROLS:
// - Desktop: Keyboard spacebar (handled by Player.KeyboardHandler)
// - Mobile: This touch button
// - Both can work simultaneously without conflict
//
// 🛡️ ERROR HANDLING:
// - onTapCancel ensures no stuck firing states
// - Player.stopShooting() is safe to call multiple times
// - No crash risk từ rapid tap events
