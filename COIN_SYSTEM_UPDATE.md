# 💰 COIN SYSTEM UPDATE - Cosmic Havoc

## 📋 Tổng quan thay đổi

Đã thay đổi cơ chế game từ **tăng điểm trực tiếp khi bắn asteroid** sang **thu thập coin rơi ra từ asteroid3**.

## 🎮 Cơ chế mới

### Trước đây:
- ❌ Bắn trúng asteroid: +1 điểm
- ❌ Phá hủy asteroid: +2 điểm
- ❌ Thu pickup bất kỳ: +1 điểm

### Bây giờ:
- ✅ Bắn trúng asteroid: **Không tăng điểm**
- ✅ Phá hủy asteroid3.png: **Rơi ra coin 💰**
- ✅ Thu thập coin: **+10 điểm**
- ✅ Thu pickup khác (laser/bomb/shield): **Không tăng điểm, chỉ có power-up**

## 📝 Chi tiết thay đổi

### 1. **pickup.dart** - Thêm PickupType mới
```dart
enum PickupType { bomb, laser, shield, coin }
```
- Thêm `coin` vào danh sách pickup types

### 2. **asteroid.dart** - Logic spawn coin

#### a) Thêm import và biến
```dart
import 'package:cosmic_havoc/components/pickup.dart';
late String _spriteName; // Lưu tên sprite để nhận diện asteroid type
```

#### b) Lưu sprite name khi load
```dart
@override
FutureOr<void> onLoad() async {
  final int imageNum = _random.nextInt(3) + 1;
  _spriteName = 'asteroid$imageNum.png'; // Lưu tên
  sprite = await game.loadSprite(_spriteName);
  return super.onLoad();
}
```

#### c) Spawn coin thay vì tăng điểm
```dart
void takeDamage() {
  game.audioManager.playSound('hit');
  _health--;

  if (_health <= 0) {
    // Spawn coin nếu là asteroid3
    if (_spriteName == 'asteroid3.png') {
      _spawnCoin();
    }
    removeFromParent();
    _createExplosion();
    _splitAsteroid();
  } else {
    // Không tăng điểm khi hit nữa
    _flashWhite();
    _applyKnockback();
  }
}

void _spawnCoin() {
  final Pickup coin = Pickup(
    position: position.clone(),
    pickupType: PickupType.coin,
  );
  game.add(coin);
}
```

### 3. **player.dart** - Xử lý thu thập coin

```dart
else if (other is Pickup) {
  game.audioManager.playSound('collect');
  other.removeFromParent();
  
  // Chỉ tăng điểm khi thu coin
  if (other.pickupType == PickupType.coin) {
    game.incrementScore(10); // Coin = 10 điểm
  }

  switch (other.pickupType) {
    case PickupType.laser:
      _upgradeLaserLevel();
      break;
    case PickupType.bomb:
      game.add(Bomb(position: position.clone()));
      break;
    case PickupType.shield:
      // ... shield logic
      break;
    case PickupType.coin:
      // Đã tăng điểm ở trên
      break;
  }
}
```

## 🎯 Gameplay Impact

### Balance mới:
1. **Asteroid1 & Asteroid2**: Không rơi coin → Chỉ là chướng ngại vật
2. **Asteroid3**: Rơi coin → Target ưu tiên để kiếm điểm
3. **Coin value**: 10 điểm/coin → Khuyến khích thu thập
4. **Power-ups**: Không còn cho điểm → Focus vào utility

### Chiến thuật mới:
- 🎯 **Ưu tiên bắn asteroid3** để spawn coin
- 💰 **Thu thập coin** là nguồn điểm chính
- 🎮 **Power-ups** giờ là lựa chọn chiến thuật thay vì điểm bonus
- ⚡ **Risk vs Reward**: Di chuyển để thu coin trong khi tránh asteroid

## 🖼️ Assets

File `coin_pickup.png` đã tồn tại trong `assets/images/`

## ✅ Testing Checklist

- [x] Code compile không lỗi
- [ ] Test game chạy
- [ ] Bắn asteroid1 → không rơi coin ✓
- [ ] Bắn asteroid2 → không rơi coin ✓
- [ ] Bắn asteroid3 → rơi coin ✓
- [ ] Thu coin → +10 điểm ✓
- [ ] Thu laser/bomb/shield → không tăng điểm ✓
- [ ] Coin animation hoạt động (pulsating effect)
- [ ] Coin rơi xuống và tự xóa nếu không thu được

## 🚀 Cách test

```bash
flutter run
```

**Gameplay test:**
1. Chơi game và bắn các asteroid
2. Quan sát chỉ asteroid3 rơi coin
3. Thu thập coin và kiểm tra điểm tăng +10
4. Thu power-ups và xác nhận không tăng điểm

## 📊 Expected Results

| Hành động | Điểm | Ghi chú |
|-----------|------|---------|
| Bắn trúng asteroid | 0 | Không còn tăng điểm |
| Phá hủy asteroid1/2 | 0 | Không rơi coin |
| Phá hủy asteroid3 | 0 | Rơi coin thay vì điểm |
| Thu coin | +10 | Nguồn điểm chính |
| Thu laser pickup | 0 | Chỉ upgrade laser |
| Thu bomb pickup | 0 | Chỉ nhận bomb |
| Thu shield pickup | 0 | Chỉ nhận shield |

## 🔧 Rollback Instructions

Nếu cần quay lại cơ chế cũ:
1. Restore `asteroid.dart` - xóa `_spawnCoin()`, restore `game.incrementScore()`
2. Restore `player.dart` - restore `game.incrementScore(1)` cho tất cả pickups
3. Restore `pickup.dart` - xóa `coin` từ enum

---

**Author**: AI Assistant  
**Date**: October 14, 2025  
**Version**: 1.0.0  
**Status**: ✅ Ready for testing
