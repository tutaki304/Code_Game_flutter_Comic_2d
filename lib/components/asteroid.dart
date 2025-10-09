import 'dart:async'; // Async/await support
import 'dart:math'; // Toán học (Random, etc.)

import 'package:cosmic_havoc/components/explosion.dart'; // Hiệu ứng nổ khi asteroid bị phá hủy
import 'package:cosmic_havoc/my_game.dart'; // Game chính để truy cập game state
import 'package:flame/collisions.dart'; // Hệ thống va chạm
import 'package:flame/components.dart'; // Flame components cơ bản
import 'package:flame/effects.dart'; // Hiệu ứng animation
import 'package:flutter/widgets.dart'; // Flutter widgets

/**
 * Asteroid - Destructible space rocks (game enemies)
 * 
 * 🪨 CHỨC NĂNG CHÍNH:
 * - Moving obstacles với random velocity và spin
 * - Multi-hit system: 3 health points, visual feedback
 * - Collision với Player (game over) và Laser (damage)
 * - Splitting mechanic: Large asteroids → 3 smaller fragments
 * - Score system: +1 per hit, +2 bonus for destruction
 * 
 * 🎯 GAMEPLAY MECHANICS:
 * - Screen wrapping: Left/right edges wrap around
 * - Bottom cleanup: Auto-remove khi ra khỏi screen
 * - Knockback effect: Pushed backward when hit
 * - Size-based scaling: Smaller = faster, less health
 * 
 * 💥 DESTRUCTION SEQUENCE:
 * 1. Explosion effect (dust particles)
 * 2. Score bonus (+2 points)
 * 3. Split into 3 smaller fragments (if large enough)
 * 4. Audio feedback (explosion sound)
 * 
 * 🎨 VISUAL EFFECTS:
 * - Random sprite selection (3 variants)
 * - White flash on damage
 * - Continuous rotation animation
 * - Scale-based movement (smaller = faster)
 */
