import 'dart:async'; // Async/await support

import 'package:cosmic_havoc/components/asteroid.dart'; // Asteroid targets
import 'package:cosmic_havoc/my_game.dart'; // Game instance access
import 'package:flame/collisions.dart'; // Collision system
import 'package:flame/components.dart'; // Flame components
import 'package:flame/effects.dart'; // Animation effects
import 'package:flutter/widgets.dart'; // Curves for animations

/**
 * Bomb - Area-of-effect weapon (screen-clear bomb)
 * 
 * 💣 CHỨC NĂNG CHÍNH:
 * - Expanding blast radius weapon
 * - Damages all asteroids within expanding circle
 * - Visual effect: Grows from 1px to 800px over 1 second
 * - Auto-cleanup: Fades out và self-destructs
 * 
 * 🎆 ANIMATION SEQUENCE:
 * 1. Start at size 1px (nearly invisible)
 * 2. Expand to 800px over 1.0 second (screen-covering)
 * 3. Fade out over 0.5 seconds
 * 4. Auto-remove from game (cleanup)
 * 
 * 🎯 COLLISION BEHAVIOR:
 * - Continuous collision detection during expansion
 * - Hits multiple asteroids simultaneously
 * - Each asteroid calls takeDamage() on contact
 * - No collision với Player (friendly fire protection)
 * 
 * 🔊 AUDIO INTEGRATION:
 * - Plays 'fire' sound on deployment
 * - Immediate audio feedback khi bomb activated
 * 
 * 🎮 USAGE:
 * - Dropped by Player khi bomb pickup collected
 * - Emergency weapon cho clearing screen
 * - Strategic timing cho maximum effectiveness
 */
class Bomb extends SpriteComponent
    with
        HasGameReference<MyGame>, // Truy cập game instance
        CollisionCallbacks {
  // Handle collision events

  /**
   * Constructor - Tạo bomb tại specified position
   * 
   * @param position - Deployment position (usually player position)
   * 
   * Initial state: Size 1px, center anchor, behind player priority
   */
  Bomb({required super.position})
      : super(
          size: Vector2.all(1), // Start tiny (will expand)
          anchor: Anchor.center, // Center expansion
          priority: -1, // Behind player, above background
        );

  // ===============================================
  // 🔄 INITIALIZATION & ANIMATION
  // ===============================================

  /**
   * onLoad() - Initialize bomb với complete animation sequence
   * 
   * Setup sequence:
   * 1. Play deployment sound effect
   * 2. Load bomb sprite graphic
   * 3. Setup collision detection
   * 4. Start expansion animation chain
   * 
   * Animation chain (SequenceEffect):
   * - Phase 1: Size expansion (1px → 800px, 1.0s)
   * - Phase 2: Fade out (1.0 → 0.0 opacity, 0.5s)
   * - Phase 3: Auto-remove (cleanup)
   */
  @override
  FutureOr<void> onLoad() async {
    // ===== AUDIO FEEDBACK =====
    game.audioManager.playSound('fire'); // Immediate deployment sound

    // ===== SPRITE LOADING =====
    sprite = await game.loadSprite('bomb.png'); // Load bomb graphic

    // ===== COLLISION SETUP =====
    add(CircleHitbox(isSolid: true)); // Solid hitbox cho continuous collision

    // ===== ANIMATION SEQUENCE =====
    add(SequenceEffect([
      // Chain of effects in order
      // Phase 1: EXPANSION
      SizeEffect.to(
        Vector2.all(800), // Mở rộng đến 800x800 pixels (phủ toàn màn hình)
        EffectController(
          duration: 1.0, // 1 second expansion time
          curve: Curves.easeInOut, // Smooth acceleration/deceleration
        ),
      ),
      // Phase 2: FADE OUT
      OpacityEffect.fadeOut(
        EffectController(duration: 0.5), // 0.5 second fade
      ),
      // Phase 3: CLEANUP
      RemoveEffect(), // Tự động xóa khỏi game
    ]));

    return super.onLoad();
  }

  // ===============================================
  // 💥 COLLISION HANDLING
  // ===============================================

  /**
   * onCollision() - Handle collision với asteroids during expansion
   * 
   * Collision behavior:
   * - Only damages Asteroid objects
   * - Calls asteroid.takeDamage() (same as laser)
   * - Multiple simultaneous hits possible
   * - No friendly fire với Player
   * 
   * @param intersectionPoints - Collision contact points  
   * @param other - The other component in collision
   * 
   * Continuous collision: As bomb expands, hitbox grows,
   * catching more asteroids trong expanding blast radius
   */
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // ===== ASTEROID DAMAGE =====
    if (other is Asteroid) {
      other.takeDamage(); // Same damage system as laser hits
      // Note: Each asteroid can only be hit once per bomb
      // (asteroid.takeDamage() handles health và destruction)
    }
    // Chú ý: Bomb không ảnh hưởng Player, Pickups, hoặc Bombs khác
  }
}

// ===============================================
// 📝 IMPLEMENTATION NOTES
// ===============================================
//
// 💣 WEAPON BALANCE:
// - Large area effect: 800px diameter covers most of screen
// - Slow deployment: 1.0s expansion gives asteroids chance to escape
// - Limited use: Only from bomb pickups (rare resource)
//
// 🎨 VISUAL DESIGN:
// - Starts invisible (1px) cho surprise factor
// - Smooth expansion với easeInOut curve
// - Fade out prevents visual clutter
//
// 🔧 TECHNICAL IMPLEMENTATION:
// - SequenceEffect: Chained animations run automatically
// - CircleHitbox: Grows với sprite size (accurate collision)
// - isSolid: true cho continuous collision detection
//
// 🎮 GAMEPLAY STRATEGY:
// - Best used when screen crowded với asteroids
// - Timing critical: Deploy before being overwhelmed
// - Emergency escape tool cho difficult situations
//
// 🔊 AUDIO DESIGN:
// - 'fire' sound: Immediate feedback cho deployment
// - No explosion sound: Visual effect is primary feedback
