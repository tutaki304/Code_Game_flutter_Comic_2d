// ============================================
// 📦 IMPORT CÁC THƯ VIỆN CẦN THIẾT
// ============================================
import 'dart:async'; // Hỗ trợ async/await cho các hàm bất đồng bộ

import 'package:cosmic_havoc/components/asteroid.dart'; // Thiên thạch - mục tiêu va chạm
import 'package:cosmic_havoc/my_game.dart'; // Truy cập game instance chính
import 'package:flame/collisions.dart'; // Hệ thống phát hiện va chạm của Flame
import 'package:flame/components.dart'; // Các component cơ bản của Flame
import 'package:flame/effects.dart'; // Hiệu ứng animation (scale, fade, etc.)
import 'package:flutter/widgets.dart'; // Curves để tạo animation mượt mà

/// ============================================
/// 🛡️ CLASS SHIELD - KHIÊN BẢO VỆ TẠM THỜI
/// ============================================
/// 
/// 📝 MỤC ĐÍCH:
/// Shield là lá chắn bảo vệ tạm thời bao quanh tàu người chơi.
/// Khi kích hoạt, nó không chỉ bảo vệ mà còn CHỦ ĐỘNG PHÁ HỦY
/// các thiên thạch va chạm vào (phòng thủ tích cực).
/// 
/// 🎮 CHỨC NĂNG CHÍNH:
/// - Lá chắn bảo vệ bao quanh tàu người chơi
/// - Phá hủy thiên thạch khi chạm vào (tấn công + phòng thủ)
/// - Thời gian giới hạn: 5 giây tổng cộng (3s active + 2s fade)
/// - Phản hồi visual: Animation nhấp nháy + cảnh báo mờ dần
/// 
/// 🔄 CHU TRÌNH HOẠT ĐỘNG:
/// 
/// ┌─────────────────────────────────────────────────────┐
/// │ Phase 1: KÍCH HOẠT (t=0s)                           │
/// │ - Được spawn bởi Player.collectShield()             │
/// │ - Xuất hiện xung quanh player với opacity đầy       │
/// │ - Bắt đầu hiệu ứng pulsating                        │
/// └─────────────────────────────────────────────────────┘
///                      ↓
/// ┌─────────────────────────────────────────────────────┐
/// │ Phase 2: ACTIVE (t=0-3s)                            │
/// │ - Bảo vệ hoàn toàn: 3 giây                          │
/// │ - Pulsating liên tục: Scale 1.0 ↔ 1.1               │
/// │ - Phá hủy mọi asteroid va chạm                      │
/// │ - Opacity = 1.0 (rõ ràng)                           │
/// └─────────────────────────────────────────────────────┘
///                      ↓
/// ┌─────────────────────────────────────────────────────┐
/// │ Phase 3: WARNING (t=3-5s)                           │
/// │ - Fade out: Opacity 1.0 → 0.0                       │
/// │ - Vẫn còn bảo vệ (vẫn phá hủy asteroid)             │
/// │ - Cảnh báo player chuẩn bị hết shield               │
/// │ - Pulsating vẫn tiếp tục                            │
/// └─────────────────────────────────────────────────────┘
///                      ↓
/// ┌─────────────────────────────────────────────────────┐
/// │ Phase 4: HẾT HẠN (t=5s)                             │
/// │ - Tự động xóa khỏi game tree                        │
/// │ - Clear reference: game.player.activeShield = null  │
/// │ - Player trở lại vulnerable                         │
/// └─────────────────────────────────────────────────────┘
/// 
/// 🎯 CƠ CHẾ PHÒNG THỦ:
/// - Va chạm với asteroid → gọi asteroid.takeDamage()
/// - Player miễn nhiễm va chạm asteroid trong khi shield active
/// - Phạm vi bảo vệ: 200x200 pixels (lớn hơn player)
/// - KHÔNG va chạm với laser hoặc pickup
/// 
/// 🎨 HIỆU ỨNG VISUAL:
/// - Pulsating animation: Scale 1.0 ↔ 1.1 (vô hạn)
/// - Fade out cảnh báo: 2 giây cuối chỉ báo sắp hết
/// - Định vị: Tự động theo dõi chuyển động player
/// 
/// 💫 SỬ DỤNG CHIẾN THUẬT:
/// - Bảo vệ khẩn cấp trong vùng asteroid đông đúc
/// - Khả năng tấn công: Lao qua cụm asteroid để phá hủy
/// - Nguồn lực giới hạn: Chỉ từ shield pickup (hiếm)
/// 
/// 🔢 TOÁN HỌC SHIELD:
/// - Size: 200x200px (player thường ~60x60px)
/// - Coverage radius: 100px from center
/// - Pulsating: 1.0x → 1.1x → 1.0x (cycle 0.6s)
/// - Fade duration: 2.0 seconds linear
/// - Total lifetime: 5.0 seconds
/// 
/// ⚔️ OFFENSIVE DEFENSE (Phòng thủ tích cực):
/// Thay vì chỉ chặn (blocking), shield CHỦ ĐỘNG PHÁ HỦY
/// asteroids khi chạm vào. Điều này tạo gameplay thú vị hơn:
/// - Player có thể lao vào asteroid để clear path
/// - Shield trở thành vũ khí tấn công tạm thời
/// - Risk/reward: Lao vào nguy hiểm để clear nhiều asteroid
class Shield extends SpriteComponent
    with
        HasGameReference<MyGame>, // Mixin để truy cập game instance
        CollisionCallbacks {
  // Mixin để xử lý các sự kiện va chạm

  // ============================================
  // 🏗️ CONSTRUCTOR - HÀM KHỞI TẠO
  // ============================================

  /// Shield()
  /// 
  /// Tạo một lá chắn bảo vệ mới
  /// 
  /// CẤU HÌNH:
  /// - size: Vector2.all(200) - Kích thước 200x200 pixels
  /// - anchor: Anchor.center - Neo ở giữa để quay quanh player
  /// 
  /// TẠI SAO SIZE = 200px?
  /// - Player sprite: ~60x60px
  /// - Shield cần lớn hơn đủ để bao phủ toàn bộ
  /// - 200px radius = 100px từ tâm
  /// - Đủ lớn để rõ ràng nhưng không che khuất quá nhiều
  /// 
  /// TẠI SAO ANCHOR.CENTER?
  /// - Shield cần xoay quanh player
  /// - Center anchor giúp positioning chính xác
  /// - Dễ dàng follow player movement
  Shield() : super(size: Vector2.all(200), anchor: Anchor.center);

  // ============================================
  // 🔄 KHỞI TẠO & HIỆU ỨNG
  // ============================================

  /// onLoad() - Khởi tạo shield với chuỗi hiệu ứng hoàn chỉnh
  /// 
  /// NHIỆM VỤ:
  /// 1. Load hình ảnh shield từ assets
  /// 2. Định vị xung quanh player (offset theo size player)
  /// 3. Thêm hệ thống va chạm hình tròn
  /// 4. Bắt đầu hiệu ứng pulsating (nhấp nháy)
  /// 5. Lên lịch fade-out và hết hạn
  /// 
  /// TRÌNH TỰ THỰC HIỆN:
  /// 
  /// ┌──────────────────────────────────────────────┐
  /// │ STEP 1: TẢI HÌNH ẢNH                        │
  /// │ - Load 'shield.png' từ assets/images/       │
  /// │ - Texture trong suốt với viền sáng          │
  /// └──────────────────────────────────────────────┘
  ///                    ↓
  /// ┌──────────────────────────────────────────────┐
  /// │ STEP 2: ĐỊNH VỊ                             │
  /// │ - position += game.player.size / 2          │
  /// │ - Công thức: Vị trí player + offset         │
  /// │ - Kết quả: Center around player             │
  /// └──────────────────────────────────────────────┘
  ///                    ↓
  /// ┌──────────────────────────────────────────────┐
  /// │ STEP 3: THIẾT LẬP VA CHẠM                   │
  /// │ - CircleHitbox() - Hitbox hình tròn         │
  /// │ - Radius = 100px (size/2)                   │
  /// │ - Collision continuous với asteroids        │
  /// └──────────────────────────────────────────────┘
  ///                    ↓
  /// ┌──────────────────────────────────────────────┐
  /// │ STEP 4: PULSATING EFFECT                    │
  /// │ - ScaleEffect.to(1.1) - Phóng to 110%      │
  /// │ - Duration: 0.6s cycle                      │
  /// │ - alternate: true - Lên xuống liên tục     │
  /// │ - infinite: true - Không bao giờ dừng      │
  /// │ - Curve: easeInOut - Mượt mà               │
  /// └──────────────────────────────────────────────┘
  ///                    ↓
  /// ┌──────────────────────────────────────────────┐
  /// │ STEP 5: FADE OUT & EXPIRATION               │
  /// │ - OpacityEffect.fadeOut(2.0s)               │
  /// │ - startDelay: 3.0s - Chờ 3s trước khi fade  │
  /// │ - onComplete: Cleanup shield                │
  /// └──────────────────────────────────────────────┘
  /// 
  /// TIMELINE CHI TIẾT:
  /// t=0.0s: Shield spawn, pulsating bắt đầu, opacity = 1.0
  /// t=0.6s: Pulsating cycle 1 hoàn thành
  /// t=1.2s: Pulsating cycle 2 hoàn thành
  /// t=3.0s: Fade out bắt đầu, opacity = 1.0 → 0.9
  /// t=4.0s: Opacity = 0.5 (warning rõ ràng)
  /// t=5.0s: Opacity = 0.0, shield expire, cleanup
  /// 
  /// Code by TuCodeDao @tutaki304
  @override
  FutureOr<void> onLoad() async {
    // ===== BƯỚC 1: TẢI HÌNH ẢNH =====
    // Load sprite 'shield.png' từ assets/images/
    sprite = await game.loadSprite('shield.png'); // Load texture shield

    // ===== BƯỚC 2: ĐỊNH VỊ XUNG QUANH PLAYER =====
    // Công thức positioning:
    // shield.position = player.position + (player.size / 2)
    //
    // Giải thích:
    // - player.position: Góc trên bên trái của player
    // - player.size / 2: Offset đến center của player
    // - Kết quả: Shield center trùng với player center
    position += game.player.size / 2; // Center xung quanh player

    // ===== BƯỚC 3: THIẾT LẬP VA CHẠM =====
    // CircleHitbox - Hitbox hình tròn cho collision detection
    // Radius tự động = size / 2 = 200 / 2 = 100 pixels
    // Tại sao Circle? Shield hình tròn nên hitbox cũng tròn
    add(CircleHitbox()); // Collision area hình tròn

    // ===== BƯỚC 4: HIỆU ỨNG PULSATING =====
    // ScaleEffect - Hiệu ứng phóng to/thu nhỏ
    final ScaleEffect pulsatingEffect = ScaleEffect.to(
      Vector2.all(1.1), // Scale lên 110% (10% lớn hơn)
      // Scale uniform: Cả X và Y đều scale 1.1x

      EffectController(
        duration: 0.6, // Thời gian 1 cycle: 0.6 giây
        // 0.6s đủ nhanh để thu hút attention
        // Không quá nhanh gây chói mắt

        alternate: true, // Đảo chiều sau mỗi cycle
        // Scale lên 1.1 → Scale xuống 1.0 → Scale lên 1.1...
        // Tạo hiệu ứng nhấp nháy liên tục

        infinite: true, // Lặp vô hạn
        // Pulsating suốt thời gian shield tồn tại
        // Chỉ dừng khi shield bị remove

        curve: Curves.easeInOut, // Đường cong animation
        // easeInOut: Chậm đầu → Nhanh giữa → Chậm cuối
        // Tạo chuyển động mượt mà, không giật
      ),
    );
    add(pulsatingEffect); // Apply pulsating vào shield

    // CÔNG THỨC PULSATING:
    // scale(t) = 1.0 + 0.1 × sin(2π × t / 0.6)
    // Trong đó:
    // - t: Thời gian (seconds)
    // - 0.6: Duration của 1 cycle
    // - 0.1: Amplitude (10% scale)
    // - sin: Dao động giữa -1 và +1
    //
    // Ví dụ:
    // t=0.0s: scale = 1.0 (ban đầu)
    // t=0.15s: scale = 1.1 (max)
    // t=0.3s: scale = 1.0 (về gốc)
    // t=0.45s: scale = 1.1 (max lại)
    // t=0.6s: scale = 1.0 (cycle hoàn thành)

    // ===== BƯỚC 5: FADE OUT & EXPIRATION =====
    // OpacityEffect - Hiệu ứng thay đổi độ trong suốt
    final OpacityEffect fadeOutEffect = OpacityEffect.fadeOut(
      // fadeOut: Giảm opacity từ 1.0 → 0.0

      EffectController(
        duration: 2.0, // Thời gian fade: 2.0 giây
        // Đủ dài để player nhận ra shield sắp hết
        // Không quá dài để không gây khó chịu

        startDelay: 3.0, // Delay 3.0 giây trước khi bắt đầu
        // 3s active phase với full opacity
        // Sau đó mới bắt đầu fade (warning phase)
      ),

      // CALLBACK KHI HOÀN THÀNH:
      onComplete: () {
        // ===== CLEANUP KHI HẾT HẠN =====

        // BƯỚC 1: Xóa shield khỏi game tree
        removeFromParent(); // Shield biến mất khỏi màn hình

        // BƯỚC 2: Clear reference trong player
        game.player.activeShield = null; // Set về null
        // Quan trọng! Nếu không clear:
        // - Player vẫn nghĩ mình có shield
        // - Không thể pickup shield mới
        // - Memory leak (shield reference còn tồn tại)

        // Sau cleanup:
        // - Player trở lại vulnerable
        // - Có thể pickup shield mới
        // - Memory được giải phóng
      },
    );
    add(fadeOutEffect); // Schedule expiration

    // CÔNG THỨC FADE OUT:
    // opacity(t) = 1.0 - (t - 3.0) / 2.0
    // Trong đó:
    // - t: Thời gian tổng (3-5 seconds)
    // - (t - 3.0): Thời gian từ khi bắt đầu fade
    // - / 2.0: Chia cho duration fade
    //
    // Ví dụ:
    // t=3.0s: opacity = 1.0 (bắt đầu fade)
    // t=3.5s: opacity = 0.75
    // t=4.0s: opacity = 0.5 (warning rõ ràng)
    // t=4.5s: opacity = 0.25
    // t=5.0s: opacity = 0.0 (expire)

    return super.onLoad(); // Gọi hàm onLoad của class cha
  }

  // ============================================
  // 💥 XỬ LÝ VA CHẠM
  // ============================================

  /// onCollision() - Xử lý va chạm với asteroid (phòng thủ tích cực)
  /// 
  /// THAM SỐ:
  /// @param intersectionPoints - Các điểm giao nhau của va chạm
  /// @param other - Component khác đang va chạm với shield
  /// 
  /// LOGIC XỬ LÝ:
  /// 1. Kiểm tra xem object va chạm có phải là Asteroid không
  /// 2. Nếu đúng là Asteroid:
  ///    - Gọi other.takeDamage() để phá hủy asteroid
  ///    - Shield KHÔNG bị damage (bất tử trong 5s)
  /// 3. Nếu không phải Asteroid: Bỏ qua
  /// 
  /// CÁC TRƯỜNG HỢP VA CHẠM:
  /// - Shield vs Asteroid: ✅ Xử lý (phá hủy asteroid)
  /// - Shield vs Player: ❌ Không xảy ra (cùng team)
  /// - Shield vs Pickup: ❌ Không xử lý (không tương tác)
  /// - Shield vs Laser: ❌ Không xử lý (không conflict)
  /// - Shield vs Bomb: ❌ Không xử lý (không tương tác)
  /// 
  /// OFFENSIVE DEFENSE CONCEPT:
  /// Thay vì chỉ chặn (passive blocking), shield CHỦ ĐỘNG PHÁ HỦY
  /// asteroids khi chạm vào. Điều này:
  /// - Làm gameplay thú vị hơn (player có thể aggressive)
  /// - Tạo risk/reward mechanics (lao vào để clear path)
  /// - Shield trở thành vũ khí tấn công tạm thời
  /// - Khuyến khích playstyle chủ động thay vì passive
  /// 
  /// SO SÁNH CƠ CHẾ:
  /// ┌────────────────┬─────────────────┬──────────────────┐
  /// │ Cơ chế         │ Passive Block   │ Active Destroy   │
  /// ├────────────────┼─────────────────┼──────────────────┤
  /// │ Asteroid hit   │ Bounce back     │ Take damage      │
  /// │ Shield damage  │ Durability loss │ No damage        │
  /// │ Playstyle      │ Defensive       │ Aggressive       │
  /// │ Risk/Reward    │ Low risk        │ High risk        │
  /// │ Fun factor     │ Safe but boring │ Exciting         │
  /// └────────────────┴─────────────────┴──────────────────┘
  /// 
  /// VÍ DỤ SỬ DỤNG:
  /// Scenario: Player có shield, bị bao vây bởi 5 asteroids
  /// 
  /// Với Passive Block:
  /// - Player phải né tránh từng asteroid
  /// - Shield chỉ bảo vệ khi va chạm ngẫu nhiên
  /// - Playstyle: Defensive, chờ asteroids đi qua
  /// 
  /// Với Active Destroy (hiện tại):
  /// - Player có thể LAO VÀO cụm asteroids
  /// - Shield phá hủy mọi asteroid va chạm
  /// - Clear path nhanh chóng
  /// - Playstyle: Aggressive, chủ động tấn công
  /// - Risk: Phải lao vào vùng nguy hiểm
  /// - Reward: Clear nhiều asteroids, lấy pickups
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other); // Gọi hàm cha

    // ===== KIỂM TRA LOẠI OBJECT =====
    if (other is Asteroid) {
      // Đây là thiên thạch! Xử lý va chạm:

      // PHÁ HỦY ASTEROID
      other.takeDamage(); // Asteroid tự xử lý:
      // - Giảm health (nếu có multi-hit)
      // - Hiệu ứng flash màu trắng
      // - Âm thanh hit
      // - Tách nhỏ nếu còn health
      // - Drop coin nếu là mảnh nhỏ nhất
      // - Explosion effect khi chết

      // CHÚ Ý: Shield KHÔNG bị damage
      // - Shield bất tử trong 5 giây
      // - Có thể phá hủy vô hạn asteroids
      // - Chỉ hết hạn theo thời gian, không theo damage

      // Logic trong Player:
      // - Player collision check bị skip nếu có activeShield
      // - Player không bị takeDamage() khi asteroid va chạm
      // - Shield hoạt động như một "force field"
    }

    // Chú ý: Không xử lý va chạm với các object khác
    // Player, Pickup, Laser, Bomb, Shield khác sẽ được bỏ qua
  }
}

