# Báo cáo ngắn gọn dự án: Cosmic Havoc

## Tổng quan
- **Thể loại:** Arcade bắn súng không gian 2D, lấy cảm hứng từ Asteroids cổ điển nhưng bổ sung hệ thống nâng cấp, vật phẩm, hiệu ứng hiện đại.
- **Mục tiêu gameplay:** Người chơi điều khiển tàu vũ trụ né tránh và bắn phá thiên thạch, thu thập vật phẩm để nâng cấp vũ khí, bảo vệ và ghi điểm cao nhất có thể.
- **Đối tượng:** Game tối ưu cho mobile (Android/iOS), chơi tốt trên desktop/web nhờ kiến trúc responsive.
- **Kiến trúc:** Component-based (ECS) với Flame, tách biệt rõ UI, logic, input, hiệu ứng, overlay.
- **Điểm mạnh:**
  - Điều khiển mượt mà (joystick ảo, nút bắn lớn, responsive)
  - Hệ thống nâng cấp đa dạng: laser, shield, bomb, coin
  - Hiệu ứng hình ảnh và âm thanh sống động
  - Tối ưu cho màn hình nhỏ (360x804), dễ chơi trên mọi thiết bị
  - Dễ mở rộng: thêm boss, nhiệm vụ, chế độ chơi mới

## Công nghệ chính
- **Flutter 3.x, Dart 3.x:**
  - Framework UI đa nền tảng, build 1 code chạy Android/iOS/Web/Desktop
  - Hot reload, dễ debug, cộng đồng lớn
- **Flame Engine:**
  - Game engine cho Flutter, hỗ trợ component, collision, animation, spawn, hiệu ứng
  - ECS (Entity Component System): tách logic, dễ bảo trì
  - SpawnComponent: sinh đối tượng theo thời gian, tối ưu performance
  - Collision detection: va chạm giữa player, asteroid, laser, pickup, shield
  - Effects: ScaleEffect, ColorEffect, MoveEffect cho animation mượt
- **flutter_soloud:**
  - Thư viện âm thanh, phát nhạc nền và sound effect (laser, nổ, nhặt vật phẩm)
- **Kiến trúc Overlay:**
  - Tách màn hình chính, game over, title thành các overlay riêng, dễ quản lý UI
- **Ưu điểm kiến trúc:**
  - Tách biệt UI/game logic/hiệu ứng
  - Dễ mở rộng, thêm tính năng mới mà không ảnh hưởng code cũ
  - Tối ưu cho mobile: tự động scale UI, điều chỉnh tốc độ, spawn rate

## Cấu trúc thư mục lib/
```
lib/
  main.dart              # Entry point, GameWidget + overlays
  my_game.dart           # Core game (scene setup, spawners, HUD, input)
  components/
    player.dart          # Tàu người chơi, di chuyển, bắn laser, nâng cấp
    laser.dart           # Đạn laser của player
    asteroid.dart        # Thiên thạch: di chuyển, va chạm, tách mảnh
    pickup.dart          # Vật phẩm: bomb/laser/shield/coin
    bomb.dart            # Bom quét màn hình (AOE)
    shield.dart          # Khiên bảo vệ tạm thời
    explosion.dart       # Hiệu ứng nổ
    star.dart            # Sao nền (background)
    shoot_button.dart    # Nút bắn trên mobile (touch)
    audio_manager.dart   # Quản lý âm thanh
  overlays/
    title_overlay.dart   # Màn hình tiêu đề (Start)
    game_over_overlay.dart # Màn hình Game Over (hiển thị điểm)
```

## Gameplay chính
- Di chuyển: Joystick ảo (góc trái dưới). Bàn phím (desktop) vẫn hỗ trợ.
- Bắn: Nút bắn (góc phải dưới) – giữ để bắn liên tục. Desktop dùng Spacebar.
- Thiên thạch: Rơi từ trên xuống, có xoay; va chạm player → Game Over.
- Điểm số: +1 mỗi hit; bonus khi phá huỷ. Hiển thị phía trên.
- Vật phẩm (pickup):
  - Bomb: Kích hoạt bom quét sạch thiên thạch trên màn hình
  - Laser: Tăng cấp súng (tối đa 10, bắn nhiều tia rộng)
  - Shield: Khiên bảo vệ tạm thời (chặn va chạm)
  - Coin: +10 điểm (rơi từ asteroid3)

