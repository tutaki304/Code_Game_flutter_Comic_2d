# 📝 GHI CHÚ CODE CHI TIẾT - COSMIC HAVOC GAME

## 🎯 Mục đích file này
File này giải thích chi tiết cách hoạt động của từng dòng code trong game Cosmic Havoc, giúp bạn hiểu cách các component tương tác với nhau và logic xử lý của game.

---

## 📁 CẤU TRÚC CODE VÀ CHỨC NĂNG

### 1. **MAIN.DART** - Điểm khởi đầu ứng dụng

```dart
void main() {
  final MyGame game = MyGame();  // Tạo instance game chính
  
  runApp(GameWidget(             // Chạy Flutter app với Flame GameWidget
    game: game,                  // Truyền game vào
    overlayBuilderMap: {         // Map các UI overlay
      'GameOver': (context, MyGame game) => GameOverOverlay(game: game),
      'Title': (context, MyGame game) => TitleOverlay(game: game),
    },
    initialActiveOverlays: const ['Title'], // Overlay đầu tiên
  ));
}
```

**Giải thích flow:**
1. `main()` là entry point của Flutter app
2. Tạo `MyGame` instance - đây là core game engine
3. `GameWidget` là wrapper Flame để chạy game trong Flutter
4. `overlayBuilderMap` định nghĩa các UI screen phủ lên game
5. `initialActiveOverlays` chỉ định screen đầu tiên (Title)

---

### 2. **MY_GAME.DART** - Core game engine

#### **Khai báo class và variables:**
```dart
class MyGame extends FlameGame
    with HasKeyboardHandlerComponents, HasCollisionDetection {
  
  // Game objects
  late Player player;                    // Tàu người chơi
  late JoystickComponent joystick;       // Joystick ảo
  late SpawnComponent _asteroidSpawner;  // Bộ sinh asteroid
  late SpawnComponent _pickupSpawner;    // Bộ sinh power-ups
  
  // Game state
  int _score = 0;                        // Điểm số
  late TextComponent _scoreDisplay;      // UI hiển thị điểm
  
  // Settings
  final List<String> playerColors = ['blue', 'red', 'green', 'purple'];
  int playerColorIndex = 0;              // Màu tàu được chọn
}
```

**Giải thích:**
- `FlameGame` là base class chính của Flame engine
- `HasKeyboardHandlerComponents` cho phép xử lý keyboard input
- `HasCollisionDetection` bật hệ thống phát hiện va chạm
- `late` keyword = biến sẽ được init sau, không phải ngay lúc tạo object

#### **Hàm onLoad() - Khởi tạo game:**
```dart
@override
FutureOr<void> onLoad() async {
  await Flame.device.fullScreen();      // Bật fullscreen
  await Flame.device.setPortrait();     // Khóa chế độ dọc
  
  audioManager = AudioManager();        // Tạo audio manager
  await add(audioManager);              // Thêm vào game world
  audioManager.playMusic();             // Phát nhạc nền
  
  _createStars();                       // Tạo background stars
  
  return super.onLoad();
}
```

**Giải thích flow:**
1. `onLoad()` được gọi khi game khởi tạo
2. Setup device (fullscreen, portrait)
3. Khởi tạo audio system
4. Tạo visual elements (stars)
5. `super.onLoad()` gọi onLoad của class cha

#### **Hàm startGame() - Bắt đầu gameplay:**
```dart
void startGame() async {
  await _createJoystick();    // Tạo joystick điều khiển
  await _createPlayer();      // Tạo tàu player
  _createShootButton();       // Tạo nút bắn
  _createAsteroidSpawner();   // Tạo bộ sinh asteroid
  _createPickupSpawner();     // Tạo bộ sinh power-ups
  _createScoreDisplay();      // Tạo UI điểm số
}
```

**Giải thích:**
- Được gọi từ Title Overlay khi player nhấn Start
- Tạo tất cả game objects theo thứ tự
- `async/await` đảm bảo các object được tạo tuần tự

---

### 3. **PLAYER.DART** - Logic tàu người chơi

#### **Khai báo class:**
```dart
class Player extends SpriteAnimationComponent
    with HasGameReference<MyGame>, KeyboardHandler, CollisionCallbacks {
  
  // Shooting system
  bool _isShooting = false;          // Có đang bắn không?
  final double _fireCooldown = 0.2;  // Thời gian chờ giữa các phát (0.2s)
  double _elapsedFireTime = 0.0;     // Thời gian đã trôi qua
  
  // Movement
  final Vector2 _keyboardMovement = Vector2.zero(); // Vector di chuyển
  
  // State
  bool _isDestroyed = false;         // Tàu có bị phá hủy không?
  Shield? activeShield;              // Khiên bảo vệ (null = không có)
}
```

