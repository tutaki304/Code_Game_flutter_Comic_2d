// Thư viện Dart cơ bản
import 'dart:async'; // Hỗ trợ bất đồng bộ (async/await)
import 'dart:math'; // Các hàm toán học (Random, sin, cos...)

// Import các component game tự tạo
import 'package:cosmic_havoc/components/asteroid.dart'; // Thiên thạch trong game
import 'package:cosmic_havoc/components/audio_manager.dart'; // Quản lý âm thanh với flutter_soloud
import 'package:cosmic_havoc/components/pickup.dart'; // Vật phẩm thu thập
import 'package:cosmic_havoc/components/player.dart'; // Tàu người chơi
import 'package:cosmic_havoc/components/shoot_button.dart'; // Nút bắn
import 'package:cosmic_havoc/components/star.dart'; // Sao trên background

// Flame game engine components
import 'package:flame/components.dart'; // Các component cơ bản của Flame
import 'package:flame/effects.dart'; // Hiệu ứng (scale, rotate, move...)
import 'package:flame/events.dart'; // Xử lý sự kiện (tap, drag...)
import 'package:flame/flame.dart'; // Core Flame functionality
import 'package:flame/game.dart'; // Base game class
import 'package:flutter/material.dart'; // Flutter UI components

// Class chính của game, kế thừa từ FlameGame
class MyGame extends FlameGame
    with
        HasKeyboardHandlerComponents, // Mixin để xử lý phím bàn phím
        HasCollisionDetection {
  // Mixin để phát hiện va chạm giữa objects

  // Các component chính của game
  late Player player; // Tàu người chơi (late = khởi tạo sau)
  late JoystickComponent joystick; // Joystick điều khiển ảo
  late SpawnComponent _asteroidSpawner; // Bộ sinh thiên thạch tự động
  late SpawnComponent _pickupSpawner; // Bộ sinh vật phẩm tự động
  final Random _random = Random(); // Đối tượng tạo số ngẫu nhiên
  late ShootButton _shootButton; // Nút bắn

  // Hệ thống điểm số
  int _score = 0; // Điểm hiện tại
  late TextComponent _scoreDisplay; // Component hiển thị điểm

  // Hệ thống chọn màu tàu
  final List<String> playerColors = [
    'blue',
    'red',
    'green',
    'purple'
  ]; // Các màu có sẵn
  int playerColorIndex = 0; // Chỉ số màu hiện tại được chọn

  // Quản lý âm thanh
  late final AudioManager
      audioManager; // Component xử lý music và sound effects

  // Hàm onLoad được gọi khi game khởi tạo lần đầu
  @override
  FutureOr<void> onLoad() async {
    // Thiết lập màn hình full screen (ẩn status bar)
    await Flame.device.fullScreen();
    // Khóa màn hình ở chế độ dọc (portrait)
    await Flame.device.setPortrait();

    // Khởi tạo và thêm audio manager vào game
    audioManager = AudioManager(); // Tạo đối tượng quản lý âm thanh
    await add(audioManager); // Thêm vào game world
    audioManager.playMusic(); // Bắt đầu phát nhạc nền

    // Tạo các ngôi sao làm background
    _createStars();

    return super.onLoad(); // Gọi onLoad của class cha
  }

  // Hàm bắt đầu game thực sự (được gọi từ Title Overlay)
  void startGame() async {
    await _createJoystick(); // Tạo joystick điều khiển
    await _createPlayer(); // Tạo tàu người chơi
    _createShootButton(); // Tạo nút bắn
    _createAsteroidSpawner(); // Tạo bộ sinh thiên thạch
    _createPickupSpawner(); // Tạo bộ sinh vật phẩm
    _createScoreDisplay(); // Tạo hiển thị điểm số
  }

  // Hàm tạo tàu người chơi
  Future<void> _createPlayer() async {
    player = Player() // Tạo đối tượng Player
      ..anchor = Anchor.center // Đặt điểm neo ở giữa sprite
      ..position =
          Vector2(size.x / 2, size.y * 0.8); // Vị trí: giữa màn hình, gần đáy
    add(player); // Thêm player vào game world
  }

  Future<void> _createJoystick() async {
    joystick = JoystickComponent(
      knob: SpriteComponent(
        sprite: await loadSprite('joystick_knob.png'),
        size: Vector2.all(50),
      ),
      background: SpriteComponent(
        sprite: await loadSprite('joystick_background.png'),
        size: Vector2.all(100),
      ),
      anchor: Anchor.bottomLeft,
      position: Vector2(20, size.y - 20),
      priority: 10,
    );
    add(joystick);
  }

  void _createShootButton() {
    _shootButton = ShootButton()
      ..anchor = Anchor.bottomRight
      ..position = Vector2(size.x - 20, size.y - 20)
      ..priority = 10;
    add(_shootButton);
  }

  void _createAsteroidSpawner() {
    _asteroidSpawner = SpawnComponent.periodRange(
      factory: (index) => Asteroid(position: _generateSpawnPosition()),
      minPeriod: 0.7,
      maxPeriod: 1.2,
      selfPositioning: true,
    );
    add(_asteroidSpawner);
  }

  void _createPickupSpawner() {
    _pickupSpawner = SpawnComponent.periodRange(
      factory: (index) => Pickup(
        position: _generateSpawnPosition(),
        pickupType:
            PickupType.values[_random.nextInt(PickupType.values.length)],
      ),
      minPeriod: 5.0,
      maxPeriod: 10.0,
      selfPositioning: true,
    );
    add(_pickupSpawner);
  }

  Vector2 _generateSpawnPosition() {
    return Vector2(
      10 + _random.nextDouble() * (size.x - 10 * 2),
      -100,
    );
  }

  void _createScoreDisplay() {
    _score = 0;

    _scoreDisplay = TextComponent(
      text: '0',
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, 20),
      priority: 10,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 48,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black,
              offset: Offset(2, 2),
              blurRadius: 2,
            ),
          ],
        ),
      ),
    );

    add(_scoreDisplay);
  }

  void incrementScore(int amount) {
    _score += amount;
    _scoreDisplay.text = _score.toString();

    final ScaleEffect popEffect = ScaleEffect.to(
      Vector2.all(1.2),
      EffectController(
        duration: 0.05,
        alternate: true,
        curve: Curves.easeInOut,
      ),
    );

    _scoreDisplay.add(popEffect);
  }

  void _createStars() {
    for (int i = 0; i < 50; i++) {
      add(Star()..priority = -10);
    }
  }

  void playerDied() {
    overlays.add('GameOver');
    pauseEngine();
  }

  void restartGame() {
    // remove any asteroids and pickups that are currently in the game
    children.whereType<PositionComponent>().forEach((component) {
      if (component is Asteroid || component is Pickup) {
        remove(component);
      }
    });

    // reset the asteroid and pickup spawners
    _asteroidSpawner.timer.start();
    _pickupSpawner.timer.start();

    // reset the score to 0
    _score = 0;
    _scoreDisplay.text = '0';

    // create a new player sprite
    _createPlayer();

    resumeEngine();
  }

  void quitGame() {
    // remove everything from the game except the stars
    children.whereType<PositionComponent>().forEach((component) {
      if (component is! Star) {
        remove(component);
      }
    });

    remove(_asteroidSpawner);
    remove(_pickupSpawner);

    // show the title overlay
    overlays.add('Title');

    resumeEngine();
  }
}