## Điều khiển & HUD
- Joystick + ShootButton: Tối ưu cho màn hình 360x804 (phone).
- HUD: Hiển thị Score ở giữa trên; Laser Level ở góc (tuỳ thiết bị).
- Title Overlay: Màn hình bắt đầu game.
- Game Over Overlay: Hiển thị "GAME OVER", điểm số, nút chơi lại/thoát.

## Tối ưu mobile (đã áp dụng)
- Tăng kích thước joystick và shoot button trên phone.
- Giảm tốc độ và tần suất spawn thiên thạch (dễ chơi hơn trên màn nhỏ).
- Player tốc độ 250 px/s; khoá trong khung hình (không wrap cạnh).
- Score/Laser UI tự co giãn theo kích thước thiết bị.

## Cách chạy nhanh
- Thiết bị: Android đã kết nối (USB Debugging) hoặc chạy emulator.
- Lệnh chạy (đã dùng gần nhất):
  - `flutter run -d <deviceId>`
- Trong code: Game khởi chạy qua `main.dart` → `MyGame` → `Title Overlay`.

## Ghi chú kỹ thuật nổi bật
- Separation of Concerns: Button UI chỉ bật/tắt trạng thái bắn; Player chịu trách nhiệm spawn laser và fire rate.
- SpawnComponent: Tạo thiên thạch/pickup theo khoảng thời gian ngẫu nhiên.
- Collision: Flame Collisions cho Player, Laser, Asteroid, Pickup, Shield.
- Effects: ScaleEffect dùng để pop score và highlight nâng cấp laser.

## Xử lý & Thuật toán (kèm code)

### 1) Di chuyển Player + giới hạn khung hình
```dart
@override
void update(double dt) {
  super.update(dt);
  // Hợp nhất joystick + keyboard, chuẩn hóa hướng, nhân tốc độ 250 px/s
  final Vector2 movement = game.joystick.relativeDelta + _keyboardMovement;
  position += movement.normalized() * 250 * dt;
  _handleScreenBounds();
}

void _handleScreenBounds() {
  final w = game.size.x, h = game.size.y;
  // Khóa trong màn hình (không wrap)
  position.y = clampDouble(position.y, size.y / 2, h - size.y / 2);
  position.x = clampDouble(position.x, size.x / 2, w - size.x / 2);
}
```

Ý tưởng: dùng clamp để neo tàu trong màn hình; tốc độ 250 giúp điều khiển mượt trên mobile.

### 2) Vòng bắn, tốc độ bắn và thuật toán tỏa tia theo cấp
```dart
// Tích lũy thời gian, đủ cooldown thì bắn
_elapsedFireTime += dt;
if (_isShooting && _elapsedFireTime >= _fireCooldown) {
  _fireLaser();
  _elapsedFireTime = 0.0;
}

void _fireLasersByLevel() {
  final base = position + Vector2(0, -size.y / 2);
  if (_laserLevel == 1) {
    _createOptimizedLaser(base, 0.0);
  } else if (_laserLevel == 2) {
    // Hai tia song song cách nhau laserSpacing
    _createOptimizedLaser(base + Vector2(-laserSpacing / 2, 0), 0.0);
    _createOptimizedLaser(base + Vector2(laserSpacing / 2, 0), 0.0);
  } else {
    // Level >=3: tỏa góc đều trong 60 độ
    final n = _laserLevel.clamp(3, maxLaserLevel);
    final spread = 60.0 * degrees2Radians;
    final step = spread / (n - 1);
    for (int i = 0; i < n; i++) {
      final angle = -spread / 2 + i * step;
      _createOptimizedLaser(base, angle);
    }
  }
}
```

Ý tưởng: cơ chế Press & Hold cờ `_isShooting`; cooldown cố định 0.2s; tăng cấp bắn mở rộng số tia và góc tỏa.

