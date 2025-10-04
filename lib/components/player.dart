// Thư viện Dart cơ bản
import 'dart:async'; // Async/await cho hàm bất đồng bộ
import 'dart:math'; // Hàm toán học (Random, sin, cos...)
import 'dart:ui'; // Primitive UI operations

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
  late Timer _laserPowerupTimer; // Timer đếm thời gian laser power-up

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

    _laserPowerupTimer = Timer(
      10.0,
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

    if (_laserPowerupTimer.isRunning()) {
      _laserPowerupTimer.update(dt);
    }

    // combine the joystick input with the keyboard movement
    final Vector2 movement = game.joystick.relativeDelta + _keyboardMovement;
    position += movement.normalized() * 200 * dt;

    _handleScreenBounds();

    // perform the shooting logic
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

    // prevent the player from going off the top or bottom edges
    position.y = clampDouble(
      position.y,
      size.y / 2,
      screenHeight - size.y / 2,
    );

    // perform wraparound if the player goes over the left or right edge
    if (position.x < 0) {
      position.x = screenWidth;
    } else if (position.x > screenWidth) {
      position.x = 0;
    }
  }

  void startShooting() {
    _isShooting = true;
  }

  void stopShooting() {
    _isShooting = false;
  }

  void _fireLaser() {
    game.audioManager.playSound('laser');

    game.add(
      Laser(position: position.clone() + Vector2(0, -size.y / 2)),
    );

    if (_laserPowerupTimer.isRunning()) {
      game.add(
        Laser(
          position: position.clone() + Vector2(0, -size.y / 2),
          angle: 15 * degrees2Radians,
        ),
      );
      game.add(
        Laser(
          position: position.clone() + Vector2(0, -size.y / 2),
          angle: -15 * degrees2Radians,
        ),
      );
    }
  }

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
      game.audioManager.playSound('collect');

      other.removeFromParent();
      game.incrementScore(1);

      switch (other.pickupType) {
        case PickupType.laser:
          _laserPowerupTimer.start();
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
      }
    }
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    // Reset movement vector
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