**Giải thích:**
- `SpriteAnimationComponent` = component có sprite với animation
- `HasGameReference<MyGame>` = có thể truy cập game instance qua `game`
- `KeyboardHandler` = xử lý input từ bàn phím
- `CollisionCallbacks` = xử lý khi va chạm với objects khác

#### **Hệ thống bắn súng với Cooldown:**
```dart
// Trong Player.update() - Logic cooldown tự động
@override
void update(double dt) {
  super.update(dt);
  
  // Cập nhật timer cooldown
  _elapsedFireTime += dt;
  
  // Bắn laser nếu đang nhấn Space và đủ cooldown
  if (_isShooting && _elapsedFireTime >= _fireCooldown) {
    _fireLaser();       // Gọi hàm bắn
    _elapsedFireTime = 0.0; // Reset timer
  }
}

// Hàm bắn laser thực sự
void _fireLaser() {
  game.audioManager.playSound('laser');  // Phát sound effect
  
  // Tạo laser chính ở giữa
  game.add(Laser(position: position.clone() + Vector2(0, -size.y / 2)));
  
  // Nếu có laser power-up, bắn thêm 2 laser chéo
  if (_laserPowerupTimer.isRunning()) {
    game.add(Laser(
      position: position.clone() + Vector2(0, -size.y / 2),
      angle: 15 * degrees2Radians,  // Laser chéo phải
    ));
    game.add(Laser(
      position: position.clone() + Vector2(0, -size.y / 2),
      angle: -15 * degrees2Radians, // Laser chéo trái
    ));
  }
}
```

**Giải thích logic bắn súng mới:**
1. **Input handling:** Space key set `_isShooting = true`
2. **Cooldown system:** `update()` kiểm tra timer mỗi frame
3. **Auto fire:** Khi giữ Space, tự động bắn với tần suất 0.2s/phát
4. **Power-up system:** Laser power-up bắn 3 tia cùng lúc
5. **Position calculation:** Laser xuất phát từ đầu tàu (`-size.y / 2`)

#### **Hệ thống di chuyển:**
```dart
@override
void update(double dt) {
  super.update(dt);
  
  // Cập nhật timer
  _elapsedFireTime += dt;
  
  // Di chuyển theo joystick
  if (game.joystick.direction != JoystickDirection.idle) {
    position += game.joystick.relativeDelta * 300 * dt;
  }
  
  // Di chuyển theo keyboard
  position += _keyboardMovement * 300 * dt;
  
  // Giữ player trong màn hình
  position.x = position.x.clamp(size.x / 2, game.size.x - size.x / 2);
  position.y = position.y.clamp(size.y / 2, game.size.y - size.y / 2);
}
```

**Giải thích:**
- `update()` được gọi mỗi frame (~60fps)
- `dt` = delta time = thời gian từ frame trước (giây)
- Joystick movement: `relativeDelta` * speed * dt
- `clamp()` giới hạn vị trí trong boundaries màn hình

---

### 4. **ASTEROID.DART** - Logic thiên thạch

#### **Khởi tạo asteroid:**
```dart
Asteroid({required super.position, double size = _maxSize})
    : super(
        size: Vector2.all(size),      // Kích thước vuông
        anchor: Anchor.center,        // Neo ở giữa
        priority: -1,                 // Vẽ sau player (dưới layer)
      ) {
  _velocity = _generateVelocity();    // Tạo vận tốc ngẫu nhiên
  _spinSpeed = _random.nextDouble() * 1.5 - 0.75; // Tốc độ quay
  _health = size / _maxSize * _maxHealth;          // Máu = tỉ lệ kích thước
  
  add(CircleHitbox(collisionType: CollisionType.passive)); // Hitbox tròn
}
```

**Giải thích:**
- Constructor nhận vị trí và kích thước
- `priority: -1` = vẽ trước player (background layer)
- Vận tốc và spin được tạo ngẫu nhiên
- Máu tính theo tỉ lệ kích thước (asteroid lớn = máu nhiều)
- `CircleHitbox` cho va chạm hình tròn

