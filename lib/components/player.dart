// Thư viện Dart cơ bản
import 'dart:async'; // Async/await cho hàm bất đồng bộ
import 'dart:math'; // Hàm toán học (Random, sin, cos...)
import 'dart:ui'; // Các thao tác UI cơ bản

// Import các component game khác
import 'package:cosmic_havoc/components/asteroid.dart'; // Thiên thạch (để xử lý va chạm)
import 'package:cosmic_havoc/components/bomb.dart'; // Bom (vũ khí của player)
import 'package:cosmic_havoc/components/explosion.dart'; // Hiệu ứng nổ
import 'package:cosmic_havoc/components/laser.dart'; // Laser (vũ khí chính)
import 'package:cosmic_havoc/components/pickup.dart'; // Vật phẩm thu thập
import 'package:cosmic_havoc/components/shield.dart'; // Khiên bảo vệ
import 'package:cosmic_havoc/my_game.dart'; // Game chính (để truy cập game state)

// Flame components
import 'package:flame/collisions.dart'; // Hệ thống va chạm
import 'package:flame/components.dart'; // Các component cơ bản
import 'package:flame/effects.dart'; // Hiệu ứng animation
import 'package:flutter/services.dart'; // Xử lý input từ keyboard

// Class Player - tàu người chơi
class Player
    extends SpriteAnimationComponent // Kế thừa từ component có animation
    with
        HasGameReference<MyGame>, // Mixin để truy cập game instance
        KeyboardHandler, // Mixin xử lý phím bàn phím
        CollisionCallbacks {
  // Mixin xử lý va chạm

  // Trạng thái bắn súng
  bool _isShooting = false; // Có đang bắn không?
  final double _fireCooldown = 0.2; // Thời gian chờ giữa các phát bắn (giây)
  double _elapsedFireTime = 0.0; // Thời gian đã trôi qua từ lần bắn cuối

  // Di chuyển bằng keyboard
  final Vector2 _keyboardMovement = Vector2.zero(); // Vector di chuyển (x,y)

  // Trạng thái game
  bool _isDestroyed = false; // Tàu đã bị phá hủy chưa?
  final Random _random = Random(); // Tạo số ngẫu nhiên cho hiệu ứng

  // Timer cho các hiệu ứng
  late Timer _explosionTimer; // Timer tạo nổ khi tàu bị phá hủy

  // 🚀 HỆ THỐNG LASER NÂNG CẤP
  int _laserLevel = 1; // Level laser hiện tại (1-10)
  static const int maxLaserLevel = 10; // Level tối đa
  static const double laserSpacing = 20.0; // Khoảng cách giữa laser song song

  // Hệ thống bảo vệ
  Shield? activeShield; // Khiên hiện tại (null = không có khiên)

  // Màu sắc tàu
  late String _color; // Màu tàu được chọn ('blue', 'red', etc.)

  Player() {
    _explosionTimer = Timer(
      0.1,
      onTick: _createRandomExplosion,
      repeat: true,
      autoStart: false,
    );
  }

  @override
  FutureOr<void> onLoad() async {
    _color = game.playerColors[game.playerColorIndex];

    animation = await _loadAnimation();

    size *= 0.3;

    add(RectangleHitbox.relative(
      Vector2(0.6, 0.9),
      parentSize: size,
      anchor: Anchor.center,
    ));

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_isDestroyed) {
      _explosionTimer.update(dt);
      return;
    }

    // Laser level giờ là permanent, không cần timer

    // Kết hợp input từ joystick và bàn phím
    //tốc độ
    final Vector2 movement = game.joystick.relativeDelta + _keyboardMovement;
    position += movement.normalized() * 250 * dt;

    _handleScreenBounds();

    // Xử lý logic bắn súng
    _elapsedFireTime += dt;
    if (_isShooting && _elapsedFireTime >= _fireCooldown) {
      _fireLaser();
      _elapsedFireTime = 0.0;
    }
  }

  Future<SpriteAnimation> _loadAnimation() async {
    return SpriteAnimation.spriteList(
      [
        await game.loadSprite('player_${_color}_on0.png'),
        await game.loadSprite('player_${_color}_on1.png'),
      ],
      stepTime: 0.1,
      loop: true,
    );
  }

  void _handleScreenBounds() {
    final double screenWidth = game.size.x;
    final double screenHeight = game.size.y;

    // 🔒 KHÓA TÀU TRONG KHUNG HÌNH - KHÔNG CHO ĐI RA NGOÀI

    // Giới hạn vị trí Y (trên - dưới)
    position.y = clampDouble(
      position.y,
      size.y / 2, // Không cho đi qua mép trên
      screenHeight - size.y / 2, // Không cho đi qua mép dưới
    );

    // Giới hạn vị trí X (trái - phải) - KHÓA THAY VÌ WRAPAROUND
    position.x = clampDouble(
      position.x,
      size.x / 2, // Không cho đi qua mép trái
      screenWidth - size.x / 2, // Không cho đi qua mép phải
    );
  }

  void startShooting() {
    _isShooting = true;
  }

  void stopShooting() {
    _isShooting = false;
  }

  void _fireLaser() {
    // 🎵 Tối ưu: Chỉ phát âm thanh khi bắt đầu bắn để tránh spam
    if (_elapsedFireTime == 0.0) {
      game.audioManager.playSound('laser');
    }

    // 🚀 Bắn laser theo level hiện tại
    _fireLasersByLevel();
  }

  // 🎯 Bắn laser theo level - TỐI ƯU HIỆU NĂNG
  void _fireLasersByLevel() {
    final Vector2 basePosition = position.clone() + Vector2(0, -size.y / 2);

    if (_laserLevel == 1) {
      // Level 1: 1 tia thẳng
      _createOptimizedLaser(basePosition, 0.0);
    } else if (_laserLevel == 2) {
      // Level 2: 2 tia song song
      _createOptimizedLaser(basePosition + Vector2(-laserSpacing / 2, 0), 0.0);
      _createOptimizedLaser(basePosition + Vector2(laserSpacing / 2, 0), 0.0);
    } else {
      // Level 3-10: Tỏa ra với góc đều
      final int numLasers = _laserLevel.clamp(3, maxLaserLevel);
      final double totalSpread = 60.0 * degrees2Radians; // 60 độ tổng
      final double angleStep = totalSpread / (numLasers - 1);

      for (int i = 0; i < numLasers; i++) {
        final double angle = -totalSpread / 2 + i * angleStep;
        _createOptimizedLaser(basePosition, angle);
      }
    }
  }

  // ⚡ Tối ưu: Tạo laser với ít object allocation
  void _createOptimizedLaser(Vector2 pos, double angle) {
    game.add(Laser(
      position: pos,
      angle: angle,
    ));
  }

  // 🆙 Nâng cấp laser level
  void _upgradeLaserLevel() {
    if (_laserLevel < maxLaserLevel) {
      _laserLevel++;
      print('🚀 Laser upgraded to Level $_laserLevel!');

      // ✅ CẬP NHẬT HIỂN THỊ LASER LEVEL TRÊN UI
      game.updateLaserLevelDisplay(_laserLevel);

      // Hiệu ứng visual cho upgrade (optional)
      _showUpgradeEffect();
    } else {
      print('⭐ Laser đã đạt level tối đa!');
      // Thay vì nâng cấp, có thể thêm bonus khác (damage, speed, etc.)
    }
  }

  // ✨ Hiệu ứng upgrade laser
  void _showUpgradeEffect() {
    // Sử dụng hiệu ứng scale thay vì đổi màu để tránh làm tàu chuyển sang màu khác
    add(ScaleEffect.by(
      Vector2.all(1.2), // Tăng kích thước 20%
      EffectController(
        duration: 0.15,
        reverseDuration: 0.15, // Quay về kích thước ban đầu
      ),
    ));
  }

  // 📊 Getter cho laser level (để UI hiển thị)
  int get laserLevel => _laserLevel;

  void _handleDestruction() async {
    animation = SpriteAnimation.spriteList(
      [
        await game.loadSprite('player_${_color}_off.png'),
      ],
      stepTime: double.infinity,
    );

    add(ColorEffect(
      const Color.fromRGBO(255, 255, 255, 1.0),
      EffectController(duration: 0.0),
    ));

    add(OpacityEffect.fadeOut(
      EffectController(duration: 3.0),
      onComplete: () => _explosionTimer.stop(),
    ));

    add(MoveEffect.by(
      Vector2(0, 200),
      EffectController(duration: 3.0),
    ));

    add(RemoveEffect(
      delay: 4.0,
      onComplete: game.playerDied,
    ));

    _isDestroyed = true;

    _explosionTimer.start();
  }

  void _createRandomExplosion() {
    final Vector2 explosionPosition = Vector2(
      position.x - size.x / 2 + _random.nextDouble() * size.x,
      position.y - size.y / 2 + _random.nextDouble() * size.y,
    );

    final ExplosionType explosionType =
        _random.nextBool() ? ExplosionType.smoke : ExplosionType.fire;

    final Explosion explosion = Explosion(
      position: explosionPosition,
      explosionSize: size.x * 0.7,
      explosionType: explosionType,
    );

    game.add(explosion);
  }

  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other);

    if (_isDestroyed) return;

    if (other is Asteroid) {
      if (activeShield == null) _handleDestruction();
    } else if (other is Pickup) {
      // Phát âm thanh khác nhau cho coin và power-ups
      if (other.pickupType == PickupType.coin) {
        game.audioManager.playSound('dropcoin'); // Âm thanh riêng cho coin
      } else {
        game.audioManager.playSound('collect'); // Âm thanh cho power-ups
      }

      other.removeFromParent();

      // Chỉ tăng điểm khi thu coin, không tăng cho các pickup khác
      if (other.pickupType == PickupType.coin) {
        game.incrementScore(10); // Coin cho 10 điểm
      }

      switch (other.pickupType) {
        case PickupType.laser:
          // 🚀 Nâng cấp laser level (không giảm tốc độ bắn)
          _upgradeLaserLevel();
          break;
        case PickupType.bomb:
          game.add(Bomb(position: position.clone()));
          break;
        case PickupType.shield:
          if (activeShield != null) {
            remove(activeShield!);
          }
          activeShield = Shield();
          add(activeShield!);
          break;
        case PickupType.coin:
          // 💰 Thu thập coin - đã tăng điểm và phát âm thanh ở trên
          break;
      }
    }
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // Reset vector di chuyển
    _keyboardMovement.setZero();

    // ===== DI CHUYỂN NGANG (Trái/Phải) =====
    // Mũi tên trái hoặc phím A
    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft) ||
        keysPressed.contains(LogicalKeyboardKey.keyA)) {
      _keyboardMovement.x -= 1;
    }

    // Mũi tên phải hoặc phím D
    if (keysPressed.contains(LogicalKeyboardKey.arrowRight) ||
        keysPressed.contains(LogicalKeyboardKey.keyD)) {
      _keyboardMovement.x += 1;
    }

    // ===== DI CHUYỂN DỌC (Lên/Xuống) =====
    // Mũi tên lên hoặc phím W
    if (keysPressed.contains(LogicalKeyboardKey.arrowUp) ||
        keysPressed.contains(LogicalKeyboardKey.keyW)) {
      _keyboardMovement.y -= 1;
    }

    // Mũi tên xuống hoặc phím S
    if (keysPressed.contains(LogicalKeyboardKey.arrowDown) ||
        keysPressed.contains(LogicalKeyboardKey.keyS)) {
      _keyboardMovement.y += 1;
    }

    // ===== BẮN SÚNG =====
    // Phím Space để bắn (với cooldown tự động trong update())
    if (keysPressed.contains(LogicalKeyboardKey.space)) {
      _isShooting =
          true; // Set trạng thái bắn, logic cooldown xử lý trong update()
    } else {
      _isShooting = false; // Ngừng bắn khi thả phím
    }

    return true; // Đã xử lý input
  }
}
