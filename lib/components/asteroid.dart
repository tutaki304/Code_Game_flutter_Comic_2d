import 'dart:async'; // Hỗ trợ Async/await
import 'dart:math'; // Toán học (Random, etc.)

import 'package:cosmic_havoc/components/explosion.dart'; // Hiệu ứng nổ khi asteroid bị phá hủy
import 'package:cosmic_havoc/components/pickup.dart'; // Import pickup để spawn coin
import 'package:cosmic_havoc/my_game.dart'; // Game chính để truy cập game state
import 'package:flame/collisions.dart'; // Hệ thống va chạm
import 'package:flame/components.dart'; // Flame components cơ bản
import 'package:flame/effects.dart'; // Hiệu ứng animation
import 'package:flutter/widgets.dart'; // Flutter widgets

/**
 * Asteroid - Tảng đá không gian có thể phá hủy (kẻ thù trong game)
 * 
 * 🪨 CHỨC NĂNG CHÍNH:
 * - Chướng ngại vật di chuyển với velocity và xoay ngẫu nhiên
 * - Hệ thống nhiều hit: 3 điểm máu, phản hồi visual
 * - Va chạm với Player (game over) và Laser (damage)
 * - Cơ chế tách: Asteroid lớn → 3 mảnh nhỏ hơn
 * - Hệ thống điểm: +1 mỗi hit, +2 bonus khi phá hủy
 * 
 * 🎯 CƠ CHẾ GAMEPLAY:
 * - Wrap màn hình: Cạnh trái/phải wrap qua lại
 * - Dọn dẹp dưới: Tự động xóa khi ra khỏi màn hình
 * - Hiệu ứng knockback: Bị đẩy lùi khi trúng đòn
 * - Scale theo kích thước: Nhỏ hơn = nhanh hơn, ít máu hơn
 * 
 * 💥 CHUỖI PHÁ HỦY:
 * 1. Hiệu ứng nổ (particle bụi)
 * 2. Bonus điểm (+2 điểm)
 * 3. Tách thành 3 mảnh nhỏ hơn (nếu đủ lớn)
 * 4. Phản hồi âm thanh (tiếng nổ)
 * 
 * 🎨 HIỆU ỨNG VISUAL:
 * - Chọn sprite ngẫu nhiên (3 biến thể)
 * - Nhấp nháy trắng khi bị damage
 * - Animation xoay liên tục
 * - Di chuyển theo scale (nhỏ hơn = nhanh hơn)
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

  late String _spriteName; // Lưu tên sprite để biết loại asteroid nào

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
          size: Vector2.all(size), // Kích thước vuông (rộng = cao)
          anchor: Anchor.center, // Điểm neo giữa cho xoay
          priority: -1, // Phía sau player, trước background
        ) {
    // ===== MOVEMENT INITIALIZATION =====
    _velocity =
        _generateVelocity(); // Tính toán velocity ngẫu nhiên dựa trên size
    _originalVelocity
        .setFrom(_velocity); // Lưu trữ ban đầu cho knockback recovery

    // ===== VISUAL EFFECTS =====
    _spinSpeed = _random.nextDouble() * 1.5 -
        0.75; // Xoay ngẫu nhiên: -0.75 đến +0.75 rad/s

    // ===== HEALTH SCALING =====
    _health = size / _maxSize * _maxHealth; // Asteroid nhỏ hơn = ít máu hơn

    // ===== COLLISION SETUP =====
    add(CircleHitbox(
        collisionType: CollisionType
            .passive)); // Collision thụ động (các object khác phát hiện ta)
  }

  // ===============================================
  // 🔄 LIFECYCLE METHODS
  // ===============================================

  /**
   * onLoad() - Load sprite asteroid ngẫu nhiên
   * 
   * Đa dạng visual: 3 sprite asteroid khác nhau
   * - asteroid1.png, asteroid2.png, asteroid3.png
   * - Chọn ngẫu nhiên để đa dạng visual
   */
  @override
  FutureOr<void> onLoad() async {
    // ===== RANDOM SPRITE SELECTION =====
    final int imageNum = _random.nextInt(3) + 1; // Ngẫu nhiên 1-3
    _spriteName = 'asteroid$imageNum.png'; // Lưu tên sprite
    sprite = await game.loadSprite(_spriteName);

    return super.onLoad();
  }

  /**
   * update() - Cập nhật vị trí và xoay asteroid mỗi frame
   * 
   * Chuỗi cập nhật:
   * 1. Áp dụng velocity cho vị trí
   * 2. Xử lý wrap/cleanup ranh giới màn hình
   * 3. Áp dụng xoay quay
   */
  @override
  void update(double dt) {
    super.update(dt);

    // ===== MOVEMENT UPDATE =====
    position += _velocity * dt; // Áp dụng velocity (pixels/giây)

    // ===== BOUNDARY HANDLING =====
    _handleScreenBounds(); // Wrap ngang, cleanup dọc

    // ===== ROTATION ANIMATION =====
    angle += _spinSpeed * dt; // Áp dụng xoay quay
  }

  // ===============================================
  // 🎲 MOVEMENT GENERATION
  // ===============================================

  /**
   * _generateVelocity() - Calculate random velocity scaled by size
   * 
   * Tính toán velocity:
   * 1. Velocity cơ bản: X ngẫu nhiên (-45 đến +45), Y xuống dưới (75-112)
   * 2. Hệ số lực: Asteroid nhỏ hơn di chuyển nhanh hơn
   * 3. Velocity cuối = cơ bản * hệ số lực
   * 
   * Logic scale kích thước: forceFactor = kích thước tối đa / kích thước hiện tại
   * - Asteroid lớn (120px): hệ số = 1.0 (tốc độ bình thường)
   * - Asteroid trung (80px): hệ số = 1.5 (nhanh hơn)
   * - Asteroid nhỏ (40px): hệ số = 3.0 (nhanh nhiều)
   * 
   * 🎮 Màn hình nhỏ: Giảm 25% tốc độ để dễ né tránh hơn
   */
  Vector2 _generateVelocity() {
    final double forceFactor = _maxSize / size.x; // Càng nhỏ = factor càng cao

    // ===== BASE VELOCITY CALCULATION =====
    // 🎮 Giảm 25%: X từ (-60,+60) -> (-45,+45), Y từ (100-150) -> (75-112)
    return Vector2(
          _random.nextDouble() * 90 - 45, // X: Random ngang (-45 đến +45)
          75 + _random.nextDouble() * 37, // Y: Xuống dưới (75 đến 112)
        ) *
        forceFactor; // Scale theo size (nhỏ hơn = nhanh hơn)
  }

  /**
   * _handleScreenBounds() - Xử lý hành vi cạnh màn hình
   * 
   * Hành vi biên:
   * - Cạnh dưới: Loại bỏ asteroid (dọn dẹp)
   * - Cạnh trái/phải: Wrap qua lại (gameplay liên tục)
   * - Cạnh trên: Không xử lý (asteroid spawn từ trên)
   */
  void _handleScreenBounds() {
    // ===== BOTTOM CLEANUP =====
    // Xóa asteroid khi đi qua bottom edge (không còn thấy được)
    if (position.y > game.size.y + size.y / 2) {
      removeFromParent(); // Dọn dẹp bộ nhớ
    }

    // ===== HORIZONTAL WRAPAROUND =====
    // Wrap cạnh trái/phải để gameplay liên tục
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
   * takeDamage() - Xử lý laser đánh trúng với chuỗi damage hoàn chỉnh
   * 
   * Chuỗi damage:
   * 1. Phát âm thanh đánh trúng
   * 2. Giảm health xuống 1
   * 3a. Nếu health <= 0: PHÁ HỦY
   *     - Spawn coin khi phá hủy asteroid NHỎ NHẤT (không còn tách)
   *     - TẤT CẢ loại asteroid (1,2,3) đều rơi coin ở mảnh cuối
   *     - Loại bỏ khỏi game
   *     - Tạo hiệu ứng nổ
   *     - Tách thành các mảnh nhỏ hơn (nếu đủ lớn)
   * 3b. Nếu vẫn sống: PHẢN HỒI DAMAGE
   *     - Không tăng điểm khi hit (chỉ khi thu coin)
   *     - Hiệu ứng flash trắng
   *     - Hiệu ứng đẩy lùi
   * 
   * Được gọi bởi: Laser.onCollision() khi laser trúng asteroid
   */
  void takeDamage() {
    // ===== AUDIO FEEDBACK =====
    game.audioManager.playSound('hit'); // Phản hồi âm thanh ngay lập tức

    // ===== HEALTH REDUCTION =====
    _health--; // Giảm máu xuống 1

    // ===== DESTRUCTION vs DAMAGE =====
    if (_health <= 0) {
      // ===== DESTRUCTION SEQUENCE =====

      // Spawn coin KHI PHÁ HỦY asteroid NHỎ NHẤT (viên cuối cùng, không còn tách)
      // TẤT CẢ loại asteroid (1,2,3) đều rơi coin ở mảnh cuối
      // Điều kiện: size <= 40 (maxSize/3) - không còn tách nữa
      if (size.x <= _maxSize / 3) {
        _spawnCoin();
      }

      removeFromParent(); // Xóa asteroid khỏi game
      _createExplosion(); // Hiệu ứng nổ
      _splitAsteroid(); // Tách thành các mảnh nhỏ hơn (nếu đủ lớn)
    } else {
      // ===== DAMAGE FEEDBACK SEQUENCE =====
      // Không tăng điểm ở đây nữa - điểm chỉ tăng khi thu coin
      _flashWhite(); // Phản hồi visual damage
      _applyKnockback(); // Đẩy asteroid về phía sau
    }
  }

  // ===============================================
  // 💰 COIN SPAWNING
  // ===============================================

  /**
   * _spawnCoin() - Spawn coin tại vị trí asteroid bị phá hủy
   * 
   * ⚠️ ĐIỀU KIỆN QUAN TRỌNG:
   * - CHỈ gọi khi asteroid3.png
   * - CHỈ gọi khi là viên cuối cùng (nhỏ nhất, không còn tách)
   * - Điều kiện: size.x <= _maxSize / 3
   * 
   * 🎯 MỤC ĐÍCH:
   * - Người chơi phải phá hủy HOÀN TOÀN asteroid3 (cả mảnh nhỏ)
   * - Tránh spam coin khi asteroid lớn tách ra
   * - Tạo cảm giác thành tựu khi phá hủy hết mảnh cuối
   */
  void _spawnCoin() {
    final Pickup coin = Pickup(
      position: position.clone(),
      pickupType: PickupType.coin,
    );
    game.add(coin);
  }

  // ===============================================
  // 🎨 VISUAL EFFECTS
  // ===============================================

  /**
   * _flashWhite() - Hiệu ứng flash trắng khi bị damage
   * 
   * Thuộc tính hiệu ứng:
   * - Màu: Trắng thuần (RGB 255,255,255)
   * - Thời gian: 0.1s flash
   * - Xen kẽ: Flash sang trắng rồi trở lại bình thường
   * - Đường cong: Chuyển tiếp mượt easeInOut
   * 
   * Phản hồi visual cho player biết laser hit thành công
   */
  void _flashWhite() {
    final ColorEffect flashEffect = ColorEffect(
      const Color.fromRGBO(255, 255, 255, 1.0), // Màu trắng tinh khiết
      EffectController(
        duration: 0.1, // Nhấp nháy nhanh (100ms)
        alternate: true, // Nhấp nháy trắng rồi về lại
        curve: Curves.easeInOut, // Chuyển tiếp mượt mà
      ),
    );
    add(flashEffect); // Áp dụng hiệu ứng cho asteroid
  }

  /**
   * _applyKnockback() - Đẩy asteroid lùi khi bị hit
   * 
   * Chuỗi knockback:
   * 1. Kiểm tra đã bị knockback chưa (ngăn chồng chất)
   * 2. Đặt flag knockback và dừng velocity hiện tại
   * 3. Áp dụng chuyển động đẩy lên (-20 pixels)
   * 4. Khôi phục velocity gốc khi hoàn thành
   * 
   * Cung cấp phản hồi vật lý hài lòng cho laser hits
   */
  void _applyKnockback() {
    if (_isKnockedback) return; // Ngăn nhiều knockback đồng thời

    // ===== KNOCKBACK STATE =====
    _isKnockedback = true; // Đặt flag knockback
    _velocity.setZero(); // Dừng chuyển động hiện tại

    // ===== KNOCKBACK EFFECT =====
    final MoveByEffect knockbackEffect = MoveByEffect(
      Vector2(0, -20), // Đẩy lên trên 20 pixels
      EffectController(
        duration: 0.1, // Đẩy nhanh (100ms)
      ),
      onComplete: _restoreVelocity, // Khôi phục chuyển động khi xong
    );
    add(knockbackEffect); // Áp dụng hiệu ứng
  }

  /**
   * _restoreVelocity() - Khôi phục chuyển động bình thường sau knockback
   * 
   * Chuỗi phục hồi:
   * 1. Khôi phục velocity gốc
   * 2. Xóa flag knockback
   * 
   * Được gọi bởi: knockbackEffect.onComplete callback
   */
  void _restoreVelocity() {
    _velocity.setFrom(_originalVelocity); // Khôi phục chuyển động ban đầu
    _isKnockedback = false; // Xóa cờ knockback
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
