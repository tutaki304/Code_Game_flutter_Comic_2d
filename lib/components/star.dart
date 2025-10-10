import 'dart:math'; // Tạo số ngẫu nhiên

import 'package:cosmic_havoc/my_game.dart'; // Truy cập game instance
import 'package:flame/components.dart'; // Flame components
import 'package:flutter/widgets.dart'; // Flutter Color class

/**
 * Star - Component star nền cho hiệu ứng parallax scrolling
 * 
 * 🌟 CHỨC NĂNG CHÍNH:
 * - Tạo background stars với các kích thước khác nhau (1-3px)
 * - Parallax scrolling: Sao lớn hơn = di chuyển nhanh hơn
 * - Vòng lặp vô tận: Sao wrap từ dưới lên trên
 * - Alpha trong suốt: Dựa trên kích thước (lớn hơn = mờ đục hơn)
 * 
 * 🎨 THUỘC TÍNH VISUAL:
 * - Kích thước: Ngẫu nhiên 1-3 pixels
 * - Màu sắc: Trắng với độ mờ đục khác nhau
 * - Tốc độ: Tỷ lệ với kích thước (sao lớn rơi nhanh hơn)
 * - Vị trí: Ngẫu nhiên trên chiều rộng màn hình
 * 
 * 🔄 HÀNH VI:
 * - Di chuyển xuống liên tục
 * - Wraparound khi đến cạnh dưới
 * - Tái định vị ngẫu nhiên trên trục X sau khi wrap
 */
class Star extends CircleComponent with HasGameReference<MyGame> {
  // ===============================================
  // 🎨 STAR PROPERTIES
  // ===============================================

  final Random _random =
      Random(); // Random generator cho kích thước, vị trí, tốc độ
  final int _maxSize =
      3; // Kích thước star tối đa (pixels) - định nghĩa range 1-3
  late double _speed; // Tốc độ rơi (pixels/giây) - tính từ size

  // ===============================================
  // 🔄 LIFECYCLE METHODS
  // ===============================================

  /**
   * onLoad() - Initialize star properties với random values
   * 
   * Setup sequence:
   * 1. Random size (1-3 pixels)
   * 2. Random position across screen
   * 3. Calculate speed based on size (parallax effect)
   * 4. Set color với alpha transparency
   */
  @override
  Future<void> onLoad() {
    // ===== RANDOM SIZE GENERATION =====
    size =
        Vector2.all(1.0 + _random.nextInt(_maxSize)); // Kích thước: 1-3 pixels

    // ===== RANDOM INITIAL POSITION =====
    position = Vector2(
      _random.nextDouble() * game.size.x, // X: Random across screen width
      _random.nextDouble() * game.size.y, // Y: Random across screen height
    );

    // ===== PARALLAX SPEED CALCULATION =====
    // Sao lớn hơn rơi nhanh hơn (tạo hiệu ứng chiều sâu)
    _speed = size.x * (40 + _random.nextInt(10)); // Tốc độ = size * (40-49)

    // ===== TRANSPARENCY BASED ON SIZE =====
    // Sao lớn hơn = mờ đục hơn (alpha = size / maxSize)
    paint.color = Color.fromRGBO(255, 255, 255, size.x / _maxSize);

    return super.onLoad();
  }

  /**
   * update() - Cập nhật vị trí star mỗi frame
   * 
   * Logic di chuyển:
   * 1. Di chuyển star xuống dưới với tốc độ đã tính
   * 2. Kiểm tra ranh giới màn hình (cạnh dưới)
   * 3. Wraparound: Reset về trên với vị trí X ngẫu nhiên mới
   * 
   * Hiệu ứng Parallax: Các star khác size di chuyển với tốc độ khác nhau
   */
  @override
  void update(double dt) {
    super.update(dt);

    // ===== DOWNWARD MOVEMENT =====
    position.y += _speed * dt; // Di chuyển xuống với tốc độ parallax

    // ===== SCREEN WRAPAROUND =====
    // Khi star đi qua bottom edge của screen
    if (position.y > game.size.y + size.y / 2) {
      position.y = -size.y / 2; // Reset về đầu màn hình
      position.x =
          _random.nextDouble() * game.size.x; // Vị trí X ngẫu nhiên mới
    }
  }
}

// ===============================================
// 📝 GHI CHÚ TRIỂN KHAI
// ===============================================
//
// 🌟 LÝ THUYẾT PARALLAX SCROLLING:
// - Sao nhỏ hơn (1px) = tốc độ chậm hơn = lớp nền
// - Sao lớn hơn (3px) = tốc độ nhanh hơn = lớp tiền cảnh
// - Tạo ảo giác về chiều sâu và chuyển động
//
// 🎨 THIẾT KẾ VISUAL:
// - Sao trắng với độ trong suốt khác nhau
// - Alpha dựa trên kích thước: lớn hơn = dễ thấy hơn
// - Chuyển động liên tục mượt mà
//
// 🔄 VÒNG LẶP VÔ TẬN:
// - Sao liên tục quay vòng từ trên xuống dưới
// - Tái định vị X ngẫu nhiên tránh tạo pattern
// - Animation nền liền mạch
//
// 📱 HIỆU SUẤT:
// - CircleComponent nhẹ (overhead tối thiểu)
// - Logic update đơn giản (chỉ di chuyển Y)
// - Không cần phát hiện va chạm
