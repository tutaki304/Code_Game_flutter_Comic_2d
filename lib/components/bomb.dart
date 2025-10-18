// ============================================
// 📦 IMPORT CÁC THƯ VIỆN CẦN THIẾT
// ============================================
import 'dart:async'; // Hỗ trợ async/await cho các hàm bất đồng bộ

import 'package:cosmic_havoc/components/asteroid.dart'; // Thiên thạch - mục tiêu của bomb
import 'package:cosmic_havoc/my_game.dart'; // Truy cập game instance chính
import 'package:flame/collisions.dart'; // Hệ thống phát hiện va chạm của Flame
import 'package:flame/components.dart'; // Các component cơ bản của Flame
import 'package:flame/effects.dart'; // Hiệu ứng animation (scale, fade, etc.)
import 'package:flutter/widgets.dart'; // Curves để tạo animation mượt mà

/// ============================================
/// 💣 CLASS BOMB - VŨ KHÍ QUÉT SẠCH MÀN HÌNH
/// ============================================
/// 
/// 📝 MỤC ĐÍCH:
/// Bomb là vũ khí đặc biệt với phạm vi tấn công rộng (AOE - Area of Effect).
/// Khi kích hoạt, bomb sẽ mở rộng thành vòng tròn khổng lồ và phá hủy
/// tất cả thiên thạch trong phạm vi bùng nổ.
/// 
/// 🎮 CHỨC NĂNG CHÍNH:
/// - Vũ khí phạm vi rộng (AOE weapon)
/// - Gây sát thương cho TẤT CẢ thiên thạch trong vòng nổ
/// - Hiệu ứng visual: Mở rộng từ 1px → 800px trong 1 giây
/// - Tự động biến mất sau khi hoàn thành
/// 
/// 🎆 TRÌNH TỰ HOẠT ĐỘNG:
/// 1. Xuất hiện tại vị trí player (kích thước 1px - gần như vô hình)
/// 2. Mở rộng dần đến 800px trong 1.0 giây (phủ gần hết màn hình)
/// 3. Trong lúc mở rộng: Va chạm và phá hủy tất cả asteroid
/// 4. Fade out (mờ dần) trong 0.5 giây
/// 5. Tự động xóa khỏi game (dọn dẹp bộ nhớ)
/// 
/// 🎯 CƠ CHẾ VA CHẠM:
/// - Phát hiện va chạm liên tục trong quá trình mở rộng
/// - Có thể đánh nhiều asteroid cùng lúc
/// - Mỗi asteroid bị trúng sẽ gọi takeDamage()
/// - KHÔNG va chạm với Player (không bị thương đồng đội)
/// 
/// 🔊 TÍCH HỢP ÂM THANH:
/// - Phát âm thanh 'fire' khi triển khai bomb
/// - Phản hồi âm thanh tức thì khi bomb được kích hoạt
/// 
/// 🎮 CÁCH SỬ DỤNG:
/// - Được kích hoạt bởi Player khi nhặt bomb pickup
/// - Vũ khí khẩn cấp để xóa sạch màn hình
/// - Timing quan trọng để đạt hiệu quả tối đa
/// 
/// 💡 CHIẾN THUẬT:
/// - Dùng khi màn hình quá đông asteroid
/// - Vũ khí cứu sinh trong tình huống nguy hiểm
/// - Nguồn lực hiếm (chỉ có từ pickup) nên dùng khôn ngoan
class Bomb extends SpriteComponent
    with
        HasGameReference<MyGame>, // Mixin để truy cập game instance
        CollisionCallbacks {
  // Mixin để xử lý các sự kiện va chạm

  // ============================================
  // 🏗️ CONSTRUCTOR - HÀM KHỞI TẠO
  // ============================================

  /**
   * Bomb({required position})
   * 
   * Tạo một quả bomb mới tại vị trí chỉ định
   * 
   * THAM SỐ:
   * @param position (required) - Vị trí triển khai (thường là vị trí player)
   * 
   * CẤU HÌNH BAN ĐẦU:
   * - size: Vector2.all(1) - Bắt đầu rất nhỏ (1x1 pixel)
   * - anchor: Anchor.center - Neo ở giữa để mở rộng đều từ tâm
   * - priority: -1 - Layer thấp hơn player nhưng cao hơn background
   * 
   * LÝ DO SIZE = 1px:
   * - Tạo hiệu ứng bất ngờ (xuất hiện từ không gian)
   * - Mở rộng từ nhỏ → lớn mượt mà hơn
   * - Không che khuất visual ngay khi spawn
   */
  Bomb({required super.position})
      : super(
          size: Vector2.all(1), // Bắt đầu với kích thước cực nhỏ (sẽ mở rộng)
          anchor: Anchor.center, // Mở rộng từ tâm ra (đồng đều mọi hướng)
          priority: -1, // Hiển thị phía sau player, trước background
        );

  // ============================================
  // 🔄 KHỞI TẠO & ANIMATION
  // ============================================

  /**
   * onLoad() - Khởi tạo bomb với chuỗi animation hoàn chỉnh
   * 
   * NHIỆM VỤ:
   * 1. Phát âm thanh triển khai
   * 2. Load hình ảnh bomb từ assets
   * 3. Thiết lập hệ thống va chạm
   * 4. Bắt đầu chuỗi animation tự động
   * 
   * CHUỖI ANIMATION (SequenceEffect):
   * Các hiệu ứng chạy tuần tự, tự động chuyển tiếp:
   * 
   * ┌─────────────────────────────────────────────────────┐
   * │ Phase 1: MỞ RỘNG (1.0 giây)                         │
   * │ - Kích thước: 1px → 800px                           │
   * │ - Curve: easeInOut (mượt mà)                        │
   * │ - Va chạm với asteroid trong lúc này                │
   * └─────────────────────────────────────────────────────┘
   *                      ↓
   * ┌─────────────────────────────────────────────────────┐
   * │ Phase 2: MỜ DẦN (0.5 giây)                          │
   * │ - Opacity: 1.0 → 0.0                                │
   * │ - Bomb vẫn còn nhưng trong suốt                     │
   * └─────────────────────────────────────────────────────┘
   *                      ↓
   * ┌─────────────────────────────────────────────────────┐
   * │ Phase 3: TỰ HỦY (tức thì)                           │
   * │ - RemoveEffect: Xóa khỏi game tree                  │
   * │ - Giải phóng bộ nhớ                                 │
   * └─────────────────────────────────────────────────────┘
   * 
   * TOÁN HỌC MỞ RỘNG:
   * - Size ban đầu: 1x1 pixel
   * - Size cuối: 800x800 pixel (phủ ~70% màn hình phone)
   * - Tỷ lệ tăng: x800 lần
   * - Tốc độ tăng trung bình: 800px / 1.0s = 800 px/s
   * 
   * CURVE easeInOut:
   * - Bắt đầu chậm (ease in)
   * - Nhanh ở giữa
   * - Chậm lại khi kết thúc (ease out)
   * - Tạo cảm giác tự nhiên, không giật cục
   */
  @override
  FutureOr<void> onLoad() async {
    // ===== BƯỚC 1: PHÁT ÂM THANH =====
    // Phát âm thanh 'fire' ngay lập tức để feedback cho player
    game.audioManager.playSound('fire'); // Âm thanh triển khai bomb

    // ===== BƯỚC 2: TẢI HÌNH ẢNH =====
    // Load sprite bomb.png từ assets/images/
    sprite = await game.loadSprite('bomb.png'); // Load texture bomb

    // ===== BƯỚC 3: THIẾT LẬP VA CHẠM =====
    // Thêm CircleHitbox - hộp va chạm hình tròn
    // isSolid: true → Phát hiện va chạm liên tục (không xuyên qua)
    // Hitbox sẽ tự động scale theo size của sprite
    add(CircleHitbox(isSolid: true)); // Va chạm hình tròn, solid

    // ===== BƯỚC 4: BẮT ĐẦU CHUỖI ANIMATION =====
    // SequenceEffect: Chạy các effect tuần tự, tự động chuyển tiếp
    add(SequenceEffect([
      // ╔═══════════════════════════════════════════╗
      // ║ PHASE 1: HIỆU ỨNG MỞ RỘNG                ║
      // ╚═══════════════════════════════════════════╝
      SizeEffect.to(
        Vector2.all(800), // Mục tiêu: Mở rộng đến 800x800 pixels
        // 800px đủ lớn để phủ phần lớn màn hình phone
        // (Màn hình phone thường ~360-400px chiều rộng)

        EffectController(
          duration: 1.0, // Thời gian mở rộng: 1.0 giây
          // Đủ chậm để player nhìn thấy hiệu ứng
          // Đủ nhanh để không làm game bị chậm

          curve: Curves.easeInOut, // Đường cong animation
          // easeInOut: Bắt đầu chậm → Nhanh ở giữa → Chậm lại cuối
          // Tạo chuyển động mượt mà, tự nhiên
        ),
      ),

      // ╔═══════════════════════════════════════════╗
      // ║ PHASE 2: HIỆU ỨNG MỜ DẦN                 ║
      // ╚═══════════════════════════════════════════╝
      OpacityEffect.fadeOut(
        // fadeOut: Giảm opacity từ 1.0 (đục) → 0.0 (trong suốt)
        EffectController(duration: 0.5), // 0.5 giây fade
        // Nhanh gọn, không làm rối mắt player
      ),

      // ╔═══════════════════════════════════════════╗
      // ║ PHASE 3: TỰ ĐỘNG XÓA                     ║
      // ╚═══════════════════════════════════════════╝
      RemoveEffect(), // Tự động xóa khỏi game tree
      // Giải phóng bộ nhớ, không để lại object rác
      // Flame engine sẽ tự động cleanup
    ]));

    return super.onLoad(); // Gọi hàm onLoad của class cha
  }

  // ============================================
  // 💥 XỬ LÝ VA CHẠM
  // ============================================

  /**
   * onCollision() - Xử lý va chạm với các object khác
   * 
   * THAM SỐ:
   * @param intersectionPoints - Các điểm giao nhau của va chạm
   * @param other - Component khác đang va chạm với bomb
   * 
   * LOGIC XỬ LÝ:
   * 1. Kiểm tra xem object va chạm có phải là Asteroid không
   * 2. Nếu đúng là Asteroid:
   *    - Gọi other.takeDamage() để gây sát thương
   *    - Asteroid sẽ tự xử lý health, effects, split, etc.
   * 3. Nếu không phải Asteroid: Bỏ qua (không làm gì)
   * 
   * CÁC TRƯỜNG HỢP VA CHẠM:
   * - Bomb vs Asteroid: ✅ Xử lý (gây damage)
   * - Bomb vs Player: ❌ Không xảy ra (không friendly fire)
   * - Bomb vs Pickup: ❌ Không xử lý (không tương tác)
   * - Bomb vs Laser: ❌ Không xử lý (không conflict)
   * - Bomb vs Bomb: ❌ Không xử lý (bombs không đánh nhau)
   * 
   * CƠ CHẾ VA CHẠM LIÊN TỤC:
   * - CircleHitbox.isSolid = true → Collision continuous
   * - Khi bomb mở rộng, hitbox cũng mở rộng theo
   * - Asteroid mới chạm vào → Bị takeDamage() ngay
   * - Mỗi asteroid chỉ bị hit 1 lần (do takeDamage logic)
   * 
   * VÍ DỤ TIMELINE:
   * t=0.0s: Bomb size 1px, chưa hit asteroid nào
   * t=0.3s: Bomb size 240px, hit 2 asteroids gần
   * t=0.6s: Bomb size 480px, hit thêm 5 asteroids
   * t=1.0s: Bomb size 800px, hit tất cả asteroids trên màn hình
   * 
   * HIỆU QUẢ TỐI ĐA:
   * - Có thể phá hủy 10-20 asteroids trong một lần nổ
   * - Đặc biệt hiệu quả khi màn hình đông đúc
   * - Emergency weapon cho tình huống nguy hiểm
   */
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other); // Gọi hàm cha

    // ===== KIỂM TRA LOẠI OBJECT =====
    if (other is Asteroid) {
      // Đây là thiên thạch! Xử lý va chạm:

      // GÂY SÁT THƯƠNG
      other.takeDamage(); // Asteroid tự xử lý:
      // - Giảm health
      // - Hiệu ứng flash màu trắng
      // - Âm thanh hit
      // - Tách nhỏ nếu còn health
      // - Drop coin nếu là mảnh nhỏ nhất
      // - Explosion effect khi chết

      // CHÚ Ý: Bomb KHÔNG tự hủy sau khi hit
      // Khác với Laser (tự hủy sau 1 hit)
      // Bomb tiếp tục mở rộng và hit nhiều asteroids
    }

    // Chú ý: Không xử lý va chạm với các object khác
    // Player, Pickup, Shield, Laser, Bomb sẽ được bỏ qua
  }
}

