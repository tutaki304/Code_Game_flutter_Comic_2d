import 'dart:async'; // Hỗ trợ Async/await
import 'package:cosmic_havoc/my_game.dart'; // Truy cập game instance
import 'package:flame/collisions.dart'; // Hệ thống va chạm
import 'package:flame/components.dart'; // Flame components
import 'package:flame/effects.dart'; // Hiệu ứng animation
import 'package:flutter/widgets.dart'; // Curves cho animations

/**
 * ===============================================
 * 🎁 PICKUP TYPE - Các loại vật phẩm
 * ===============================================
 * 
 * LOẠI VẬT PHẨM:
 * - bomb: Bom xóa sạch màn hình
 * - laser: Nâng cấp laser (+1 level, tối đa 10)
 * - shield: Khiên bảo vệ tạm thời
 * - coin: Đồng xu rơi từ asteroid3 (tăng điểm)
 * 
 * 📝 LUU Ý QUAN TRỌNG:
 * - Coin CHỈ rơi từ asteroid3.png khi bị phá hủy
 * - Các power-up khác (bomb/laser/shield) spawn ngẫu nhiên
 * - Mỗi loại có sprite riêng: {type}_pickup.png
 */
enum PickupType { bomb, laser, shield, coin }

/**
 * ===============================================
 * 🎁 CLASS PICKUP - Vật phẩm thu thập
 * ===============================================
 * 
 * � CHỨC NĂNG CHÍNH:
 * - Vật phẩm rơi xuống từ trên cao với tốc độ 300 px/s
 * - Player va chạm để thu thập và nhận hiệu ứng
 * - Hiệu ứng visual: Animation phình to/nhỏ liên tục
 * - Tự động xóa khi ra khỏi màn hình (bottom edge)
 * 
 * 🎮 HIỆU ỨNG CÁC LOẠI PICKUP:
 * - BOMB: Tạo bom xóa sạch các asteroid trên màn hình
 * - LASER: Tăng level laser lên 1 bậc (tối đa level 10)
 * - SHIELD: Kích hoạt khiên bảo vệ tạm thời
 * - COIN: Tăng 10 điểm khi thu thập (chỉ rơi từ asteroid3)
 * 
 * 📏 KÍCH THƯỚC:
 * - Power-ups (bomb/laser/shield): 100x100 pixels
 * - Coin: 40x40 pixels (nhỏ hơn để phân biệt)
 * 
 * 🎨 THIẾT KẾ VISUAL:
 * - Mỗi loại có sprite riêng: bomb_pickup.png, laser_pickup.png, etc.
 * - Hiệu ứng phình to nhỏ: Scale 1.0 ↔ 0.9 (lặp vô hạn)
 * - Animation thu hút sự chú ý của người chơi
 * 
 * 🔄 CHU TRÌNH SỐNG:
 * 1. Spawn tại vị trí ngẫu nhiên hoặc từ asteroid bị phá hủy
 * 2. Rơi xuống với tốc độ 300 px/s
 * 3. Player thu thập hoặc rơi ra khỏi màn hình
 * 4. Tự động cleanup để tiết kiệm bộ nhớ
 * 
 * 💫 CƠ CHẾ THU THẬP:
 * - Va chạm với Player kích hoạt hiệu ứng
 * - Xóa ngay khỏi game sau khi thu thập
 * - Phát âm thanh 'collect' để phản hồi
 * - Tăng điểm (chỉ với coin: +10 điểm)
 * 
 * 📝 GHI CHÚ QUAN TRỌNG:
 * - Coin CHỈ spawn từ asteroid3.png khi bị phá hủy
 * - Power-ups khác spawn ngẫu nhiên từ PickupSpawner
 * - Không tăng điểm khi thu power-ups (chỉ coin mới tăng điểm)
 */
class Pickup extends SpriteComponent with HasGameReference<MyGame> {
  // ===============================================
  // 🎁 THUỘC TÍNH PICKUP
  // ===============================================

  final PickupType pickupType; // Loại power-up (bomb/laser/shield/coin)

  // ===============================================
  // 🏗️ CONSTRUCTOR - Hàm khởi tạo
  // ===============================================

  /**
   * Pickup Constructor - Tạo vật phẩm tại vị trí chỉ định
   * 
   * @param position - Vị trí spawn (từ PickupSpawner hoặc asteroid)
   * @param pickupType - Loại vật phẩm (bomb/laser/shield/coin)
   * 
   * KÍCH THƯỚC MẶC ĐỊNH:
   * - Power-ups (bomb/laser/shield): 100x100 pixels
   * - Coin: 40x40 pixels (nhỏ hơn để dễ phân biệt)
   * 
   * 📝 LƯU Ý:
   * - Anchor ở center để va chạm chính xác
   * - Size coin nhỏ hơn vì chỉ để lấy điểm, không phải power-up quan trọng
   * - Có thể điều chỉnh số 40 (coin size) theo ý muốn
   */
  Pickup({required super.position, required this.pickupType})
      : super(
          size: pickupType == PickupType.coin
              ? Vector2.all(40) // 🪙 COIN: 40x40 pixels (nhỏ gọn)
              : Vector2.all(100), // 🎁 POWER-UPS: 100x100 pixels
          anchor: Anchor.center, // Neo ở giữa
        );

  // ===============================================
  // 🔄 KHỞI TẠO & ANIMATION
  // ===============================================

