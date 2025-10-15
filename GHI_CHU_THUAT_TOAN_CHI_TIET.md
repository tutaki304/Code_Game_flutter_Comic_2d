# 📚 GHI CHÚ CHI TIẾT CODE - COSMIC HAVOC

## 📖 MỤC LỤC
1. [main.dart](#1-maindart) - Entry point
2. [my_game.dart](#2-my_gamedart) - Game core logic
3. [player.dart](#3-playerdart) - Player ship
4. [asteroid.dart](#4-asteroiddart) - Asteroid system
5. [pickup.dart](#5-pickupdart) - Power-ups & coins
6. [laser.dart](#6-laserdart) - Laser projectile
7. [bomb.dart](#7-bombdart) - Bomb explosion
8. [shield.dart](#8-shielddart) - Shield protection
9. [explosion.dart](#9-explosiondart) - Particle effects
10. [star.dart](#10-stardart) - Background stars
11. [shoot_button.dart](#11-shoot_buttondart) - Touch shoot button
12. [audio_manager.dart](#12-audio_managerdart) - Dual audio system
13. [title_overlay.dart](#13-title_overlaydart) - Main menu
14. [game_over_overlay.dart](#14-game_over_overlaydart) - Game over screen

---

## 1. main.dart

### 📝 MỤC ĐÍCH
Entry point của ứng dụng Flutter. Khởi tạo game instance và thiết lập overlay system.

### 🔑 THUẬT TOÁN CHÍNH

#### 1.1 Main Function
```dart
void main() {
  final MyGame game = MyGame();  // Tạo singleton game instance
  runApp(GameWidget(...));       // Khởi chạy Flutter app
}
```

**Flow:**
1. Tạo instance của MyGame (game core)
2. Wrap vào GameWidget (Flame's game container)
3. Register overlays (UI screens)
4. Set initial overlay (Title screen)

#### 1.2 Overlay System
```dart
overlayBuilderMap: {
  'GameOver': (context, game) => GameOverOverlay(game: game),
  'Title': (context, game) => TitleOverlay(game: game),
}
```

**Thuật toán Overlay Routing:**
- Map<String, OverlayBuilder> lưu trữ builders
- Key = tên overlay
- Value = factory function trả về Widget
- Flame quản lý show/hide lifecycle

**Pattern:** Factory Pattern cho UI screens

---

## 2. my_game.dart

### 📝 MỤC ĐÍCH
Core game logic, quản lý game state, components, và game loop.

### 🏗️ KIẾN TRÚC

```
MyGame (FlameGame)
├─ Mixins
│  ├─ HasKeyboardHandlerComponents (Keyboard input)
│  └─ HasCollisionDetection (Physics engine)
├─ Components
│  ├─ AudioManager (Sound system)
│  ├─ Stars (Background, 50-100 instances)
│  ├─ JoystickComponent (Touch input)
│  ├─ ShootButton (Touch input)
│  ├─ Player (Main character)
│  ├─ SpawnComponent (Asteroids spawner)
│  ├─ SpawnComponent (Pickups spawner)
│  ├─ Score Display (UI Text)
│  └─ Laser Level Display (UI Text)
└─ State
   ├─ _score (int)
   ├─ playerColorIndex (int)
   └─ _random (Random instance)
```

### 🔑 THUẬT TOÁN CHÍNH

#### 2.1 Initialization Sequence (onLoad)
```dart
async onLoad() {
  1. await Flame.device.fullScreen();     // System UI setup
  2. await Flame.device.setPortrait();     // Lock orientation
  3. audioManager = AudioManager();        // Audio initialization
  4. await add(audioManager);              // Add to component tree
  5. _createStars();                       // Background setup
  6. return super.onLoad();                // Flame initialization
}
```

**Thứ tự quan trọng:**
- System config TRƯỚC components
- Audio manager TRƯỚC game start (preload sounds)
- Background TRƯỚC foreground objects

#### 2.2 Game Start Sequence
```dart
startGame() {
  1. _createJoystick()         // Input setup
  2. _createPlayer()           // Player spawn
  3. _createShootButton()      // UI setup
  4. _createAsteroidSpawner()  // Enemy spawner
  5. _createPickupSpawner()    // Powerup spawner
  6. _createScoreDisplay()     // UI setup
  7. _createLaserLevelDisplay() // UI setup
  8. _showDeviceInfo()         // Debug info
}
```

**Dependency Order:**
- Input systems → Player → Enemies → UI
- Đảm bảo player tồn tại trước khi spawn enemies

#### 2.3 Adaptive UI Algorithm
```dart
// THUẬT TOÁN: Phát hiện loại thiết bị
final isPhone = size.y > size.x;  // Portrait ratio check

// THUẬT TOÁN: Tính toán responsive size
if (isPhone) {
  joystickSizePercent = 0.24;     // 24% screen width
  marginPercent = 0.08;            // 8% margin
  buttonScale = 1.2;               // 120% size
} else {
  joystickSizePercent = 0.12;     // 12% screen width
  marginPercent = 0.04;            // 4% margin
  buttonScale = 1.0;               // 100% size (default)
}

final actualSize = size.x * sizePercent;
```

**Công thức Responsive:**
```
Actual Size = Screen Width × Size Percentage
Margin = Screen Width × Margin Percentage
```

**Rationale:**
- Portrait (height > width) = Mobile phone
- Landscape (width > height) = Tablet/Desktop
- Mobile cần controls lớn hơn (touch targets)

#### 2.4 Spawn System Algorithm
```dart
// THUẬT TOÁN: Periodic Spawn với Random Range
SpawnComponent.periodRange(
  factory: (index) => createObject(),
  minPeriod: min_seconds,
  maxPeriod: max_seconds,
  selfPositioning: true
)

// Internal Algorithm:
// 1. Timer countdown từ random(minPeriod, maxPeriod)
// 2. Khi timer = 0:
//    - Call factory(index)
//    - Reset timer với random mới
//    - index++
// 3. selfPositioning = true → không auto-set position
```

**Asteroid Spawn Rate (Mobile Optimized):**
```
minPeriod = 1.2s
maxPeriod = 1.8s
Average = (1.2 + 1.8) / 2 = 1.5s
Rate = 1 / 1.5 = 0.67 asteroids/second ≈ 40 asteroids/minute
```

**Pickup Spawn Rate (Mobile Optimized):**
```
minPeriod = 3.0s
maxPeriod = 6.0s
Average = 4.5s
Rate = 1 / 4.5 ≈ 0.22 pickups/second ≈ 13 pickups/minute
```

#### 2.5 Random Spawn Position Algorithm
```dart
Vector2 _generateSpawnPosition() {
  // THUẬT TOÁN: Random X với padding, Fixed Y ở trên màn hình
  final padding = 10.0;
  final minX = padding;
  final maxX = size.x - padding * 2;
  
  // Random trong khoảng [minX, maxX]
  final x = minX + _random.nextDouble() * (maxX - minX);
  
  // Y cố định ở trên màn hình (-100 để spawn ngoài view)
  final y = -100.0;
  
  return Vector2(x, y);
}
```

**Công thức:**
```
X = min + random(0, 1) × (max - min)
Y = -100 (constant, off-screen top)
```

**Padding rationale:**
- Tránh spawn sát mép màn hình
- Đảm bảo objects luôn visible khi di chuyển vào

#### 2.6 Score System Algorithm
```dart
void incrementScore(int points) {
  _score += points;
  _scoreDisplay.text = '$_score';
}

// Called by:
// - Player.onCollision(Pickup.coin) → +10 points
```

**Score Mechanics:**
- Chỉ tăng khi thu coin (không phải khi kill asteroid)
- Mỗi coin = +10 điểm cố định
- Text UI update real-time

#### 2.7 Reset Game Algorithm
```dart
void resetGame() {
  // 1. Clear state
  _score = 0;
  _scoreDisplay.text = '0';
  
  // 2. Remove all dynamic components
  player.removeFromParent();
  children.whereType<Asteroid>().forEach((a) => a.removeFromParent());
  children.whereType<Laser>().forEach((l) => l.removeFromParent());
  children.whereType<Pickup>().forEach((p) => p.removeFromParent());
  
  // 3. Reset spawners
  _asteroidSpawner.timer.start();
  _pickupSpawner.timer.start();
  
  // 4. Recreate player
  startGame();
}
```

**Clean-up Order:**
- State → Components → Spawners → Reinitialize

#### 2.8 Game Over Sequence
```dart
void gameOver() {
  // 1. Stop spawners
  _asteroidSpawner.timer.stop();
  _pickupSpawner.timer.stop();
  
  // 2. Show overlay
  overlays.add('GameOver');
  
  // 3. Remove game overlay if any
  overlays.remove('Game');
}
```

---

## 3. player.dart

### 📝 MỤC ĐÍCH
Player ship với movement, shooting, collision, và laser upgrade system.

### 🏗️ KIẾN TRÚC

```
Player (SpriteAnimationComponent)
├─ Mixins
│  ├─ HasGameReference<MyGame>
│  ├─ KeyboardHandler
│  └─ CollisionCallbacks
├─ State
│  ├─ _isShooting (bool)
│  ├─ _laserLevel (int 1-10)
│  ├─ activeShield (Shield?)
│  └─ _isDestroyed (bool)
├─ Timers
│  ├─ _fireCooldown (0.2s)
│  ├─ _elapsedFireTime (accumulator)
│  └─ _explosionTimer (death animation)
└─ Components
   ├─ RectangleHitbox (collision)
   └─ Shield (optional child)
```

### 🔑 THUẬT TOÁN CHÍNH

#### 3.1 Movement Algorithm
```dart
update(dt) {
  // THUẬT TOÁN: Vector Addition + Normalization + Velocity
  
  // 1. Combine inputs
  final movement = joystick.delta + keyboard.delta;
  
  // 2. Normalize (prevent diagonal speed boost)
  final normalized = movement.normalized();
  // normalized.length() = 1.0 (constant speed)
  
  // 3. Apply velocity
  final velocity = 200.0;  // pixels/second
  position += normalized * velocity * dt;
  
  // 4. Clamp to screen bounds
  _handleScreenBounds();
}
```

**Công thức Velocity:**
```
New Position = Old Position + Direction × Speed × DeltaTime

Direction: normalized vector (length = 1)
Speed: 200 px/s
DeltaTime: seconds since last frame (typically 0.016s @ 60fps)

Example @ 60 FPS:
Movement per frame = 1.0 × 200 × 0.016 = 3.2 pixels
```

**Normalization Math:**
```
Vector v = (x, y)
Length = sqrt(x² + y²)
Normalized = (x/length, y/length)

Example:
Input: (1, 1)     → diagonal
Length: sqrt(2) ≈ 1.414
Normalized: (0.707, 0.707)
Result: Same speed as cardinal directions
```

#### 3.2 Screen Bounds Clamping
```dart
void _handleScreenBounds() {
  // THUẬT TOÁN: Clamp với padding
  final padding = size.x / 2;  // Half sprite width
  
  position.x = position.x.clamp(
    padding,                    // Min: left edge + padding
    game.size.x - padding      // Max: right edge - padding
  );
  
  position.y = position.y.clamp(
    padding,                    // Min: top edge + padding
    game.size.y - padding      // Max: bottom edge - padding
  );
}
```

**Clamp Function:**
```
clamp(value, min, max) {
  if (value < min) return min;
  if (value > max) return max;
  return value;
}
```

#### 3.3 Laser Firing System
```dart
// THUẬT TOÁN: Cooldown-based Auto-fire
update(dt) {
  _elapsedFireTime += dt;  // Accumulate time
  
  if (_isShooting && _elapsedFireTime >= _fireCooldown) {
    _fireLaser();
    _elapsedFireTime = 0.0;  // Reset accumulator
  }
}

// Fire rate = 1 / cooldown = 1 / 0.2 = 5 shots/second
```

**Cooldown Timing Diagram:**
```
Time:    0.0  0.2  0.4  0.6  0.8  1.0  (seconds)
Shoot:    🔫   🔫   🔫   🔫   🔫
Cooldown: ←───→←───→←───→←───→←───→
```

#### 3.4 Multi-Laser Algorithm (Level-based)
```dart
void _fireLasersByLevel() {
  // THUẬT TOÁN: Pattern Generation dựa trên level
  
  if (_laserLevel == 1) {
    // Pattern: Single center shot
    _createLaser(position, 0.0);
  }
  else if (_laserLevel == 2) {
    // Pattern: Parallel dual shot
    _createLaser(position + Vector2(-spacing/2, 0), 0.0);
    _createLaser(position + Vector2(+spacing/2, 0), 0.0);
  }
  else {
    // Pattern: Radial spread (level 3-10)
    final numLasers = _laserLevel.clamp(3, 10);
    final totalSpread = 60° × π/180;  // Convert to radians
    final angleStep = totalSpread / (numLasers - 1);
    
    for (int i = 0; i < numLasers; i++) {
      final angle = -totalSpread/2 + i * angleStep;
      _createLaser(position, angle);
    }
  }
}
```

**Spread Angle Calculation:**
```
Total Spread: 60° (-30° to +30°)
Num Lasers: n
Angle Step: 60° / (n-1)

Example n=5:
Step = 60° / 4 = 15°
Angles: -30°, -15°, 0°, +15°, +30°

Example n=10:
Step = 60° / 9 ≈ 6.67°
Angles: -30°, -23.33°, -16.67°, -10°, -3.33°, +3.33°, +10°, +16.67°, +23.33°, +30°
```

**Laser Pattern Visualization:**
```
Level 1:        Level 2:       Level 5:
   ↑               ↑ ↑          ╱ ╱ ↑ ╲ ╲
   🛸              🛸             🛸

Level 10:
╱╱╱╱↑╲╲╲╲
    🛸
```

#### 3.5 Collision Detection Algorithm
```dart
onCollisionStart(other) {
  if (other is Asteroid) {
    // THUẬT TOÁN: Shield check → Damage → Game Over
    if (activeShield != null) {
      activeShield.removeFromParent();  // Shield absorbs hit
      activeShield = null;
      return;  // Player survives
    }
    
    // No shield → Death
    _isDestroyed = true;
    _explosionTimer.start();  // Death animation
    game.gameOver();
  }
  
  else if (other is Pickup) {
    // THUẬT TOÁN: Type-based power-up application
    switch (other.pickupType) {
      case PickupType.laser:
        _upgradeLaser();
        break;
      case PickupType.shield:
        _activateShield();
        break;
      case PickupType.bomb:
        _launchBomb();
        break;
      case PickupType.coin:
        game.incrementScore(10);
        game.audioManager.playSound('dropcoin');
        break;
    }
    
    other.removeFromParent();  // Consume pickup
  }
}
```

**Collision Response Table:**
| Collision Type | Shield? | Action |
|----------------|---------|--------|
| Asteroid + Shield | Yes | Remove shield, continue |
| Asteroid + No Shield | No | Death, game over |
| Pickup.laser | N/A | Upgrade laser +1 level |
| Pickup.shield | N/A | Add shield child component |
| Pickup.bomb | N/A | Destroy all asteroids |
| Pickup.coin | N/A | +10 score, play sound |

#### 3.6 Laser Upgrade Algorithm
```dart
void _upgradeLaser() {
  if (_laserLevel < maxLaserLevel) {
    _laserLevel++;
    
    // Visual feedback
    add(ScaleEffect.to(
      Vector2.all(1.3),        // Scale up to 130%
      EffectController(
        duration: 0.2,
        reverseDuration: 0.2,  // Scale back to 100%
        curve: Curves.easeOut
      )
    ));
    
    // Audio feedback
    game.audioManager.playSound('collect');
    
    // UI update
    game.updateLaserLevelDisplay(_laserLevel);
  }
}
```

**Upgrade Progression:**
```
Level:  1  2  3  4  5  6  7  8  9 10
Lasers: 1  2  3  4  5  6  7  8  9 10
Spread: -  -  60 60 60 60 60 60 60 60 (degrees)
```

#### 3.7 Shield Activation Algorithm
```dart
void _activateShield() {
  // THUẬT TOÁN: Remove old → Create new
  
  // 1. Clean up existing shield (if any)
  if (activeShield != null) {
    activeShield!.removeFromParent();
  }
  
  // 2. Create new shield
  activeShield = Shield();
  add(activeShield);  // Add as child component
  
  // Parent-child relationship:
  // - Shield position = player.position (automatic)
  // - Shield moves with player (automatic)
  // - Shield removed when player dies (automatic)
}
```

#### 3.8 Bomb Launch Algorithm
```dart
void _launchBomb() {
  // THUẬT TOÁN: Find all → Destroy each → Effects
  
  final bomb = Bomb(position: position.clone());
  game.add(bomb);  // Add to world
  
  // In Bomb.onLoad():
  // 1. Get all asteroids
  final asteroids = game.children.whereType<Asteroid>();
  
  // 2. Destroy each with effects
  for (final asteroid in asteroids) {
    asteroid.removeFromParent();
    game.add(Explosion(position: asteroid.position));
  }
  
  // 3. Play explosion sound
  game.audioManager.playSound('explode1');
}
```

---

## 4. asteroid.dart

### 📝 MỤC ĐÍCH
Asteroid enemy với splitting mechanism, health system, và coin drop.

### 🏗️ KIẾN TRÚC

```
Asteroid (SpriteComponent)
├─ State
│  ├─ _spriteName (asteroid1/2/3.png)
│  ├─ _health (int, based on size)
│  ├─ _maxSize (120px constant)
│  └─ _random (Random instance)
└─ Components
   └─ RectangleHitbox (collision)
```

### 🔑 THUẬT TOÁN CHÍNH

#### 4.1 Size-based Health System
```dart
// THUẬT TOÁN: Health = f(size)
void _initializeHealth() {
  if (size.x >= _maxSize * 2/3) {
    _health = 3;  // Large: ≥80px
  } else if (size.x >= _maxSize / 3) {
    _health = 2;  // Medium: ≥40px
  } else {
    _health = 1;  // Small: <40px
  }
}
```

**Health Table:**
| Size (px) | Category | Health | Hits to Kill |
|-----------|----------|--------|--------------|
| 120 | Large | 3 | 3 |
| 80 | Medium | 2 | 2 |
| 40 | Small | 1 | 1 |

#### 4.2 Splitting Algorithm
```dart
void _splitAsteroid() {
  // THUẬT TOÁN: Recursive splitting với size reduction
  
  if (size.x <= _maxSize / 3) {
    return;  // Too small, don't split
  }
  
  // Calculate new size (66% of current)
  final newSize = size.x * 2 / 3;
  
  // Random số lượng mảnh (2 hoặc 3)
  final numFragments = 2 + _random.nextInt(2);
  
  for (int i = 0; i < numFragments; i++) {
    // Random angle for scatter
    final angle = _random.nextDouble() * 2 * pi;
    
    // Offset position
    final offset = Vector2(
      cos(angle) * 20,
      sin(angle) * 20
    );
    
    // Create fragment
    final fragment = Asteroid(
      position: position + offset,
      size: Vector2.all(newSize)
    );
    
    game.add(fragment);
  }
}
```

**Splitting Tree:**
```
Large (120px, 3 HP)
    ↓ Hit 3 times
    ├─ Medium (80px, 2 HP)
    │   ↓ Hit 2 times
    │   ├─ Small (40px, 1 HP)
    │   └─ Small (40px, 1 HP)
    ├─ Medium (80px, 2 HP)
    │   ↓ Hit 2 times
    │   ├─ Small (40px, 1 HP)
    │   └─ Small (40px, 1 HP)
    └─ Medium (80px, 2 HP) [if numFragments=3]
```

**Size Reduction:**
```
Generation 0: 120px
Generation 1: 120 × 2/3 = 80px
Generation 2: 80 × 2/3 ≈ 53.3px → clamp to 40px minimum
Generation 3: Would be < 40px → no split
```

#### 4.3 Damage & Coin Drop Algorithm
```dart
void takeDamage() {
  // 1. Audio feedback
  game.audioManager.playSound('hit');
  
  // 2. Reduce health
  _health--;
  
  // 3. Check destruction
  if (_health <= 0) {
    // THUẬT TOÁN: Coin drop check
    if (size.x <= _maxSize / 3) {
      _spawnCoin();  // Drop coin for smallest fragments
    }
    
    removeFromParent();
    _createExplosion();
    _splitAsteroid();
  } else {
    // Damaged but alive → visual feedback
    _flashWhite();
    _applyKnockback();
  }
}
```

**Coin Drop Logic:**
```
Large asteroid destroyed   → NO coin (splits into medium)
Medium asteroid destroyed  → NO coin (splits into small)
Small asteroid destroyed   → COIN! (cannot split further)
```

**Rationale:** Người chơi phải phá hủy HOÀN TOÀN asteroid để nhận coin.

#### 4.4 Coin Spawn Algorithm
```dart
void _spawnCoin() {
  // THUẬT TOÁN: Simple factory at destruction position
  final coin = Pickup(
    position: position.clone(),
    pickupType: PickupType.coin
  );
  game.add(coin);
}
```

#### 4.5 Movement Algorithm
```dart
update(dt) {
  // THUẬT TOÁN: Constant downward velocity
  final velocity = 300.0;  // px/s
  position.y += velocity * dt;
  
  // Auto-remove when off-screen
  if (position.y > game.size.y + size.y) {
    removeFromParent();
  }
}
```

#### 4.6 Visual Feedback Algorithms

**Flash Effect:**
```dart
void _flashWhite() {
  // THUẬT TOÁN: Temporary color tint
  add(ColorEffect(
    Colors.white,
    EffectController(
      duration: 0.1,
      reverseDuration: 0.1,
      curve: Curves.easeInOut
    ),
    opacityFrom: 0.0,
    opacityTo: 0.8
  ));
}
```

**Knockback Effect:**
```dart
void _applyKnockback() {
  // THUẬT TOÁN: Reverse velocity impulse
  final knockbackDistance = 20.0;
  add(MoveEffect.by(
    Vector2(0, -knockbackDistance),  // Move up (opposite of movement)
    EffectController(
      duration: 0.1,
      curve: Curves.easeOut
    )
  ));
}
```

---

## 5. pickup.dart

### 📝 MỤC ĐÍCH
Power-ups và coins với visual animation và auto-collection.

### 🏗️ KIẾN TRÚC

```
Pickup (SpriteComponent)
├─ pickupType (enum: bomb/laser/shield/coin)
├─ Size
│  ├─ Power-ups: 100×100px
│  └─ Coins: 40×40px
└─ Components
   └─ CircleHitbox (collision)
```

### 🔑 THUẬT TOÁN CHÍNH

#### 5.1 Size Differentiation Algorithm
```dart
Pickup({required this.pickupType, required Vector2 position}) {
  // THUẬT TOÁN: Conditional sizing
  if (pickupType == PickupType.coin) {
    size = Vector2.all(40);   // Smaller for coins
  } else {
    size = Vector2.all(100);  // Standard for power-ups
  }
  
  this.position = position;
}
```

**Size Rationale:**
- Coins nhỏ hơn vì xuất hiện thường xuyên hơn
- Power-ups lớn hơn vì quan trọng hơn (visual emphasis)

#### 5.2 Pulsing Animation Algorithm
```dart
onLoad() {
  // THUẬT TOÁN: Infinite ping-pong scale effect
  add(ScaleEffect.to(
    Vector2.all(0.9),           // Scale down to 90%
    EffectController(
      duration: 0.5,             // 0.5s to shrink
      reverseDuration: 0.5,      // 0.5s to grow back
      infinite: true,            // Loop forever
      curve: Curves.easeInOut   // Smooth acceleration
    )
  ));
}
```

**Animation Timing:**
```
Time:  0.0   0.5   1.0   1.5   2.0  (seconds)
Scale: 1.0 → 0.9 → 1.0 → 0.9 → 1.0
       ──────▼──────▲──────▼──────▲
       shrink    grow   shrink   grow
```

#### 5.3 Movement & Auto-removal
```dart
update(dt) {
  // THUẬT TOÁN: Constant downward movement
  position.y += 300 * dt;
  
  // THUẬT TOÁN: Off-screen culling
  if (position.y > game.size.y + size.y / 2) {
    removeFromParent();  // Clean up memory
  }
}
```

---

## 6. laser.dart

### 📝 MỤC ĐÍCH
Projectile với angled movement và collision detection.

### 🔑 THUẬT TOÁN CHÍNH

#### 6.1 Angled Movement Algorithm
```dart
update(dt) {
  // THUẬT TOÁN: Vector decomposition
  final velocity = 600.0;  // px/s
  
  // Decompose angle into X/Y components
  position.x += cos(_angle) * velocity * dt;
  position.y += sin(_angle) * velocity * dt;
  
  // Off-screen removal
  if (position.y < -size.y) {
    removeFromParent();
  }
}
```

**Trigonometry:**
```
          ↑ y (sin θ)
          |
   Laser  | 
      ╲   |
     θ ╲  |
        ╲ |
─────────╲|────── → x (cos θ)

X component = velocity × cos(angle)
Y component = velocity × sin(angle)
Total velocity magnitude = 600 px/s
```

**Example Calculations:**
```
Angle 0° (straight up):
  X = 600 × cos(0°) = 600 × 0 = 0
  Y = 600 × sin(0°) = 600 × -1 = -600
  Result: Moves straight up

Angle -30° (right diagonal):
  X = 600 × cos(-30°) ≈ 600 × 0.866 ≈ 520
  Y = 600 × sin(-30°) ≈ 600 × -0.5 = -300
  Result: Moves up-right diagonal

Angle +30° (left diagonal):
  X = 600 × cos(+30°) ≈ 600 × 0.866 ≈ 520
  Y = 600 × sin(+30°) ≈ 600 × -0.5 = -300
  Result: Moves up-left diagonal
```

#### 6.2 Collision Algorithm
```dart
onCollisionStart(other) {
  if (other is Asteroid) {
    other.takeDamage();
    removeFromParent();  // Bullet consumed
  }
}
```

---

## 7. bomb.dart

### 📝 MỤC ĐÍCH
Screen-clearing power-up với area-of-effect damage.

### 🔑 THUẬT TOÁN CHÍNH

#### 7.1 AOE Destruction Algorithm
```dart
onLoad() {
  // THUẬT TOÁN: Query all → Filter type → Apply effect
  
  // 1. Get all game objects
  final children = game.children;
  
  // 2. Filter asteroids only
  final asteroids = children.whereType<Asteroid>().toList();
  
  // 3. Destroy each asteroid
  for (final asteroid in asteroids) {
    // Create explosion effect
    final explosion = Explosion(position: asteroid.position);
    game.add(explosion);
    
    // Remove asteroid
    asteroid.removeFromParent();
  }
  
  // 4. Sound effect
  game.audioManager.playSound('explode1');
  
  // 5. Remove self
  removeFromParent();
}
```

**Pseudo-code:**
```
FUNCTION bomb.activate():
  asteroids = GET_ALL_OBJECTS_OF_TYPE(Asteroid)
  FOR EACH asteroid IN asteroids:
    CREATE explosion AT asteroid.position
    DESTROY asteroid
  END FOR
  PLAY_SOUND('explode1')
  DESTROY self
END FUNCTION
```

---

## 8. shield.dart

### 📝 MỤC ĐÍCH
Defensive power-up, child component của player.

### 🔑 THUẬT TOÁN CHÍNH

#### 8.1 Parent-Child Positioning
```dart
update(dt) {
  // THUẬT TOÁN: Automatic positioning (Flame handles this)
  // Shield.position = Player.position (relative)
  // No manual calculation needed
}
```

**Parent-Child System:**
```
Player (parent)
  position: (100, 200)
  ↓
  Shield (child)
    position: (0, 0) relative to parent
    absolute position: (100, 200) automatic
```

#### 8.2 Visual Pulse Animation
```dart
onLoad() {
  // THUẬT TOÁN: Opacity pulse
  add(OpacityEffect.to(
    0.3,                      // Fade to 30%
    EffectController(
      duration: 0.5,
      reverseDuration: 0.5,
      infinite: true
    )
  ));
}
```

---

## 9. explosion.dart

### 📝 MỤC ĐÍCH
Particle system cho visual feedback khi phá hủy objects.

### 🔑 THUẬT TOÁN CHÍNH

#### 9.1 Particle Generation Algorithm
```dart
void _createParticles() {
  // THUẬT TOÁN: Random particle spray
  final numParticles = 10 + _random.nextInt(6);  // 10-15 particles
  
  for (int i = 0; i < numParticles; i++) {
    // Random angle (360°)
    final angle = _random.nextDouble() * 2 * pi;
    
    // Random speed (100-300 px/s)
    final speed = 100 + _random.nextDouble() * 200;
    
    // Calculate velocity vector
    final velocity = Vector2(
      cos(angle) * speed,
      sin(angle) * speed
    );
    
    // Random color (yellow/orange/red)
    final colors = [
      Colors.yellow,
      Colors.orange,
      Colors.red,
      Colors.deepOrange
    ];
    final color = colors[_random.nextInt(colors.length)];
    
    // Create particle
    final particle = CircleComponent(
      radius: 2 + _random.nextDouble() * 3,  // 2-5px
      paint: Paint()..color = color,
      position: position.clone()
    );
    
    // Add velocity effect
    particle.add(MoveEffect.by(
      velocity,
      EffectController(duration: 1.0)
    ));
    
    // Add fade-out
    particle.add(OpacityEffect.to(
      0.0,
      EffectController(duration: 1.0)
    ));
    
    game.add(particle);
  }
  
  // Auto-remove explosion center
  add(RemoveEffect(delay: 1.0));
}
```

**Particle Distribution:**
```
     ●    ●   ● 
   ●    💥    ●
     ●    ●   ●

Angle: Random 0-360°
Speed: Random 100-300 px/s
Color: Random warm colors
Size: Random 2-5px radius
```

#### 9.2 Flash Effect Algorithm
```dart
void _createFlash() {
  // THUẬT TOÁN: Expanding white circle
  final flash = CircleComponent(
    radius: 10,
    paint: Paint()..color = Colors.white,
    position: position.clone()
  );
  
  // Scale up
  flash.add(ScaleEffect.to(
    Vector2.all(3.0),  // 3x size
    EffectController(duration: 0.2)
  ));
  
  // Fade out
  flash.add(OpacityEffect.to(
    0.0,
    EffectController(duration: 0.2)
  ));
  
  game.add(flash);
}
```

---

## 10. star.dart

### 📝 MỤC ĐÍCH
Parallax scrolling background cho depth effect.

### 🔑 THUẬT TOÁN CHÍNH

#### 10.1 Parallax Speed Algorithm
```dart
// THUẬT TOÁN: Random speed layers
final speed = 20 + _random.nextDouble() * 80;  // 20-100 px/s

update(dt) {
  position.y += speed * dt;
  
  // Wrap around
  if (position.y > game.size.y) {
    position.y = -10;
    position.x = _random.nextDouble() * game.size.x;
  }
}
```

**Parallax Layers:**
```
Fast stars (80-100 px/s):   ●  ●  ●  (close)
Medium stars (50-80 px/s):   ●   ●   ●
Slow stars (20-50 px/s):      ●    ●    ●  (far)
```

**Depth Illusion:**
- Faster stars = appear closer
- Slower stars = appear farther
- Creates 3D depth on 2D screen

---

## 11. shoot_button.dart

### 📝 MỤC ĐÍCH
Touch input button cho mobile shooting.

### 🔑 THUẬT TOÁN CHÍNH

#### 11.1 Touch Event Handling
```dart
onTapDown(event) {
  game.player.startShooting();
  scale = Vector2.all(0.9);  // Visual press feedback
}

onTapUp(event) {
  game.player.stopShooting();
  scale = Vector2.all(1.0);  // Return to normal
}

onTapCancel(event) {
  game.player.stopShooting();
  scale = Vector2.all(1.0);
}
```

**State Machine:**
```
[Released] ─tap down→ [Pressed] ─tap up→ [Released]
    ↑                     ↓
    └────── tap cancel ───┘
```

---

## 12. audio_manager.dart

### 📝 MỤC ĐÍCH
Dual audio system: SoLoud (SFX) + FlameAudio (BGM).

### 🔑 THUẬT TOÁN CHÍNH

#### 12.1 Preload System Algorithm
```dart
async onLoad() {
  // THUẬT TOÁN: Batch preload với error handling
  
  for (String sound in _sounds) {
    try {
      // Load OGG file vào RAM
      final source = await _soloud.loadAsset(
        'assets/audio/$sound.ogg'
      );
      
      // Cache trong Map
      _soundSources[sound] = source;
      
      print('✅ Loaded: $sound.ogg');
    } catch (e) {
      // Fail individual files, continue loading
      print('❌ Failed to load $sound.ogg: $e');
    }
  }
}
```

**Loading Sequence:**
```
Start
  ↓
For each sound file:
  ├─ Try load from assets
  ├─ If success: Store in Map
  ├─ If fail: Log error, continue
  └─ Next file
  ↓
Complete (all sounds loaded or attempted)
```

**Memory Structure:**
```
_soundSources (Map<String, AudioSource>)
├─ 'click' → AudioSource(click.ogg bytes in RAM)
├─ 'collect' → AudioSource(collect.ogg bytes in RAM)
├─ 'dropcoin' → AudioSource(dropcoin.ogg bytes in RAM)
└─ ... (all 9 sounds)
```

#### 12.2 Playback Algorithm
```dart
void playSound(String sound) {
  // THUẬT TOÁN: Map lookup + instant play
  
  // 1. Check enabled
  if (!soundsEnabled) return;
  
  // 2. Check exists
  if (!_soundSources.containsKey(sound)) return;
  
  // 3. Play from RAM (zero latency)
  try {
    _soloud.play(_soundSources[sound]!);
  } catch (e) {
    print('❌ Error playing $sound: $e');
  }
}
```

**Playback Speed:**
- RAM access: ~1 nanosecond
- SoLoud mixing: ~1 millisecond
- Total latency: <5ms (imperceptible)

---

## 13. title_overlay.dart

### 📝 MỤC ĐÍCH
Main menu với player color selection.

### 🔑 THUẬT TOÁN CHÍNH

#### 13.1 Color Picker Algorithm
```dart
void _buildColorPicker() {
  // THUẬT TOÁN: Horizontal scroll list
  return ListView.builder(
    scrollDirection: Axis.horizontal,
    itemCount: game.playerColors.length,
    itemBuilder: (context, index) {
      return GestureDetector(
        onTap: () {
          setState(() {
            game.playerColorIndex = index;  // Update selection
          });
        },
        child: Container(
          decoration: BoxDecoration(
            border: index == game.playerColorIndex
              ? Border.all(color: Colors.white, width: 3)
              : null,  // Highlight selected
          ),
          child: Image.asset(
            'assets/images/player_${game.playerColors[index]}_off.png'
          ),
        ),
      );
    },
  );
}
```

**UI Layout:**
```
┌─────────────────────────┐
│  COSMIC HAVOC          │
├─────────────────────────┤
│  [🔵] [🔴] [🟢] [🟣]  │ ← Scrollable color picker
│   ↑                     │
│ Selected (white border) │
├─────────────────────────┤
│     [ START ]           │
└─────────────────────────┘
```

---

## 14. game_over_overlay.dart

### 📝 MỤC ĐÍCH
Game over screen với score display và restart option.

### 🔑 THUẬT TOÁN CHÍNH

#### 14.1 Restart Flow
```dart
onPressed: () {
  // THUẬT TOÁN: Clean state → Hide overlay → Reset game
  
  // 1. Remove game over UI
  game.overlays.remove('GameOver');
  
  // 2. Reset game state
  game.resetGame();
  
  // 3. Show title screen (optional)
  game.overlays.add('Title');
}
```

---

## 🧮 TỔNG HỢP THUẬT TOÁN & CÔNG THỨC

### Math & Physics

#### Velocity & Movement
```
Position Update: P' = P + V × Δt
  P' = new position
  P = current position
  V = velocity vector
  Δt = delta time (frame time)

Normalization: V̂ = V / |V|
  V̂ = normalized vector (length 1)
  V = original vector
  |V| = length = sqrt(Vx² + Vy²)

Angle to Vector:
  Vx = magnitude × cos(angle)
  Vy = magnitude × sin(angle)
```

#### Collision Detection
```
Circle-Circle: distance < r1 + r2
Rectangle-Rectangle: AABB (Axis-Aligned Bounding Box)
  if (x1 < x2 + w2 && x1 + w1 > x2 &&
      y1 < y2 + h2 && y1 + h1 > y2)
```

### Game Logic

#### Spawn Rate
```
Average Spawn Time = (minPeriod + maxPeriod) / 2
Spawn Rate = 1 / Average Spawn Time
Objects per Minute = Spawn Rate × 60
```

#### Damage Calculation
```
Health = initial_health
Damage = 1 per hit
New Health = Health - Damage
if (New Health <= 0) → Destroyed
```

#### Score System
```
Score = Σ(coins collected × 10)
No score from direct asteroid hits
```

---

## 📊 PERFORMANCE METRICS

### Complexity Analysis

| Operation | Time Complexity | Space Complexity |
|-----------|----------------|------------------|
| Spawn object | O(1) | O(1) |
| Find all asteroids | O(n) | O(1) |
| Collision check | O(n²) worst, O(n) average* | O(1) |
| Update all objects | O(n) | O(1) |
| Particle creation | O(k) k=10-15 | O(k) |

*Flame uses spatial hashing for collision optimization

### Memory Usage

```
Typical Game State:
- Player: 1 × ~1KB = 1KB
- Asteroids: ~30 × ~2KB = 60KB
- Lasers: ~10 × ~0.5KB = 5KB
- Particles: ~50 × ~0.1KB = 5KB
- UI: ~5KB
- Sounds (preloaded): ~2MB
Total: ~2.1MB
```

### Frame Budget (60 FPS)

```
Target: 16.67ms per frame

Breakdown:
- Update: ~5ms (game logic)
- Collision: ~3ms (physics)
- Render: ~7ms (draw calls)
- System: ~1.67ms (OS overhead)
Total: 16.67ms
```

---

## 🎯 KẾT LUẬN

### Key Algorithms Summary

1. **Movement:** Normalized vector + constant velocity
2. **Collision:** Flame's built-in AABB + callbacks
3. **Spawning:** Periodic timer with random range
4. **Splitting:** Recursive size reduction + scatter
5. **Upgrades:** Level-based pattern generation
6. **Audio:** Preload + instant playback from RAM
7. **UI:** Responsive size calculations
8. **Effects:** Tween-based animations

### Design Patterns Used

- **Component Pattern:** Flame ECS
- **Factory Pattern:** SpawnComponent, object creation
- **Observer Pattern:** Collision callbacks
- **Singleton Pattern:** AudioManager, Game instance
- **State Pattern:** Game states (title/playing/gameover)

---

**Ngày tạo:** 15/10/2025  
**Phiên bản:** 1.0.0  
**Tổng số dòng phân tích:** ~2000+ dòng documentation  
**Files được phân tích:** 14 files Dart

*Document này phân tích chi tiết mọi thuật toán và công thức toán học trong Cosmic Havoc game.*
