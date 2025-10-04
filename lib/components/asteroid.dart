import 'dart:async'; // Async/await support
import 'dart:math'; // Toán học (Random, etc.)

import 'package:cosmic_havoc/components/explosion.dart'; // Hiệu ứng nổ khi asteroid bị phá hủy
import 'package:cosmic_havoc/my_game.dart'; // Game chính để truy cập game state
import 'package:flame/collisions.dart'; // Hệ thống va chạm
import 'package:flame/components.dart'; // Flame components cơ bản
import 'package:flame/effects.dart'; // Hiệu ứng animation
import 'package:flutter/widgets.dart'; // Flutter widgets

// Class Asteroid - thiên thạch trong game
class Asteroid extends SpriteComponent // Kế thừa từ component có sprite
    with
        HasGameReference<MyGame> {
  // Mixin để truy cập game instance

  final Random _random = Random(); // Tạo số ngẫu nhiên
  static const double _maxSize = 120; // Kích thước tối đa của asteroid

  // Chuyển động
  late Vector2 _velocity; // Vận tốc hiện tại (pixel/giây)
  final Vector2 _originalVelocity =
      Vector2.zero(); // Vận tốc gốc (để reset sau knockback)
  late double _spinSpeed; // Tốc độ quay (radian/giây)

  // Sức khỏe
  final double _maxHealth = 3; // Máu tối đa
  late double _health; // Máu hiện tại

  // Trạng thái
  bool _isKnockedback = false; // Có đang bị đẩy lùi không?

  Asteroid({required super.position, double size = _maxSize})
      : super(
          size: Vector2.all(size),
          anchor: Anchor.center,
          priority: -1,
        ) {
    _velocity = _generateVelocity();
    _originalVelocity.setFrom(_velocity);
    _spinSpeed = _random.nextDouble() * 1.5 - 0.75;
    _health = size / _maxSize * _maxHealth;

    add(CircleHitbox(collisionType: CollisionType.passive));
  }

  @override
  FutureOr<void> onLoad() async {
    final int imageNum = _random.nextInt(3) + 1;
    sprite = await game.loadSprite('asteroid$imageNum.png');

    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);

    position += _velocity * dt;

    _handleScreenBounds();

    angle += _spinSpeed * dt;
  }

  Vector2 _generateVelocity() {
    final double forceFactor = _maxSize / size.x;

    return Vector2(
          _random.nextDouble() * 120 - 60,
          100 + _random.nextDouble() * 50,
        ) *
        forceFactor;
  }

  void _handleScreenBounds() {
    // remove the asteroid from the game if it goes below the bottom
    if (position.y > game.size.y + size.y / 2) {
      removeFromParent();
    }

    // perform wraparound if the asteroid goes over the left or right edge
    final double screenWidth = game.size.x;
    if (position.x < -size.x / 2) {
      position.x = screenWidth + size.x / 2;
    } else if (position.x > screenWidth + size.x / 2) {
      position.x = -size.x / 2;
    }
  }

  void takeDamage() {
    game.audioManager.playSound('hit');

    _health--;

    if (_health <= 0) {
      game.incrementScore(2);
      removeFromParent();
      _createExplosion();
      _splitAsteroid();
    } else {
      game.incrementScore(1);
      _flashWhite();
      _applyKnockback();
    }
  }

  void _flashWhite() {
    final ColorEffect flashEffect = ColorEffect(
      const Color.fromRGBO(255, 255, 255, 1.0),
      EffectController(
        duration: 0.1,
        alternate: true,
        curve: Curves.easeInOut,
      ),
    );
    add(flashEffect);
  }

  void _applyKnockback() {
    if (_isKnockedback) return;

    _isKnockedback = true;

    _velocity.setZero();

    final MoveByEffect knockbackEffect = MoveByEffect(
      Vector2(0, -20),
      EffectController(
        duration: 0.1,
      ),
      onComplete: _restoreVelocity,
    );
    add(knockbackEffect);
  }

  void _restoreVelocity() {
    _velocity.setFrom(_originalVelocity);

    _isKnockedback = false;
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
