import 'dart:async'; // Async/await support

import 'package:cosmic_havoc/my_game.dart'; // Game instance access
import 'package:flame/collisions.dart'; // Collision system
import 'package:flame/components.dart'; // Flame components
import 'package:flame/effects.dart'; // Animation effects
import 'package:flutter/widgets.dart'; // Curves for animations

/**
 * PickupType - Enum defines available power-up types
 * 
 * 🎁 PICKUP TYPES:
 * - bomb: Area-of-effect weapon (screen clear)
 * - laser: Upgrade laser level (+1, max 10)
 * - shield: Temporary invincibility protection
 */
enum PickupType { bomb, laser, shield }

/**
 * Pickup - Collectible power-ups that enhance player abilities
 * 
 * 🎁 CHỨC NĂNG CHÍNH:
 * - Falling power-ups spawned randomly by PickupSpawner
 * - Player collision triggers power-up effect
 * - Visual: Pulsating animation để attract attention
 * - Movement: Falls downward at constant speed (300 px/s)
 * 
 * 🎮 PICKUP EFFECTS:
 * - BOMB: Deploys screen-clearing explosion
 * - LASER: Increases laser level (1→10, more projectiles)
 * - SHIELD: Activates temporary invincibility
 * 
 * 🎨 VISUAL DESIGN:
 * - Distinct sprites: bomb_pickup.png, laser_pickup.png, shield_pickup.png
 * - Pulsating effect: Scale 1.0 ↔ 0.9 (infinite loop)
 * - Size: 100x100 pixels (easy to collect)
 * 
 * 🔄 LIFECYCLE:
 * - Spawned at random intervals by game
 * - Falls downward until collected or off-screen
 * - Auto-cleanup khi reaches bottom edge
 * 
 * 💫 COLLECTION MECHANICS:
 * - Collision với Player triggers effect
 * - Immediate removal from game
 * - Score bonus (+10 points)
 * - Audio feedback ('collect' sound)
 */
class Pickup extends SpriteComponent with HasGameReference<MyGame> {
  // ===============================================
  // 🎁 PICKUP PROPERTIES
  // ===============================================

  final PickupType pickupType; // Type of power-up (bomb/laser/shield)

  // ===============================================
  // 🏗️ CONSTRUCTOR
  // ===============================================

  /**
   * Pickup Constructor - Tạo pickup tại specified position
   * 
   * @param position - Spawn position (usually from PickupSpawner)
   * @param pickupType - Type of pickup effect (bomb/laser/shield)
   * 
   * Default properties:
   * - Size: 100x100 pixels (consistent collectible size)
   * - Anchor: Center (for proper collision detection)
   */
  Pickup({required super.position, required this.pickupType})
      : super(size: Vector2.all(100), anchor: Anchor.center);

  // ===============================================
  // 🔄 INITIALIZATION & ANIMATION
  // ===============================================

  /**
   * onLoad() - Initialize pickup sprite và pulsating animation
   * 
   * Setup sequence:
   * 1. Load appropriate sprite based on pickup type
   * 2. Add circular collision hitbox
   * 3. Start infinite pulsating animation
   * 
   * Sprite naming convention: "${type}_pickup.png"
   * - bomb_pickup.png, laser_pickup.png, shield_pickup.png
   */
  @override
  FutureOr<void> onLoad() async {
    // ===== SPRITE LOADING =====
    sprite = await game
        .loadSprite('${pickupType.name}_pickup.png'); // Dynamic sprite loading

    // ===== COLLISION SETUP =====
    add(CircleHitbox()); // Circular collision area

    // ===== PULSATING ANIMATION =====
    final ScaleEffect pulsatingEffect = ScaleEffect.to(
      Vector2.all(0.9), // Scale xuống 90%
      EffectController(
        duration: 0.6, // 0.6 second pulse cycle
        alternate: true, // Scale xuống rồi lên lại
        infinite: true, // Continue forever
        curve: Curves.easeInOut, // Smooth pulsing motion
      ),
    );
    add(pulsatingEffect); // Apply pulsating effect

    return super.onLoad();
  }

  // ===============================================
  // 🔄 MOVEMENT & CLEANUP
  // ===============================================

  /**
   * update() - Handle pickup movement và screen bounds
   * 
   * Movement behavior:
   * 1. Constant downward movement (300 pixels/second)
   * 2. Auto-cleanup when reaching bottom edge
   * 
   * Speed design: Slower than asteroids to give player
   * reasonable time to collect while dodging threats
   */
  @override
  void update(double dt) {
    super.update(dt);

    // ===== DOWNWARD MOVEMENT =====
    position.y += 300 * dt; // Fall at moderate speed (300 px/s)

    // ===== SCREEN CLEANUP =====
    // Xóa pickup khi đi qua bottom edge (bỏ lỡ cơ hội)
    if (position.y > game.size.y + size.y / 2) {
      removeFromParent(); // Clean up memory
    }
  }
}

// ===============================================
// 📝 IMPLEMENTATION NOTES  
// ===============================================
//
// 🎁 PICKUP BALANCE:
// - Fall speed: 300 px/s (moderate - catchable but requires effort)
// - Size: 100px (large enough to collect easily)
// - Pulsing: Visual attention grabber
//
// 🎮 GAMEPLAY INTEGRATION:
// - Collection handled by Player.onCollision()
// - Each type triggers different Player method:
//   * bomb → Player.collectBomb()
//   * laser → Player.collectLaser() 
//   * shield → Player.collectShield()
//
// 🎨 VISUAL FEEDBACK:
// - Pulsating animation draws player attention
// - Color coding: Each pickup type has distinct sprite
// - Size consistency: All pickups same size for fair gameplay
//
// 🔧 SPAWN MECHANICS:
// - Created by PickupSpawner at random intervals
// - Random type selection weighted by game balance
// - Position: Random X across screen width
//
// 💫 COLLECTION REWARDS:
// - Score bonus: +10 points per pickup
// - Power-up effect: Varies by type
// - Audio feedback: 'collect' sound on pickup
