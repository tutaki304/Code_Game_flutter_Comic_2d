import 'dart:math'; // Random number generation

import 'package:cosmic_havoc/my_game.dart'; // Game instance access
import 'package:flame/components.dart'; // Flame components
import 'package:flutter/widgets.dart'; // Flutter Color class

/**
 * Star - Background star component cho parallax scrolling effect
 * 
 * 🌟 CHỨC NĂNG CHÍNH:
 * - Tạo background stars với different sizes (1-3px)
 * - Parallax scrolling: Bigger stars = faster movement
 * - Infinite loop: Stars wrap from bottom to top
 * - Alpha transparency: Based on size (bigger = more opaque)
 * 
 * 🎨 VISUAL PROPERTIES:
 * - Size: Random 1-3 pixels
 * - Color: White với variable opacity
 * - Speed: Proportional to size (bigger stars fall faster)
 * - Position: Random across screen width
 * 
 * 🔄 BEHAVIOR:
 * - Continuous downward movement
 * - Wraparound when reaching bottom edge
 * - Random repositioning on X-axis after wrap
 */
class Star extends CircleComponent with HasGameReference<MyGame> {
  // ===============================================
  // 🎨 STAR PROPERTIES
  // ===============================================

  final Random _random =
      Random(); // Random generator cho kích thước, vị trí, tốc độ
  final int _maxSize = 3; // Max star size (pixels) - defines size range 1-3
  late double _speed; // Fall speed (pixels/second) - calculated from size

  // ===============================================
  // 🔄 LIFECYCLE METHODS
  // ===============================================

  /**
   * onLoad() - Initialize star properties với random values
   * 
   * Setup sequence:
   * 1. Random size (1-3 pixels)
   * 2. Random position across screen
   * 3. Calculate speed based on size (parallax effect)
   * 4. Set color với alpha transparency
   */
  @override
  Future<void> onLoad() {
    // ===== RANDOM SIZE GENERATION =====
    size =
        Vector2.all(1.0 + _random.nextInt(_maxSize)); // Size range: 1-3 pixels

    // ===== RANDOM INITIAL POSITION =====
    position = Vector2(
      _random.nextDouble() * game.size.x, // X: Random across screen width
      _random.nextDouble() * game.size.y, // Y: Random across screen height
    );

    // ===== PARALLAX SPEED CALCULATION =====
    // Bigger stars fall faster (creates depth illusion)
    _speed = size.x * (40 + _random.nextInt(10)); // Speed = size * (40-49)

    // ===== TRANSPARENCY BASED ON SIZE =====
    // Bigger stars = more opaque (alpha = size / maxSize)
    paint.color = Color.fromRGBO(255, 255, 255, size.x / _maxSize);

    return super.onLoad();
  }

  /**
   * update() - Update star position mỗi frame
   * 
   * Movement logic:
   * 1. Move star downward với calculated speed
   * 2. Check screen bounds (bottom edge)
   * 3. Wraparound: Reset to top với new random X position
   * 
   * Parallax effect: Different sized stars move at different speeds
   */
  @override
  void update(double dt) {
    super.update(dt);

    // ===== DOWNWARD MOVEMENT =====
    position.y += _speed * dt; // Move down với parallax speed

    // ===== SCREEN WRAPAROUND =====
    // Khi star đi qua bottom edge của screen
    if (position.y > game.size.y + size.y / 2) {
      position.y = -size.y / 2; // Reset về đầu màn hình
      position.x = _random.nextDouble() * game.size.x; // New random X position
    }
  }
}

// ===============================================
// 📝 IMPLEMENTATION NOTES
// ===============================================
//
// 🌟 PARALLAX SCROLLING THEORY:
// - Smaller stars (1px) = slower speed = background layer
// - Bigger stars (3px) = faster speed = foreground layer
// - Creates illusion of depth và movement
//
// 🎨 VISUAL DESIGN:
// - White stars với variable transparency
// - Alpha based on size: bigger = more visible
// - Smooth continuous movement
//
// 🔄 INFINITE LOOP:
// - Stars continuously cycle from top to bottom
// - Random X repositioning prevents patterns
// - Seamless background animation
//
// 📱 PERFORMANCE:
// - Lightweight CircleComponent (minimal overhead)
// - Simple update logic (just Y movement)
// - No collision detection needed
