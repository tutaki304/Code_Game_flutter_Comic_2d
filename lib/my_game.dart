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
  late TextComponent _laserLevelDisplay; // Component hiển thị laser level

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
    // audioManager.playMusic(); // Bắt đầu phát nhạc nền - tạm disable để tránh crash

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
    _createLaserLevelDisplay(); // Tạo hiển thị laser level
    _showDeviceInfo(); // Hiển thị thông tin thiết bị (debug)
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
    // 📱 Adaptive UI: Tự động điều chỉnh theo thiết bị
    final isPhone =
        size.y > size.x; // Portrait = Phone, Landscape = Desktop/Tablet

    // Size và margin tùy theo thiết bị
    final joystickSizePercent =
        isPhone ? 0.28 : 0.12; // 🎮 Tăng từ 0.24 -> 0.28 cho màn hình nhỏ
    final marginPercent = isPhone ? 0.08 : 0.04; // Phone cần margin lớn hơn

    final joystickSize = Vector2.all(size.x * joystickSizePercent);
    final knobSize = joystickSize * 0.6; // Knob chiếm 60% background
    final margin = size.x * marginPercent;

    joystick = JoystickComponent(
      knob: SpriteComponent(
        sprite: await loadSprite('joystick_knob.png'),
        size: knobSize,
      ),
      background: SpriteComponent(
        sprite: await loadSprite('joystick_background.png'),
        size: joystickSize,
      ),
      anchor: Anchor.bottomLeft,
      position: Vector2(margin, size.y - margin),
      priority: 10,
    );
    add(joystick);
  }

  void _createShootButton() {
    // 📱 Adaptive shoot button
    final isPhone = size.y > size.x;
    final marginPercent = isPhone ? 0.08 : 0.04; // Phone cần margin lớn hơn
    final margin = size.x * marginPercent;

    _shootButton = ShootButton()
      ..anchor = Anchor.bottomRight
      ..position = Vector2(size.x - margin, size.y - margin)
      ..priority = 10;

    // 🎮 Phone cần button lớn hơn 30% để dễ chạm (tăng từ 1.2 -> 1.3)
    if (isPhone) {
      _shootButton.scale = Vector2.all(1.3);
    }

    add(_shootButton);
  }

  void _createAsteroidSpawner() {
    _asteroidSpawner = SpawnComponent.periodRange(
      factory: (index) => Asteroid(position: _generateSpawnPosition()),
      minPeriod:
          1.5, // 🎮 Màn hình nhỏ: Tăng từ 1.2 -> 1.5 để giảm density thiên thạch
      maxPeriod: 2.2, // 🎮 Màn hình nhỏ: Tăng từ 1.8 -> 2.2 để dễ chơi hơn
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
      minPeriod:
          2.5, // 🎮 Màn hình nhỏ: Giảm từ 3.0 -> 2.5 để pickup xuất hiện nhanh hơn
      maxPeriod: 5.0, // 🎮 Màn hình nhỏ: Giảm từ 6.0 -> 5.0 để dễ lấy power-up
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

    // 📱 Adaptive score display
    final isPhone = size.y > size.x;

    // Điều chỉnh margin và font cho từng thiết bị
    final topMarginPercent = isPhone ? 0.08 : 0.04; // Phone tránh notch/camera
    final fontSizePercent = isPhone ? 0.10 : 0.06; // Phone cần font lớn hơn

    final topMargin = size.y * topMarginPercent;
    final fontSize = size.x * fontSizePercent;

    _scoreDisplay = TextComponent(
      text: '0',
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, topMargin),
      priority: 10,
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black,
              offset: Offset(fontSize * 0.05,
                  fontSize * 0.05), // Bóng tỷ lệ với kích thước font
              blurRadius: fontSize * 0.05,
            ),
          ],
        ),
      ),
    );

    add(_scoreDisplay);
  }

  void _createLaserLevelDisplay() {
    // 📱 Adaptive laser level display
    final isPhone = size.y > size.x;

    // Điều chỉnh size và position cho từng thiết bị
    final topMarginPercent = isPhone ? 0.08 : 0.04; // Đồng bộ với score
    final fontSizePercent = isPhone ? 0.06 : 0.04; // Phone cần font lớn hơn
    final sideMarginPercent = isPhone ? 0.08 : 0.04; // Phone cần margin lớn hơn

    final topMargin = size.y * topMarginPercent;
    final fontSize = size.x * fontSizePercent;
    final sideMargin = size.x * sideMarginPercent;

    // 🎯 Position thông minh: Phone để bên trái, Desktop để bên phải
    final anchor = isPhone ? Anchor.topLeft : Anchor.topRight;
    final positionX = isPhone ? sideMargin : (size.x - sideMargin);

    _laserLevelDisplay = TextComponent(
      text: 'LASER LV.1',
      anchor: anchor,
      position: Vector2(positionX, topMargin),
      priority: 10,
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.cyan,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black,
              offset: Offset(fontSize * 0.05, fontSize * 0.05),
              blurRadius: fontSize * 0.05,
            ),
          ],
        ),
      ),
    );

    add(_laserLevelDisplay);
  }

  void _showDeviceInfo() {
    // 🔍 Debug: Hiển thị thông tin thiết bị và UI layout
    final isPhone = size.y > size.x;
    String deviceType;
    String layoutInfo;

    if (isPhone) {
      deviceType = '📱 PHONE UI';
      layoutInfo = 'Portrait Mode - Laser Level: Top Left';
    } else {
      if (size.x < 1200) {
        deviceType = '📚 TABLET UI';
      } else {
        deviceType = '🖥️ DESKTOP UI';
      }
      layoutInfo = 'Landscape Mode - Laser Level: Top Right';
    }

    final infoText = TextComponent(
      text:
          '$deviceType\nSize: ${size.x.toInt()}x${size.y.toInt()}\n$layoutInfo',
      anchor: Anchor.bottomCenter,
      position: Vector2(size.x / 2, size.y - 15),
      priority: 15,
      textRenderer: TextPaint(
        style: TextStyle(
          color: Colors.yellow.withOpacity(0.8),
          fontSize: isPhone ? 14 : 12,
          fontWeight: FontWeight.normal,
        ),
      ),
    );

    add(infoText);

    // Tự động ẩn sau 4 giây
    Timer deviceInfoTimer = Timer(4.0, onTick: () {
      remove(infoText);
    });
    deviceInfoTimer.start();
  }

  void updateLaserLevelDisplay(int level) {
    _laserLevelDisplay.text = 'LASER LV.$level';

    // Hiệu ứng nhấp nháy khi nâng cấp
    final glowEffect = ScaleEffect.to(
      Vector2.all(1.3),
      EffectController(
        duration: 0.15,
        alternate: true,
        curve: Curves.easeInOut,
      ),
    );
    _laserLevelDisplay.add(glowEffect);
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
    // Xóa tất cả asteroids và pickups hiện tại trong game
    children.whereType<PositionComponent>().forEach((component) {
      if (component is Asteroid || component is Pickup) {
        remove(component);
      }
    });

    // Reset spawners cho asteroids và pickups
    _asteroidSpawner.timer.start();
    _pickupSpawner.timer.start();

    // Reset điểm về 0
    _score = 0;
    _scoreDisplay.text = '0';

    // Reset hiển thị level laser về level 1
    _laserLevelDisplay.text = 'LASER LV.1';

    // Tạo sprite player mới
    _createPlayer();

    resumeEngine();
  }

  void quitGame() {
    // Xóa mọi thứ trong game trừ stars
    children.whereType<PositionComponent>().forEach((component) {
      if (component is! Star) {
        remove(component);
      }
    });

    remove(_asteroidSpawner);
    remove(_pickupSpawner);

    // Hiển thị title overlay
    overlays.add('Title');

    resumeEngine();
  }
}
