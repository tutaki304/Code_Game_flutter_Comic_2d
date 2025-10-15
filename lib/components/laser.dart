// ============================================
// 📦 IMPORT CÁC THỨ VIỆN CẦN THIẾT
// ============================================
import 'dart:async'; // Hỗ trợ async/await cho các hàm bất đồng bộ
import 'dart:math'; // Hàm toán học (sin, cos) để tính toán góc bắn

import 'package:cosmic_havoc/components/asteroid.dart'; // Import Asteroid để xử lý va chạm
import 'package:cosmic_havoc/my_game.dart'; // Truy cập instance game chính
import 'package:flame/collisions.dart'; // Hệ thống phát hiện va chạm của Flame
import 'package:flame/components.dart'; // Các component cơ bản của Flame

/**
 * ============================================
 * 🚀 CLASS LASER - ĐẠN BẮN CỦA TÀU NGƯỜI CHƠI
 * ============================================
 * 
 * 📝 MỤC ĐÍCH:
 * Laser là viên đạn được bắn ra từ tàu người chơi để tiêu diệt thiên thạch.
 * Đây là vũ khí chính trong game, có thể bắn thẳng hoặc tán xạ tùy theo level.
 * 
 * 🎮 CHỨC NĂNG CHÍNH:
 * - Bắn từ vị trí tàu người chơi
 * - Di chuyển lên trên với tốc độ cao (500 px/giây)
 * - Có thể bắn theo góc (cho hệ thống laser nâng cấp)
 * - Va chạm với thiên thạch và gây sát thương
 * - Tự động xóa khi ra khỏi màn hình (tiết kiệm bộ nhớ)
 * 
 * 🎯 CƠ CHẾ VA CHẠM:
 * - Khi trúng thiên thạch: Gọi hàm takeDamage() của asteroid
 * - Tự hủy sau khi trúng đích (viên đạn biến mất)
 * - Dùng RectangleHitbox cho va chạm chính xác
 * 
 * ⚡ HỆ THỐNG DI CHUYỂN:
 * - Tốc độ: 500 pixels/giây (rất nhanh)
 * - Hướng: Lên trên (mặc định) hoặc theo góc
 * - Công thức: Vector2(sin(góc), -cos(góc)) × tốc_độ × thời_gian
 * 
 * 🔢 TOÁN HỌC:
 * - Góc 0°: Bắn thẳng lên (0, -1)
 * - Góc dương (+30°): Bắn lên bên phải (0.5, -0.866)
 * - Góc âm (-30°): Bắn lên bên trái (-0.5, -0.866)
 * 
 * 🗑️ TỰ ĐỘNG DỌN DẸP:
 * - Xóa laser khi đi ra khỏi đỉnh màn hình
 * - Không để lại object thừa trong bộ nhớ
 * - Tối ưu hóa hiệu suất game
 */