#### **Update movement:**
```dart
@override
void update(double dt) {
  super.update(dt);
  
  position += _velocity * dt;         // Di chuyển theo vận tốc
  angle += _spinSpeed * dt;          // Quay theo spin speed
  
  // Xóa khi ra khỏi màn hình
  if (position.y > game.size.y + size.y) {
    removeFromParent();
  }
}
```

**Giải thích:**
- Di chuyển = position cũ + (vận tốc × thời gian)
- Quay = góc cũ + (tốc độ quay × thời gian)
- Tự xóa khi ra khỏi màn hình (tối ưu performance)

---

### 5. **AUDIO_MANAGER.DART** - Quản lý âm thanh

```dart
class AudioManager extends Component {
  bool musicEnabled = true;   // Setting nhạc nền
  bool soundsEnabled = true;  // Setting sound effects
  
  void playMusic() {
    if (musicEnabled) {
      FlameAudio.bgm.play('music.ogg');  // Phát nhạc nền loop
    }
  }
  
  void playSound(String sound) {
    if (soundsEnabled) {
      FlameAudio.play('$sound.ogg');     // Phát sound effect 1 lần
    }
  }
}
```

**Giải thích:**
- `FlameAudio.bgm` cho background music (loop tự động)
- `FlameAudio.play()` cho sound effects (phát 1 lần)
- Settings cho phép bật/tắt từ UI

---

### 6. **TITLE_OVERLAY.DART** - Màn hình chính

#### **Animation system:**
```dart
class _TitleOverlayState extends State<TitleOverlay> {
  double _opacity = 0.0;  // Độ mờ ban đầu = 0 (trong suốt)
  
  @override
  void initState() {
    super.initState();
    
    // Tạo hiệu ứng fade-in
    Future.delayed(Duration.zero, () {
      setState(() {
        _opacity = 1.0;  // Thay đổi thành 1.0 (hiện đầy đủ)
      });
    });
  }
}
```

**Giải thích:**
- `setState()` trigger rebuild widget với opacity mới
- `AnimatedOpacity` tự động tạo smooth transition
- `Future.delayed(Duration.zero)` = chạy sau build cycle hiện tại

#### **Game control:**
```dart
// Nút Start Game
ElevatedButton(
  onPressed: () {
    setState(() {
      _opacity = 0.0;  // Fade-out overlay
    });
    
    // Sau khi fade-out xong, start game
    Future.delayed(Duration(milliseconds: 500), () {
      widget.game.startGame();
    });
  },
  child: Text('START GAME'),
)
```

**Giải thích flow:**
1. Player nhấn nút Start
2. Trigger fade-out animation (opacity → 0)
3. Sau 500ms, gọi `game.startGame()`
4. `AnimatedOpacity.onEnd` tự động remove overlay

---

## 🔄 GAME LOOP VÀ COMPONENT LIFECYCLE

### **Game Loop Flow:**
```
1. main() → Tạo MyGame → Hiển thị Title Overlay
2. Player nhấn Start → startGame() → Tạo tất cả components
3. Mỗi frame (~60fps):
   - Flame gọi update() cho tất cả components
   - Flame gọi render() để vẽ lên màn hình
   - Kiểm tra va chạm giữa các objects
   - Xử lý input (joystick, keyboard, touch)
4. Khi player chết → Hiển thị GameOver Overlay
5. Player chọn Restart → Quay lại bước 2
```

### **Component Lifecycle:**
```
1. Constructor → Khởi tạo variables
2. onLoad() → Load sprites, setup hitboxes
3. onMount() → Component được thêm vào game tree
4. update(dt) → Được gọi mỗi frame
5. render(canvas) → Vẽ lên màn hình
6. onRemove() → Component bị xóa khỏi game
```

---

## 🎮 HỆ THỐNG INPUT VÀ CONTROL

### **Joystick System:**
```dart
// Trong MyGame.update()
if (joystick.direction != JoystickDirection.idle) {
  final delta = joystick.relativeDelta;  // Vector từ -1 đến 1
  player.position += delta * playerSpeed * dt;
}
```

### **Keyboard System - WASD + Mũi tên + Space:**
```dart
// Trong Player.onKeyEvent() - Hỗ trợ WASD và mũi tên để di chuyển, Space để bắn
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
    _isShooting = true;  // Set trạng thái bắn, logic cooldown xử lý trong update()
  } else {
    _isShooting = false; // Ngừng bắn khi thả phím
  }

  return true; // Đã xử lý input
}
```

