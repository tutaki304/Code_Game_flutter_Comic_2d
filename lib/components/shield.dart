import 'dart:async'; // Async/await support

import 'package:cosmic_havoc/components/asteroid.dart'; // Asteroid collision target
import 'package:cosmic_havoc/my_game.dart'; // Game instance access
import 'package:flame/collisions.dart'; // Collision system
import 'package:flame/components.dart'; // Flame components
import 'package:flame/effects.dart'; // Animation effects
import 'package:flutter/widgets.dart'; // Curves for animations

/**
 * Shield - Temporary protective barrier around Player
 * 
 * 🛡️ CHỨC NĂNG CHÍNH:
 * - Protective barrier surrounding player ship
 * - Destroys asteroids on contact (offensive defense)
 * - Limited duration: 5 seconds total (3s active + 2s fade)
 * - Visual feedback: Pulsating animation + fade warning
 * 
 * 🔄 LIFECYCLE SEQUENCE:
 * 1. Activation: Spawned by Player.collectShield()
 * 2. Active phase: 3 seconds full protection + pulsating
 * 3. Warning phase: 2 seconds fade out (still protective)
 * 4. Expiration: Auto-remove + clear Player reference
 * 
 * 🎯 DEFENSIVE MECHANICS:  
 * - Collision với asteroids → asteroid.takeDamage()
 * - Player invulnerable to asteroid collision while active
 * - Area protection: 200x200 pixels (larger than player)
 * - No collision với lasers hoặc pickups
 * 
 * 🎨 VISUAL EFFECTS:
 * - Pulsating animation: Scale 1.0 ↔ 1.1 (infinite)
 * - Fade out warning: Last 2 seconds indicate expiration  
 * - Positioning: Automatically follows player movement
 * 
 * 💫 STRATEGIC USAGE:
 * - Emergency protection trong crowded asteroid fields
 * - Offensive capability: Rams through asteroid clusters
 * - Limited resource: Only from shield pickups
 */
class Shield extends SpriteComponent
    with
        HasGameReference<MyGame>, // Truy cập game instance
        CollisionCallbacks {
  // Handle collision events

  /**
   * Constructor - Tạo shield với fixed size và center anchor
   * 
   * Size: 200x200 pixels (larger than player cho full coverage)
   * Anchor: Center (for proper positioning around player)
   */
  Shield() : super(size: Vector2.all(200), anchor: Anchor.center);

  // ===============================================
  // 🔄 INITIALIZATION & EFFECTS
  // ===============================================

  /**
   * onLoad() - Initialize shield với complete effect sequence
   * 
   * Setup sequence:
   * 1. Load shield sprite graphic
   * 2. Position around player (offset by player size)
   * 3. Add circular collision detection
   * 4. Start pulsating visual effect
   * 5. Schedule fade-out và expiration
   * 
   * Timing breakdown:
   * - 0-3s: Active protection với pulsating
   * - 3-5s: Fade out warning (still protective)
   * - 5s: Auto-expire và cleanup
   */
  @override
  FutureOr<void> onLoad() async {
    // ===== SPRITE LOADING =====
    sprite = await game.loadSprite('shield.png'); // Load shield graphic

    // ===== POSITIONING =====
    position += game.player.size / 2; // Center around player position

    // ===== COLLISION SETUP =====
    add(CircleHitbox()); // Circular collision area

    // ===== PULSATING ANIMATION =====
    final ScaleEffect pulsatingEffect = ScaleEffect.to(
      Vector2.all(1.1), // Scale lên 110%
      EffectController(
        duration: 0.6, // 0.6s pulsing cycle
        alternate: true, // Scale lên rồi xuống
        infinite: true, // Tiếp tục suốt thời gian shield tồn tại
        curve: Curves.easeInOut, // Smooth pulsing motion
      ),
    );
    add(pulsatingEffect); // Apply pulsating effect

    // ===== EXPIRATION SEQUENCE =====
    final OpacityEffect fadeOutEffect = OpacityEffect.fadeOut(
      EffectController(
        duration: 2.0, // 2s fade duration
        startDelay: 3.0, // Start after 3s (warning phase)
      ),
      onComplete: () {
        // ===== CLEANUP ON EXPIRATION =====
        removeFromParent(); // Remove shield from game
        game.player.activeShield = null; // Clear player reference
      },
    );
    add(fadeOutEffect); // Schedule expiration

    return super.onLoad();
  }

  // ===============================================
  // 💥 COLLISION HANDLING
  // ===============================================

  /**
   * onCollision() - Handle collision với asteroids (offensive defense)
   * 
   * Shield collision behavior:
   * - Destroys asteroids on contact
   * - Calls asteroid.takeDamage() (same as laser/bomb)
   * - No collision với Player (friendly protection)
   * - No collision với Pickups hoặc other weapons
   * 
   * @param intersectionPoints - Collision contact points
   * @param other - The other component in collision
   * 
   * Offensive defense concept: Shield actively destroys threats
   * rather than just blocking them (more engaging gameplay)
   */
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // ===== ASTEROID DESTRUCTION =====
    if (other is Asteroid) {
      other.takeDamage(); // Destroy asteroid on contact
      // Note: Shield never takes damage itself (temporary invulnerability)
    }
    // Note: Shield doesn't collide với Player, Lasers, hoặc Pickups
  }
}

// ===============================================
// 📝 IMPLEMENTATION NOTES
// ===============================================
//
// 🛡️ SHIELD MECHANICS:
// - Duration: 5 seconds total protection
// - Size: 200px diameter (full player coverage)
// - Offensive: Destroys asteroids rather than blocking
// - Single use: Expires after timer, requires new pickup
//
// 🎮 GAMEPLAY INTEGRATION:
// - Activated by Player.collectShield() từ shield pickup
// - Player.activeShield reference prevents multiple shields
// - Player collision checking skipped while shield active
//
// 🎨 VISUAL FEEDBACK:
// - Pulsating: Indicates active protection status
// - Fade warning: Last 2 seconds show impending expiration
// - Size: Large enough to clearly indicate protection area
//
// ⏱️ TIMING STRATEGY:
// - 3s active phase: Full protection với visual stability
// - 2s warning phase: Fade out indicates prepare for vulnerability
// - Auto-cleanup: No manual management required
//
// 🔧 TECHNICAL DETAILS:
// - CircleHitbox: Accurate collision detection
// - Player reference: Proper cleanup on expiration
// - Effect chaining: Pulsating + fade controlled separately