class Laser extends SpriteComponent
    with
        HasGameReference<MyGame>, // Mixin để truy cập game instance
        CollisionCallbacks {
  // Mixin để xử lý các sự kiện va chạm

  // ============================================
  // 🏗️ CONSTRUCTOR - HÀM KHỞI TẠO
  // ============================================

  /**
   * Laser({required position, angle = 0.0})
   * 
   * Tạo một viên đạn laser mới
   * 
   * THAM SỐ:
   * @param position (required) - Vị trí xuất phát (thường là vị trí tàu player)
   * @param angle (optional) - Góc bắn tính bằng radian
   *        - Mặc định: 0.0 (bắn thẳng lên)
   *        - Dương: Nghiêng bên phải
   *        - Âm: Nghiêng bên trái
   * 
   * CẤU HÌNH:
   * - anchor: Anchor.center - Điểm neo ở giữa sprite (cho xoay đẹp)
   * - priority: -1 - Hiển thị phía sau player nhưng trước background
   */
  Laser({required super.position, super.angle = 0.0})
      : super(
          anchor: Anchor.center, // Neo ở giữa để xoay mượt
          priority: -1, // Layer thấp hơn player
        );

  // ============================================
  // 🔄 CÁC HÀM VÒNG ĐỜI (LIFECYCLE)
  // ============================================

  /**
   * onLoad() - Hàm được gọi khi laser được tạo lần đầu
   * 
   * NHIỆM VỤ:
   * 1. Load hình ảnh laser từ assets
   * 2. Điều chỉnh kích thước cho phù hợp
   * 3. Thêm hitbox để phát hiện va chạm
   * 
   * TRÌNH TỰ THỰC HIỆN:
   * 1. Load sprite 'laser.png' từ thư mục assets/images/
   * 2. Scale xuống 25% kích thước gốc (cân bằng visual)
   * 3. Thêm RectangleHitbox cho collision detection
   * 4. Gọi super.onLoad() để hoàn tất
   */
  @override
  FutureOr<void> onLoad() async {
    // ===== BƯỚC 1: TẢI HÌNH ẢNH =====
    sprite = await game.loadSprite('laser.png'); // Load texture laser

    // ===== BƯỚC 2: ĐIỀU CHỈNH KÍCH THƯỚC =====
    // Scale xuống 25% kích thước gốc
    // Lý do: Laser gốc quá lớn, cần nhỏ lại cho phù hợp gameplay
    size *= 0.25;

    // ===== BƯỚC 3: THIẾT LẬP VA CHẠM =====
    // Thêm RectangleHitbox - hộp va chạm hình chữ nhật
    // Tự động khớp với size của sprite
    add(RectangleHitbox());

    return super.onLoad(); // Gọi hàm onLoad của class cha
  }

  /**
   * update(dt) - Hàm được gọi mỗi frame để cập nhật laser
   * 
   * THAM SỐ:
   * @param dt (delta time) - Thời gian trôi qua từ frame trước (giây)
   *        Thường là ~0.016 giây (60 FPS) hoặc ~0.033 giây (30 FPS)
   * 
   * NHIỆM VỤ:
   * 1. Tính toán hướng di chuyển dựa trên góc
   * 2. Di chuyển laser theo hướng đó với tốc độ 500 px/s
   * 3. Kiểm tra nếu laser đã ra khỏi màn hình
   * 4. Xóa laser nếu đã bay quá đỉnh màn hình
   * 
   * TOÁN HỌC DI CHUYỂN:
   * - Vector hướng: Vector2(sin(angle), -cos(angle))
   * - Vận tốc: 500 pixels/giây
   * - Di chuyển: position += hướng × vận_tốc × dt
   * 
   * VÍ DỤ TÍNH TOÁN:
   * Giả sử angle = 0 (bắn thẳng lên), dt = 0.016s (60 FPS):
   * - Hướng: Vector2(sin(0), -cos(0)) = Vector2(0, -1)
   * - Di chuyển: Vector2(0, -1) × 500 × 0.016 = Vector2(0, -8)
   * - Kết quả: Laser di chuyển 8 pixels lên trên mỗi frame
   * 
   * GIẢI THÍCH CÔNG THỨC:
   * - sin(angle): Thành phần ngang (trái/phải)
   *   + angle = 0: sin(0) = 0 (không đi ngang)
   *   + angle = +30°: sin(30°) = 0.5 (đi phải)
   *   + angle = -30°: sin(-30°) = -0.5 (đi trái)
   * 
   * - -cos(angle): Thành phần dọc (lên/xuống)
   *   + Dấu trừ vì: Y tăng = xuống dưới trong Flame
   *   + angle = 0: -cos(0) = -1 (đi lên)
   *   + angle = 90°: -cos(90°) = 0 (không đi dọc)
   */
  @override
  void update(double dt) {
    super.update(dt); // Gọi update của class cha trước

    // ===== TÍNH TOÁN & DI CHUYỂN =====
    // Công thức tổng quát: position_mới = position_cũ + hướng × tốc_độ × thời_gian

    // Vector hướng dựa trên góc:
    final direction = Vector2(
        sin(angle), // Thành phần X (trái -1 ... 0 ... +1 phải)
        -cos(angle) // Thành phần Y (-1 lên ... 0 ... +1 xuống)
        );

    final speed = 500.0; // Tốc độ: 500 pixels mỗi giây

    // Cập nhật vị trí
    position += direction * speed * dt;

    // ===== KIỂM TRA BIÊN MÀN HÌNH =====
    // Nếu laser đã bay quá đỉnh màn hình (position.y âm và nhỏ hơn -size.y/2)
    // thì xóa nó để tiết kiệm bộ nhớ
    if (position.y < -size.y / 2) {
      removeFromParent(); // Xóa khỏi game tree (giải phóng bộ nhớ)
    }
  }

  // ============================================
  // 💥 XỬ LÝ VA CHẠM
  // ============================================

  /**
   * onCollision() - Hàm được gọi khi laser va chạm với object khác
   * 
   * THAM SỐ:
   * @param intersectionPoints - Tập hợp các điểm giao nhau của collision
   * @param other - Component khác đang va chạm với laser
   * 
   * LOGIC XỬ LÝ:
   * 1. Kiểm tra xem object va chạm có phải là Asteroid không
   * 2. Nếu đúng là Asteroid:
   *    a. Tự hủy laser (removeFromParent)
   *    b. Gây damage cho asteroid (other.takeDamage)
   * 3. Nếu không phải Asteroid: Bỏ qua (không làm gì)
   * 
   * CÁC TRƯỜNG HỢP VA CHẠM:
   * - Laser vs Asteroid: ✅ Xử lý (damage + tự hủy)
   * - Laser vs Player: ❌ Không xảy ra (cùng team)
   * - Laser vs Pickup: ❌ Không xử lý (không tương tác)
   * - Laser vs Laser: ❌ Không xử lý (đạn không đánh nhau)
   * 
   * TRÌNH TỰ THỰC HIỆN:
   * 1. Laser trúng Asteroid
   * 2. onCollision() được Flame gọi tự động
   * 3. removeFromParent() - Laser biến mất
   * 4. other.takeDamage() - Asteroid nhận damage
   * 5. Asteroid xử lý: health--, effects, split, etc.
   */
  @override
  void onCollision(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollision(intersectionPoints, other); // Gọi hàm cha

    // ===== KIỂM TRA LOẠI OBJECT =====
    if (other is Asteroid) {
      // Đây là thiên thạch! Xử lý va chạm:

      // BƯỚC 1: Tự hủy laser
      removeFromParent(); // Viên đạn biến mất sau khi trúng đích

      // BƯỚC 2: Gây sát thương cho thiên thạch
      other.takeDamage(); // Asteroid sẽ xử lý:
      // - Giảm health
      // - Hiệu ứng flash
      // - Âm thanh hit
      // - Tách nhỏ nếu còn health
      // - Drop coin nếu là mảnh nhỏ nhất
    }

    // Chú ý: Không xử lý va chạm với các object khác
    // Player, Pickup, Shield, etc. sẽ được bỏ qua
  }
}