// ============================================
// 📝 GHI CHÚ TRIỂN KHAI CHI TIẾT
// ============================================
//
// 🛡️ CƠ CHẾ SHIELD:
//
// THỜI GIAN:
// - Total duration: 5.0 seconds
// - Active phase: 3.0 seconds (full opacity)
// - Warning phase: 2.0 seconds (fading)
// - Expiration: Auto-remove + cleanup
//
// KÍCH THƯỚC:
// - Size: 200x200 pixels
// - Coverage radius: 100 pixels from center
// - Player size: ~60x60 pixels
// - Extra protection: 40 pixels buffer zone
//
// OFFENSIVE CAPABILITY:
// - Destroys asteroids on contact
// - No limit on destruction count
// - Same damage as laser (calls takeDamage())
// - Can ram through asteroid clusters
//
// INVULNERABILITY:
// - Player cannot take damage while shield active
// - Collision check skipped in Player.onCollision()
// - Shield never takes damage itself
//
// 🎮 TÍCH HỢP GAMEPLAY:
//
// ACTIVATION:
// - Triggered by Player.collectShield()
// - Spawned at player position
// - Only one shield at a time (activeShield reference)
//
// PLAYER REFERENCE:
// - game.player.activeShield = this
// - Prevents multiple shields
// - Used to skip player collision checks
// - Cleared on expiration
//
// MOVEMENT SYNC:
// - Shield doesn't manually follow player
// - Position set once in onLoad()
// - Player.update() handles shield positioning
// - Shield automatically moves with player
//
// 🎨 THIẾT KẾ VISUAL:
//
// PULSATING ANIMATION:
// - Scale range: 1.0x to 1.1x (10% growth)
// - Cycle duration: 0.6 seconds
// - Infinite loop: Never stops until removed
// - Curve: easeInOut (smooth acceleration/deceleration)
// - Purpose: Indicate active protection status
//
// FADE WARNING:
// - Start: 3.0 seconds (delayed)
// - Duration: 2.0 seconds
// - Opacity: 1.0 → 0.0 (linear)
// - Purpose: Warn player shield expiring soon
//
// SIZE DESIGN:
// - Large enough: Clear protection indicator
// - Not too large: Doesn't obscure gameplay
// - Circular: Matches sprite và hitbox shape
//
// ⏱️ CHIẾN THUẬT TIMING:
//
// BEST USAGE:
// ✅ When surrounded by many asteroids (5+)
// ✅ During difficult waves
// ✅ To ram through asteroid clusters
// ✅ When low on health (emergency)
// ✅ To collect pickups in dangerous areas
//
// AVOID WASTING:
// ❌ When only 1-2 asteroids on screen
// ❌ When asteroids are far away
// ❌ When you have high laser level
// ❌ At start of wave (asteroids not spawned yet)
//
// AGGRESSIVE TACTICS:
// - Activate shield → Ram into asteroid cluster
// - Clear path to pickups quickly
// - Use momentum to chain multiple destructions
// - Position near spawn points for max effect
//
// DEFENSIVE TACTICS:
// - Activate when cornered
// - Buy time to reposition
// - Cover retreat to safe area
// - Protect during laser pickup collection
//
// 🔧 CHI TIẾT KỸ THUẬT:
//
// COLLISION DETECTION:
// - CircleHitbox: Accurate circular collision
// - Radius: 100 pixels (size / 2)
// - Continuous detection: Checks every frame
// - No isSolid flag: Allows overlap
//
// PLAYER REFERENCE MANAGEMENT:
// - Set on spawn: game.player.activeShield = this
// - Checked in Player: if (activeShield != null) skip collision
// - Cleared on expire: game.player.activeShield = null
// - Prevents memory leaks and multiple shields
//
// EFFECT CHAINING:
// - Pulsating + Fade run independently
// - No interference between effects
// - Pulsating: Infinite loop
// - Fade: Single execution with delay
//
// POSITIONING ALGORITHM:
// position = player.position + (player.size / 2)
//
// Breakdown:
// - player.position: Top-left corner of player
// - player.size: Vector2(width, height) of player
// - player.size / 2: Offset to center
// - Result: Shield center = Player center
//
// Example:
// - Player position: (100, 200)
// - Player size: (60, 60)
// - player.size / 2: (30, 30)
// - Shield position: (100+30, 200+30) = (130, 230)
//
// 📊 HIỆU SUẤT (PERFORMANCE):
// - Memory: ~2KB per shield
// - Max shields: 1 at a time (controlled)
// - Animation cost: O(1) (Flame optimized)
// - Collision checks: O(n) với n = asteroids on screen
// - Cleanup: Automatic, no manual management
//
// 🎯 ĐỀ XUẤT CẢI TIẾN (FUTURE IDEAS):
// - Multi-level shield: Durability system (3 hits = expire)
// - Shield particles: Energy particles around edge
// - Sound effect: Activation sound + hit sound
// - Power boost: Temporary speed boost while shielded
// - Shield upgrade: Longer duration from special pickups
// - Visual variety: Different colors for different durations
//
// 🐛 DEBUG TIPS:
// - Nếu shield không xuất hiện: Check sprite loading
// - Nếu không follow player: Check positioning logic
// - Nếu không va chạm: Check CircleHitbox setup
// - Nếu player vẫn bị damage: Check activeShield reference
// - Nếu pulsating không hoạt động: Check effect controller
// - Nếu không tự xóa: Check fadeOut onComplete callback