### 3) Tạo vận tốc thiên thạch theo kích thước + xử lý biên
```dart
Vector2 _generateVelocity() {
  final force = _maxSize / size.x; // nhỏ hơn → nhanh hơn
  return Vector2(
    _random.nextDouble() * 90 - 45, // X: [-45, +45]
    75 + _random.nextDouble() * 37, // Y: [75, 112]
  ) * force;
}

void _handleScreenBounds() {
  // Dọn dẹp khi ra đáy màn hình
  if (position.y > game.size.y + size.y / 2) {
    removeFromParent();
  }
  // Wrap ngang trái/phải để gameplay liên tục
  final w = game.size.x;
  if (position.x < -size.x / 2) position.x = w + size.x / 2;
  else if (position.x > w + size.x / 2) position.x = -size.x / 2;
}
```

Ý tưởng: tốc độ tỉ lệ nghịch kích thước; wrap ngang để không “trống trải”, dọn dẹp dưới đáy tránh rò rỉ object.

### 4) Chuỗi damage/phá hủy/tách mảnh + rơi coin
```dart
void takeDamage() {
  game.audioManager.playSound('hit');
  _health--;
  if (_health <= 0) {
    if (size.x <= _maxSize / 3) _spawnCoin(); // mảnh cuối rơi coin
    removeFromParent();
    _createExplosion();
    _splitAsteroid(); // nếu còn đủ lớn
  } else {
    _flashWhite();
    _applyKnockback();
  }
}
```

Ý tưởng: phản hồi âm thanh+ánh sáng; mảnh nhỏ nhất rơi coin để tránh spam; knockback tạo cảm giác lực.

### 5) Spawner: cấu hình tần suất sinh đối tượng theo khoảng
```dart
// Asteroids: giảm mật độ cho màn hình nhỏ
_asteroidSpawner = SpawnComponent.periodRange(
  factory: (i) => Asteroid(position: _generateSpawnPosition()),
  minPeriod: 1.5,
  maxPeriod: 2.2,
  selfPositioning: true,
);

// Pickups: xuất hiện nhanh hơn để hỗ trợ người chơi
_pickupSpawner = SpawnComponent.periodRange(
  factory: (i) => Pickup(
    position: _generateSpawnPosition(),
    pickupType: PickupType.values[_random.nextInt(PickupType.values.length)],
  ),
  minPeriod: 2.5,
  maxPeriod: 5.0,
  selfPositioning: true,
);
```

Ý tưởng: dùng khoảng thời gian ngẫu nhiên để gameplay bớt nhàm; tinh chỉnh min/max theo thiết bị nhỏ.

### 6) HUD: cập nhật điểm và hiển thị Laser Level kèm hiệu ứng
```dart
void incrementScore(int amount) {
  _score += amount;
  _scoreDisplay.text = _score.toString();
  _scoreDisplay.add(ScaleEffect.to(
    Vector2.all(1.2),
    EffectController(duration: 0.05, alternate: true, curve: Curves.easeInOut),
  ));
}

void updateLaserLevelDisplay(int level) {
  _laserLevelDisplay.text = 'LASER LV.$level';
  _laserLevelDisplay.add(ScaleEffect.to(
    Vector2.all(1.3),
    EffectController(duration: 0.15, alternate: true, curve: Curves.easeInOut),
  ));
}
```

Ý tưởng: hiệu ứng scale ngắn tạo phản hồi thị giác rõ ràng khi tăng điểm/nâng cấp.

### 7) Tối ưu UI mobile: joystick & nút bắn
```dart
// Joystick: tăng size và margin trên phone
final isPhone = size.y > size.x;
final joystickSize = Vector2.all(size.x * (isPhone ? 0.28 : 0.12));
final margin = size.x * (isPhone ? 0.08 : 0.04);

// Shoot button: scale lớn hơn 30% trên phone để dễ chạm
_shootButton = ShootButton()
  ..anchor = Anchor.bottomRight
  ..position = Vector2(size.x - margin, size.y - margin)
  ..priority = 10;
if (isPhone) _shootButton.scale = Vector2.all(1.3);
```

Ý tưởng: ngón tay chiếm diện tích lớn trên màn nhỏ; tăng hit-area giúp thao tác chính xác.