**Giải thích Keyboard Controls:**
- **WASD hoặc Mũi tên:** Di chuyển tàu theo 4 hướng
- **Space:** Bắn laser liên tục (với cooldown 0.2s)
- **Logic shooting:** Chỉ set `_isShooting = true`, hàm `update()` tự động xử lý cooldown
- **Vector movement:** Cho phép di chuyển chéo (ví dụ: W+D = lên phải)

---

## ⚡ HỆ THỐNG VA CHẠM (COLLISION)

### **Setup Hitboxes:**
```dart
// Trong Player.onLoad()
add(RectangleHitbox.relative(
  Vector2(0.6, 0.9),        // 60% width, 90% height
  parentSize: size,         // Relative to sprite size
  anchor: Anchor.center,    // Neo ở giữa
));

// Trong Asteroid.constructor
add(CircleHitbox(
  collisionType: CollisionType.passive  // Không di chuyển khi va chạm
));
```

### **Collision Callbacks:**
```dart
// Trong Player class
@override
bool onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
  if (other is Asteroid) {
    // Xử lý va chạm với asteroid
    takeDamage();
    return false;  // Không block collision
  }
  
  if (other is Pickup) {
    // Thu thập power-up
    collectPowerup(other);
    return false;
  }
  
  return true;
}
```

---

## 🎯 TIPS ĐỌC VÀ HIỂU CODE

### **1. Flame Component System:**
- Mỗi object trong game là 1 Component
- Components có lifecycle: onLoad → onMount → update → render → onRemove
- Components có thể chứa Components con (tree structure)

### **2. Coordinate System:**
- (0,0) = góc trên trái màn hình
- X tăng về phía phải
- Y tăng xuống dưới
- `anchor` xác định điểm neo của sprite

### **3. Delta Time (dt):**
- dt = thời gian từ frame trước (thường ~0.016s với 60fps)
- Dùng dt để movement độc lập với framerate
- `position += velocity * dt` đảm bảo speed nhất quán

### **4. Async/Await Pattern:**
- `onLoad()` thường async vì cần load assets
- `await` đảm bảo chờ operation hoàn thành
- `Future.delayed()` để tạo timer

### **5. State Management:**
- Game state lưu trong MyGame class
- UI state lưu trong StatefulWidget
- Communication qua game reference

---

## 🎮 TÓM TẮT CONTROLS - HƯỚNG DẪN CHƠI

### **🎯 Điều khiển di chuyển:**
| Phím | Chức năng | Ghi chú |
|------|-----------|---------|
| **W** hoặc **↑** | Di chuyển lên | Y -= 1 |
| **S** hoặc **↓** | Di chuyển xuống | Y += 1 |
| **A** hoặc **←** | Di chuyển trái | X -= 1 |
| **D** hoặc **→** | Di chuyển phải | X += 1 |

### **🔫 Điều khiển bắn súng:**
| Phím | Chức năng | Cooldown |
|------|-----------|----------|
| **Space** | Bắn laser | 0.2 giây/phát |

### **� Điều khiển touch (Mobile):**
| Control | Chức năng | Vị trí |
|---------|-----------|--------|
| **Joystick** | Di chuyển tàu | Góc trái dưới |
| **Shoot Button** | Bắn laser | Góc phải dưới |

### **🎮 Gameplay Tips:**
- **Di chuyển chéo:** Có thể nhấn 2 phím cùng lúc (VD: W+D = di chuyển lên phải)
- **Bắn liên tục:** Giữ Space để bắn tự động với cooldown
- **Power-ups:** Thu thập để tăng sức mạnh:
  - 🔴 **Laser Power-up:** Bắn 3 tia cùng lúc (10 giây)
  - 💣 **Bomb Power-up:** Vũ khí diện rộng
  - 🛡️ **Shield Power-up:** Bảo vệ khỏi va chạm
- **Boundaries:** Tàu không thể ra khỏi màn hình
- **Scoring:** Phá hủy asteroid để ghi điểm

### **⚙️ Technical Notes:**
- **Frame rate:** ~60 FPS
- **Movement speed:** 200 pixels/giây
- **Fire rate:** 5 phát/giây (0.2s cooldown)
- **Input system:** Hỗ trợ đồng thời keyboard + touch
- **Platform:** Windows, Android, iOS, Web

---

*�📅 Cập nhật: 04/10/2025*
*🎯 Mục đích: Giúp hiểu chi tiết cách code hoạt động và controls*
*🆕 Thêm: Hệ thống điều khiển WASD + Space*