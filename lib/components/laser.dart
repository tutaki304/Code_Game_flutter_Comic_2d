import 'dart:async'; // Async/await support
import 'dart:math'; // Math functions (sin, cos)

import 'package:cosmic_havoc/components/asteroid.dart'; // Asteroid target for collision
import 'package:cosmic_havoc/my_game.dart'; // Game instance access
import 'package:flame/collisions.dart'; // Collision system
import 'package:flame/components.dart'; // Flame components

/**
 * Laser - Projectile fired by Player ship
 * 
 * 🚀 CHỨC NĂNG CHÍNH:
 * - Player's primary weapon projectile
 * - Travels upward với optional angle (cho spread shots)
 * - Collision detection với asteroids
 * - Auto-cleanup khi ra khỏi screen bounds
 * 
 * 🎯 COLLISION BEHAVIOR:
 * - Hits asteroids → calls asteroid.takeDamage()
 * - Self-destructs on impact
 * - Rectangular hitbox for precise collision
 * 
 * ⚡ MOVEMENT SYSTEM:
 * - Speed: 500 pixels/second upward
 * - Angle support: Cho 10-level laser spread system
 * - Direction: sin/cos calculation for angled shots
 * 
 * 🗑️ CLEANUP:
 * - Auto-remove khi đi qua top edge of screen
 * - Memory efficient (no lingering objects)
 */
class Laser extends SpriteComponent
    with
        HasGameReference<MyGame>, // Truy cập game instance
        CollisionCallbacks {
  // Handle collision events

  /**
   * Constructor - Tạo laser projectile
   * 
   * @param position - Starting position (usually player position)
   * @param angle - Firing angle in radians (0 = straight up, +/- for spread)
   */
  Laser({required super.position, super.angle = 0.0})
      : super(
          anchor: Anchor.center, // Center anchor for rotation
          priority: -1, // Behind player but in front of background
        );

  // ===============================================
  // 🔄 LIFECYCLE METHODS
  // ===============================================

  /**
   * onLoad() - Initialize laser sprite và collision
   * 
   * Setup sequence:
   * 1. Load laser sprite từ assets
   * 2. Scale down to appropriate size (25% original)
   * 3. Add rectangular hitbox for collision detection
   */
  @override
  FutureOr<void> onLoad() async {
    // ===== SPRITE LOADING =====
    sprite = await game.loadSprite('laser.png'); // Load laser texture

    // ===== SIZE ADJUSTMENT =====
    size *= 0.25; // Scale xuống 25% (cân bằng visual/gameplay)

    // ===== COLLISION SETUP =====
    add(RectangleHitbox()); // Rectangle hitbox cho precise collision

    return super.onLoad();
  }

  /**
   * update() - Update laser position và cleanup
   * 
   * Movement logic:
   * 1. Calculate direction vector từ angle (sin/cos)
   * 2. Move laser với speed 500 pixels/second
   * 3. Check screen bounds và cleanup if needed
   * 
   * Math explanation:
   * - angle = 0: straight up (-cos(0) = -1, sin(0) = 0) = (0, -1)
   * - angle = +π/6: right diagonal (sin(π/6) = 0.5, -cos(π/6) = -0.866)
   */
  @override
  void update(double dt) {
    super.update(dt);

    // ===== ANGLED MOVEMENT CALCULATION =====
    // Vector2(sin(angle), -cos(angle)) cho hướng dựa trên góc
    // - sin(angle): horizontal component (left/right)
    // - -cos(angle): vertical component (negative = upward)
    position += Vector2(sin(angle), -cos(angle)) * 500 * dt;

    // ===== SCREEN BOUNDS CLEANUP =====
    // Xóa laser khi đi qua top edge (không còn thấy được)
    if (position.y < -size.y / 2) {
      removeFromParent(); // Clean up memory
    }
  }

  // ===============================================
  // 💥 COLLISION HANDLING
  // ===============================================

  /**
   * onCollision() - Xử lý va chạm với other objects
   * 
   * Collision sequence khi hit asteroid:
   * 1. Check if other object là Asteroid
   * 2. Self-destruct laser (removeFromParent)
   * 3. Damage asteroid (calls asteroid.takeDamage())
   * 
   * @param intersectionPoints - Points where collision occurred
   * @param other - The other component in collision
   */
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    // ===== ASTEROID HIT DETECTION =====
    if (other is Asteroid) {
      removeFromParent(); // Laser self-destructs on impact
      other.takeDamage(); // Gây damage cho asteroid (điểm + hiệu ứng)
    }
    // Chú ý: Laser không va chạm với Player, Pickups, hoặc Lasers khác
  }
}

// ===============================================
// 📝 IMPLEMENTATION NOTES
// ===============================================
//
// 🎯 LASER SPREAD SYSTEM INTEGRATION:
// - Level 1: Single laser (angle = 0)
// - Level 2-10: Multiple lasers với different angles
// - Angle calculation: ±(i * spacing) từ Player.shoot()
//
// ⚡ PERFORMANCE CONSIDERATIONS:
// - Fast movement (500 px/s) for responsive gameplay
// - Auto-cleanup prevents memory leaks
// - Simple rectangular collision for efficiency
//
// 🎨 VISUAL DESIGN:
// - Small sprite (25% scale) for balance
// - Center anchor cho smooth rotation
// - Priority -1 (behind player, above background)
//
// 🔧 ANGLE MATH BREAKDOWN:
// - angle = 0 radians: Vector2(0, -1) = straight up
// - angle = π/6 radians (30°): Vector2(0.5, -0.866) = up-right
// - angle = -π/6 radians (-30°): Vector2(-0.5, -0.866) = up-left