class Asteroid extends SpriteComponent // Kế thừa từ component có sprite
    with
        HasGameReference<MyGame> {
  // Mixin để truy cập game instance

  // ===============================================
  // 🎲 GENERATION CONSTANTS
  // ===============================================

  final Random _random = Random(); // Tạo số ngẫu nhiên cho movement/effects
  static const double _maxSize = 120; // Kích thước tối đa (defines size scale)

  // ===============================================
  // 🚀 MOVEMENT SYSTEM
  // ===============================================

  late Vector2 _velocity; // Vận tốc hiện tại (pixel/giây)
  final Vector2 _originalVelocity =
      Vector2.zero(); // Vận tốc gốc (để reset sau knockback)
  late double _spinSpeed; // Tốc độ quay (radian/giây) cho visual rotation

  // ===============================================
  // ❤️ HEALTH SYSTEM
  // ===============================================

  final double _maxHealth = 3; // Máu tối đa (3 phát để phá hủy)
  late double _health; // Máu hiện tại (scaled by size)

  // ===============================================
  // 🎭 STATE MANAGEMENT
  // ===============================================

  bool _isKnockedback =
      false; // Có đang bị đẩy lùi không? (prevents double-knockback)

  // ===============================================
  // 🏗️ CONSTRUCTOR
  // ===============================================

  /**
   * Asteroid Constructor - Tạo asteroid với size customizable
   * 
   * @param position - Starting position (usually from spawner)
   * @param size - Asteroid size (default = _maxSize = 120)
   * 
   * Initialization sequence:
   * 1. Generate random velocity (based on size)
   * 2. Store original velocity (for knockback reset)
   * 3. Random spin speed (-0.75 to +0.75 rad/s)
   * 4. Scale health based on size
   * 5. Add circular collision hitbox
   */
  Asteroid({required super.position, double size = _maxSize})
      : super(
          size: Vector2.all(size), // Square size (width = height)
          anchor: Anchor.center, // Center anchor for rotation
          priority: -1, // Behind player, above background
        ) {
    // ===== MOVEMENT INITIALIZATION =====
    _velocity = _generateVelocity(); // Calculate random velocity based on size
    _originalVelocity
        .setFrom(_velocity); // Store original for knockback recovery

    // ===== VISUAL EFFECTS =====
    _spinSpeed = _random.nextDouble() * 1.5 -
        0.75; // Xoay ngẫu nhiên: -0.75 đến +0.75 rad/s

    // ===== HEALTH SCALING =====
    _health = size / _maxSize * _maxHealth; // Smaller asteroids = less health

    // ===== COLLISION SETUP =====
    add(CircleHitbox(
        collisionType: CollisionType
            .passive)); // Collision thụ động (các object khác phát hiện ta)
  }

  // ===============================================
  // 🔄 LIFECYCLE METHODS
  // ===============================================

  /**
   * onLoad() - Load random asteroid sprite
   * 
   * Visual variety: 3 different asteroid sprites
   * - asteroid1.png, asteroid2.png, asteroid3.png
   * - Random selection cho visual diversity
   */
  @override
  FutureOr<void> onLoad() async {
    // ===== RANDOM SPRITE SELECTION =====
    final int imageNum = _random.nextInt(3) + 1; // Random 1-3
    sprite = await game.loadSprite('asteroid$imageNum.png');

    return super.onLoad();
  }

  /**
   * update() - Update asteroid position và rotation mỗi frame
   * 
   * Update sequence:
   * 1. Apply velocity to position
   * 2. Handle screen boundary wrapping/cleanup
   * 3. Apply spin rotation
   */
  @override
  void update(double dt) {
    super.update(dt);

    // ===== MOVEMENT UPDATE =====
    position += _velocity * dt; // Apply velocity (pixels/second)

    // ===== BOUNDARY HANDLING =====
    _handleScreenBounds(); // Wrap horizontally, cleanup vertically

    // ===== ROTATION ANIMATION =====
    angle += _spinSpeed * dt; // Apply spin rotation
  }

  // ===============================================
  // 🎲 MOVEMENT GENERATION
  // ===============================================

  /**
   * _generateVelocity() - Calculate random velocity scaled by size
   * 
   * Velocity calculation:
   * 1. Base velocity: X random (-60 to +60), Y downward (100-150)
   * 2. Force factor: Smaller asteroids move faster
   * 3. Final velocity = base * force factor
   * 
   * Size scaling logic: forceFactor = maxSize / currentSize
   * - Large asteroid (120px): factor = 1.0 (normal speed)
   * - Medium asteroid (80px): factor = 1.5 (faster)
   * - Small asteroid (40px): factor = 3.0 (much faster)
   */
  Vector2 _generateVelocity() {
    final double forceFactor = _maxSize / size.x; // Càng nhỏ = factor càng cao

    // ===== BASE VELOCITY CALCULATION =====
    return Vector2(
          _random.nextDouble() * 120 - 60, // X: Random ngang (-60 đến +60)
          100 + _random.nextDouble() * 50, // Y: Xuống dưới (100 đến 150)
        ) *
        forceFactor; // Scale by size (smaller = faster)
  }

  /**
   * _handleScreenBounds() - Handle screen edge behavior
   * 
   * Boundary behaviors:
   * - Bottom edge: Remove asteroid (cleanup)
   * - Left/Right edges: Wraparound (continuous gameplay)
   * - Top edge: No handling (asteroids spawn from top)
   */
  void _handleScreenBounds() {
    // ===== BOTTOM CLEANUP =====
    // Xóa asteroid khi đi qua bottom edge (không còn thấy được)
    if (position.y > game.size.y + size.y / 2) {
      removeFromParent(); // Clean up memory
    }

    // ===== HORIZONTAL WRAPAROUND =====
    // Wrap left/right edges để continuous gameplay
    final double screenWidth = game.size.x;
    if (position.x < -size.x / 2) {
      position.x = screenWidth + size.x / 2; // Wrap từ trái sang phải
    } else if (position.x > screenWidth + size.x / 2) {
      position.x = -size.x / 2; // Wrap từ phải sang trái
    }
  }

  // ===============================================
  // 💥 DAMAGE SYSTEM
  // ===============================================

  /**
   * takeDamage() - Handle laser hit với complete damage sequence
   * 
   * Damage sequence:
   * 1. Play hit sound effect
   * 2. Reduce health by 1
   * 3a. If health <= 0: DESTRUCTION
   *     - Award +2 bonus points
   *     - Remove from game
   *     - Create explosion effect  
   *     - Split into smaller fragments
   * 3b. If still alive: DAMAGE FEEDBACK
   *     - Award +1 hit point
   *     - White flash effect
   *     - Knockback push effect
   * 
   * Called by: Laser.onCollision() khi laser hits asteroid
   */
  void takeDamage() {
    // ===== AUDIO FEEDBACK =====
    game.audioManager.playSound('hit'); // Immediate audio feedback

    // ===== HEALTH REDUCTION =====
    _health--; // Reduce health by 1

    // ===== DESTRUCTION vs DAMAGE =====
    if (_health <= 0) {
      // ===== DESTRUCTION SEQUENCE =====
      game.incrementScore(2); // Bonus points for destruction
      removeFromParent(); // Remove asteroid from game
      _createExplosion(); // Visual explosion effect
      _splitAsteroid(); // Tách thành các mảnh nhỏ hơn (nếu đủ lớn)
    } else {
      // ===== DAMAGE FEEDBACK SEQUENCE =====
      game.incrementScore(1); // Hit points (per laser hit)
      _flashWhite(); // Visual damage feedback
      _applyKnockback(); // Push asteroid backward
    }
  }

  // ===============================================
  // 🎨 VISUAL EFFECTS
  // ===============================================

  /**
   * _flashWhite() - White flash effect khi bị damage
   * 
   * Effect properties:
   * - Color: Pure white (RGB 255,255,255)
   * - Duration: 0.1s flash
   * - Alternate: Flash to white then back to normal
   * - Curve: Smooth easeInOut transition
   * 
   * Visual feedback cho player biết laser hit thành công
   */
  void _flashWhite() {
    final ColorEffect flashEffect = ColorEffect(
      const Color.fromRGBO(255, 255, 255, 1.0), // Pure white color
      EffectController(
        duration: 0.1, // Quick flash (100ms)
        alternate: true, // Nhấp nháy trắng rồi về lại
        curve: Curves.easeInOut, // Smooth transition
      ),
    );
    add(flashEffect); // Áp dụng hiệu ứng cho asteroid
  }

  /**
   * _applyKnockback() - Push asteroid backward khi bị hit
   * 
   * Knockback sequence:
   * 1. Check if already knocked back (prevent stacking)
   * 2. Set knockback flag và stop current velocity
   * 3. Apply upward push movement (-20 pixels)
   * 4. Restore original velocity khi complete
   * 
   * Provides satisfying physical feedback cho laser hits
   */
  void _applyKnockback() {
    if (_isKnockedback) return; // Prevent multiple simultaneous knockbacks

    // ===== KNOCKBACK STATE =====
    _isKnockedback = true; // Set knockback flag
    _velocity.setZero(); // Stop current movement

    // ===== KNOCKBACK EFFECT =====
    final MoveByEffect knockbackEffect = MoveByEffect(
      Vector2(0, -20), // Push upward 20 pixels
      EffectController(
        duration: 0.1, // Quick push (100ms)
      ),
      onComplete: _restoreVelocity, // Khôi phục chuyển động khi xong
    );
    add(knockbackEffect); // Apply effect
  }

  /**
   * _restoreVelocity() - Restore normal movement sau knockback
   * 
   * Recovery sequence:
   * 1. Restore original velocity
   * 2. Clear knockback flag
   * 
   * Called by: knockbackEffect.onComplete callback
   */
  void _restoreVelocity() {
    _velocity.setFrom(_originalVelocity); // Khôi phục chuyển động ban đầu
    _isKnockedback = false; // Clear knockback flag
  }

  void _createExplosion() {
    final Explosion explosion = Explosion(
      position: position.clone(),
      explosionSize: size.x,
      explosionType: ExplosionType.dust,
    );
    game.add(explosion);
  }

  void _splitAsteroid() {
    if (size.x <= _maxSize / 3) return;

    for (int i = 0; i < 3; i++) {
      final Asteroid fragment = Asteroid(
        position: position.clone(),
        size: size.x - _maxSize / 3,
      );
      game.add(fragment);
    }
  }
}