  /**
   * onLoad() - Khởi tạo sprite và animation phình to/nhỏ
   * 
   * CHU TRÌNH SETUP:
   * 1. Load sprite phù hợp dựa trên loại pickup
   * 2. Thêm circular collision hitbox
   * 3. Bắt đầu animation phình to/nhỏ vô hạn
   * 
   * QUY TẮC ĐẶT TÊN SPRITE: "{loại}_pickup.png"
   * - bomb_pickup.png (bom)
   * - laser_pickup.png (laser)
   * - shield_pickup.png (khiên)
   * - coin_pickup.png (đồng xu)
   * 
   * 📝 LƯU Ý:
   * - Sprite tự động load dựa vào pickupType.name
   * - Animation giúp thu hút sự chú ý người chơi
   */
  @override
  FutureOr<void> onLoad() async {
    // ===== LOAD SPRITE =====
    sprite = await game
        .loadSprite('${pickupType.name}_pickup.png'); // Load sprite động

    // ===== THIẾT LẬP VA CHẠM =====
    add(CircleHitbox()); // Vùng va chạm hình tròn

    // ===== HIỆU ỨNG PHÌNH TO NHỎ =====
    final ScaleEffect pulsatingEffect = ScaleEffect.to(
      Vector2.all(0.9), // Thu nhỏ xuống 90% kích thước
      EffectController(
        duration: 0.6, // Chu kỳ 0.6 giây
        alternate: true, // Phình to rồi nhỏ lại (lặp lại)
        infinite: true, // Lặp vô hạn
        curve: Curves.easeInOut, // Chuyển động mượt mà
      ),
    );
    add(pulsatingEffect); // Áp dụng hiệu ứng

    return super.onLoad();
  }

  // ===============================================
  // 🔄 DI CHUYỂN & DỌN DẸP
  // ===============================================

  /**
   * update() - Xử lý di chuyển pickup và giới hạn màn hình
   * 
   * HÀNH VI DI CHUYỂN:
   * 1. Rơi xuống liên tục với tốc độ 300 pixels/giây
   * 2. Tự động xóa khi chạm đáy màn hình
   * 
   * THIẾT KẾ TỐC ĐỘ:
   * - Chậm hơn asteroid để người chơi có thời gian thu thập
   * - Vẫn đủ nhanh để tạo áp lực phải di chuyển
   * - 300 px/s là tốc độ cân bằng giữa dễ và khó
   * 
   * 📝 LƯU Ý:
   * - Pickup không wrap ngang như asteroid
   * - Chỉ di chuyển thẳng xuống dưới
   * - Tự động cleanup khi ra khỏi màn hình để tiết kiệm bộ nhớ
   */
  @override
  void update(double dt) {
    super.update(dt);

    // ===== DI CHUYỂN XUỐNG DƯỚI =====
    position.y += 300 * dt; // Rơi với tốc độ vừa phải (300 px/s)

    // ===== DỌN DẸP KHI RA KHỎI MÀN HÌNH =====
    // Xóa pickup khi đi qua đáy màn hình (người chơi bỏ lỡ)
    if (position.y > game.size.y + size.y / 2) {
      removeFromParent(); // Dọn dẹp bộ nhớ
    }
  }
}

// ===============================================
// 📝 GHI CHÚ TRIỂN KHAI (IMPLEMENTATION NOTES)
// ===============================================
//
// 🎁 CÂN BẰNG GAMEPLAY:
// - Tốc độ rơi: 300 px/s (vừa phải - có thể bắt được nhưng cần cố gắng)
// - Kích thước: 100px cho power-ups, 40px cho coin
// - Animation phình to nhỏ: Thu hút sự chú ý người chơi
//
// 🎮 TÍCH HỢP VỚI GAME:
// - Thu thập được xử lý bởi Player.onCollision()
// - Mỗi loại kích hoạt effect khác nhau:
//   * bomb → Spawn Bomb component xóa màn hình
//   * laser → Tăng laser level lên 1 (_upgradeLaserLevel)
//   * shield → Kích hoạt Shield component bảo vệ
//   * coin → Tăng 10 điểm (KHÔNG có effect đặc biệt khác)
//
// 🎨 PHẢN HỒI VISUAL:
// - Animation phình to nhỏ thu hút chú ý
// - Màu sắc riêng biệt: Mỗi loại có sprite khác nhau
// - Kích thước nhất quán: Dễ nhận biết và thu thập
//
// 🔧 CƠ CHẾ SPAWN:
// - Power-ups (bomb/laser/shield): PickupSpawner tạo ngẫu nhiên
// - Coin: CHỈ spawn từ asteroid3.png khi bị phá hủy (xem asteroid.dart)
// - Vị trí: X ngẫu nhiên trên chiều rộng màn hình
//
// � PHẦN THƯỞNG THU THẬP:
// - Coin: +10 điểm (mục đích chính để kiếm điểm)
// - Power-ups: KHÔNG tăng điểm, chỉ có hiệu ứng đặc biệt
// - Âm thanh: Phát 'collect' sound khi thu thập bất kỳ pickup nào
// - Xóa ngay: Pickup biến mất ngay sau khi thu thập
//
// 💰 HỆ THỐNG COIN ĐẶC BIỆT:
// - Coin là nguồn điểm DUY NHẤT trong game
// - CHỈ rơi từ asteroid3.png (không phải asteroid1 hay asteroid2)
// - Giá trị: 10 điểm/coin
// - Mục đích: Khuyến khích người chơi ưu tiên bắn asteroid3
// - Balance: Tạo risk vs reward (di chuyển để lấy coin vs tránh asteroid)
//
// 🎯 CHIẾN THUẬT NGƯỜI CHƠI:
// - Ưu tiên bắn asteroid3 để spawn coin
// - Thu thập coin để tăng điểm (không thể tăng điểm cách khác)
// - Cân nhắc lấy power-ups để mạnh hơn vs focus kiếm coin
// - Di chuyển khôn ngoan để lấy coin mà không bị asteroid đâm