## Hệ thống nâng cấp (Upgrades)

### A) Laser (pickup: laser)
- Cơ chế: Thu thập laser → tăng cấp vũ khí tối đa 10. Giữ nguyên tốc độ bắn (cooldown 0.2s), chỉ tăng số tia và độ phủ.
- Thuật toán tăng cấp và cập nhật UI/hiệu ứng:
```dart
void _upgradeLaserLevel() {
  if (_laserLevel < maxLaserLevel) {
    _laserLevel++;
    game.updateLaserLevelDisplay(_laserLevel); // HUD: 'LASER LV.x'
    _showUpgradeEffect(); // ScaleEffect ngắn trên Player
  } else {
    // Đã max: hiện tại chỉ log, có thể đổi thành bonus khác trong tương lai
    print('⭐ Laser đã đạt level tối đa!');
  }
}
```
- Bản đồ Level → Kiểu bắn:
  - Lv1: 1 tia thẳng (angle = 0)
  - Lv2: 2 tia song song (offset ±laserSpacing/2)
  - Lv3…Lv10: n tia tỏa đều 60°, step = spread/(n-1)
```dart
final n = _laserLevel.clamp(3, maxLaserLevel);
final spread = 60.0 * degrees2Radians;
final step = spread / (n - 1);
for (int i = 0; i < n; i++) {
  final angle = -spread / 2 + i * step; // từ -30° đến +30°
  _createOptimizedLaser(basePosition, angle);
}
```
- Phản hồi: HUD nhấp nháy (ScaleEffect 1.3x), Player “pop” 1.2x ngắn; âm thanh pickup dùng chung ‘collect’.

### B) Shield (pickup: shield)
- Cơ chế: Kích hoạt khiên bảo vệ, chặn va chạm phá hủy với asteroid. Nếu đang có khiên cũ, thay thế bằng khiên mới.
```dart
case PickupType.shield:
  if (activeShield != null) remove(activeShield!);
  activeShield = Shield();
  add(activeShield!);
  break;
```
- Tương tác va chạm: Trong Player.onCollision, chỉ gọi phá hủy khi KHÔNG có khiên:
```dart
if (other is Asteroid) {
  if (activeShield == null) _handleDestruction();
}
```
- Ghi chú: Chi tiết thời lượng/tác động chủ động (nếu có) nằm trong `components/shield.dart`.

### C) Bomb (pickup: bomb)
- Cơ chế: Kích hoạt bom AOE tại vị trí Player, mở rộng bán kính và phá hủy thiên thạch trong vùng ảnh hưởng.
```dart
case PickupType.bomb:
  game.add(Bomb(position: position.clone()));
  break;
```
- Sử dụng: Dọn màn hình khi quá tải, tạo “khoảng thở” để nhặt thêm pickup/né cụm thiên thạch.

### D) Coin (pickup: coin)
- Không phải nâng cấp; chỉ cộng điểm (+10). Coin sinh ra khi phá hủy mảnh asteroid nhỏ nhất (không còn tách).
```dart
if (size.x <= _maxSize / 3) _spawnCoin(); // chỉ mảnh cuối cùng mới rơi coin
```
- Điểm chỉ tăng khi THU coin (Pickup.onCollision trong Player), không tăng khi bắn trúng asteroid.

### Edge cases & Cân bằng
- Laser ở cấp tối đa: chỉ log; có thể thay bằng bonus khác (damage, piercing, score bonus) trong tương lai.
- Shield: nhặt mới sẽ thay thế cái cũ (không cộng dồn).
- Bomb/Shield không cộng điểm trực tiếp; Coin mới +10.
- Fire rate cố định 0.2s để giữ nhịp game ổn định; nâng cấp tập trung vào số tia/độ phủ thay vì spam đạn.

## Hướng phát triển tiếp theo (gợi ý)
- Thêm boss/đợt sóng (wave) tăng dần độ khó.
- Hệ thống nhiệm vụ/achievement đơn giản.
- Tuỳ chọn cấu hình nút (vị trí, kích thước) trong Settings.
- Haptic feedback khi bắn/nhặt vật phẩm (mobile).

---
Tác giả: tutaki304 
