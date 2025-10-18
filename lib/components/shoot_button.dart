// ============================================
// 📦 IMPORT CÁC THƯ VIỆN CẦN THIẾT
// ============================================
import 'dart:async'; // Hỗ trợ async/await cho các hàm bất đồng bộ

import 'package:cosmic_havoc/my_game.dart'; // Truy cập game instance chính
import 'package:flame/components.dart'; // Các component cơ bản của Flame
import 'package:flame/events.dart'; // Xử lý sự kiện chạm (touch events)

class ShootButton extends SpriteComponent
    with
        HasGameReference<MyGame>, // Mixin để truy cập game instance
        TapCallbacks {
  ShootButton() : super(size: Vector2.all(80));

  @override
  FutureOr<void> onLoad() async {
    // ===== TẢI HÌNH ẢNH NÚT BẮN =====
    // Load sprite 'shoot_button.png' từ assets/images/
    sprite = await game.loadSprite('shoot_button.png'); // Load texture button

    return super.onLoad(); // Gọi hàm onLoad của class cha
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event); // Gọi hàm cha để xử lý event chuẩn

    // ===== BẮT ĐẦU BẮN LIÊN TỤC =====
    // Kích hoạt trạng thái bắn của player
    game.player.startShooting(); // Set player._isShooting = true
  }


  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event); // Gọi hàm cha

    // ===== DỪNG BẮN KHI NHẤC TAY =====
    // Deactivate trạng thái bắn của player
    game.player.stopShooting(); // Set player._isShooting = false

    // KẾT QUẢ:
    // - Laser spawning dừng ngay lập tức
    // - Player có thể tap lại để bắn tiếp
    // - No lasting effects, clean state
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    super.onTapCancel(event); // Gọi hàm cha

    // ===== DỪNG BẮN AN TOÀN KHI BỊ GIÁN ĐOẠN =====
    // Đảm bảo dừng bắn khi touch bị gián đoạn
    game.player.stopShooting(); // Set player._isShooting = false
  }
}