// ============================================
// 📝 GHI CHÚ TRIỂN KHAI CHI TIẾT
// ============================================
//
// 🎯 HỆ THỐNG LASER ĐA CẤP:
// Level 1: 1 laser, góc 0° (thẳng lên)
// Level 2: 2 laser, góc 0° song song (cách nhau 20px)
// Level 3-10: 3-10 laser, tán xạ trong góc 60°
//
// Công thức góc cho level 3+:
// - Tổng góc tán: 60° = π/3 radian
// - Góc mỗi laser: totalSpread / (numLasers - 1)
// - Góc laser thứ i: -totalSpread/2 + i × angleStep
//
// Ví dụ Level 5 (5 lasers):
// - angleStep = 60° / 4 = 15°
// - Laser 0: -30° (trái nhất)
// - Laser 1: -15°
// - Laser 2: 0° (giữa)
// - Laser 3: +15°
// - Laser 4: +30° (phải nhất)
//
// ⚡ TỐI ƯU HÓA HIỆU SUẤT:
// - Tốc độ cao (500 px/s) cho gameplay responsive
// - Auto-cleanup ngăn memory leak
// - RectangleHitbox đơn giản cho hiệu suất tốt
// - Không dùng CircleHitbox vì laser hình chữ nhật
//
// 🎨 THIẾT KẾ VISUAL:
// - Sprite nhỏ (25% scale) cân bằng với kích thước game
// - Center anchor cho rotation mượt mà
// - Priority -1: Laser nằm sau player, trước background
// - Màu sắc: Tùy vào sprite được load
//
// 🔧 BREAKDOWN TOÁN HỌC:
//
// 1. Góc 0 radian (0°):
//    - sin(0) = 0
//    - cos(0) = 1
//    - Vector: (0, -1)
//    - Kết quả: Đi thẳng lên
//
// 2. Góc π/6 radian (30°):
//    - sin(π/6) = 0.5
//    - cos(π/6) = 0.866
//    - Vector: (0.5, -0.866)
//    - Kết quả: Đi lên bên phải (góc 30°)
//
// 3. Góc -π/6 radian (-30°):
//    - sin(-π/6) = -0.5
//    - cos(-π/6) = 0.866
//    - Vector: (-0.5, -0.866)
//    - Kết quả: Đi lên bên trái (góc -30°)
//
// 📊 HIỆU SUẤT:
// - Mỗi laser: ~1KB memory
// - Tối đa ~20 lasers trên màn hình (player bắn 5 shots/s × 2s × 2 lasers)
// - Collision check: O(n) với spatial hashing của Flame
// - Update cost: O(1) mỗi laser
//
// 🎮 GAMEPLAY BALANCE:
// - Tốc độ 500 px/s: Nhanh hơn asteroid (300 px/s)
// - Tầm bắn: Toàn màn hình (unlimited range)
// - Damage: 1 hit = 1 damage (handled by Asteroid)
// - Cooldown: 0.2s giữa mỗi lần bắn (handled by Player)
//
// 🐛 DEBUG TIPS:
// - Nếu laser không xuất hiện: Check sprite loading
// - Nếu không va chạm: Check hitbox size và collision layers
// - Nếu lag: Check số lượng laser (không auto-cleanup)
// - Nếu góc sai: Verify radian conversion (degrees × π/180)
