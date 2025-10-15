import 'package:cosmic_havoc/my_game.dart';
import 'package:flutter/material.dart';

/**
 * GameOverOverlay - Màn hình hiển thị khi game over
 * 
 * 🎮 CHỨC NĂNG CHÍNH:
 * - Hiển thị "GAME OVER" với fade-in animation
 * - 2 buttons: "PLAY AGAIN" (restart) và "QUIT GAME" (về menu)
 * - Semi-transparent background (đen mờ 150 alpha)
 * - Smooth fade out animation khi thoát
 * 
 * 🔄 LIFECYCLE:
 * 1. Được show bởi MyGame.playerDied() 
 * 2. Fade in từ opacity 0 → 1 (500ms)
 * 3. User chọn action → fade out về 0 → auto remove
 * 
 * 📱 RESPONSIVE: Font size cố định phù hợp mọi thiết bị
 */
class GameOverOverlay extends StatefulWidget {
  final MyGame game; // Reference đến game instance để gọi methods

  const GameOverOverlay({super.key, required this.game});

  @override
  State<GameOverOverlay> createState() => _GameOverOverlayState();
}

class _GameOverOverlayState extends State<GameOverOverlay> {
  // ===============================================
  // 🎨 STATE VARIABLES
  // ===============================================

  double _opacity =
      0.0; // Opacity cho fade in/out animation (0.0 = invisible, 1.0 = visible)

  // ===============================================
  // 🔄 LIFECYCLE METHODS
  // ===============================================

  /**
   * initState() - Khởi tạo overlay với fade-in effect
   * 
   * Logic:
   * - Bắt đầu với opacity = 0 (invisible)
   * - Dùng Future.delayed để trigger setState trong next frame
   * - Set opacity = 1.0 để AnimatedOpacity tự fade in
   * 
   * Duration 0ms = execute ngay sau khi widget built
   */
  @override
  void initState() {
    super.initState();

    // ===== TRIGGER FADE-IN ANIMATION =====
    Future.delayed(
      const Duration(milliseconds: 0), // Execute trong next frame
      () {
        if (mounted) {
          // Safety check: widget còn tồn tại
          setState(() {
            _opacity = 1.0; // Trigger fade in animation
          });
        }
      },
    );
  }

  /**
   * build() - Xây dựng UI của Game Over overlay
   * 
   * 🏗️ STRUCTURE:
   * AnimatedOpacity (fade in/out)
   *   └── Container (semi-transparent background)  
   *       └── Column (center alignment)
   *           ├── "GAME OVER" text
   *           ├── "PLAY AGAIN" button
   *           └── "QUIT GAME" button
   * 
   * 🎭 ANIMATIONS:
   * - Fade in: opacity 0→1 khi show (500ms)
   * - Fade out: opacity 1→0 khi button pressed → auto remove overlay
   */
  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      // ===== ANIMATION CALLBACK =====
      onEnd: () {
        if (_opacity == 0.0) {
          // Khi fade out hoàn tất
          widget.game.overlays.remove('GameOver'); // Tự động xóa overlay
        }
      },
      opacity: _opacity, // Giá trị opacity hiện tại
      duration: const Duration(milliseconds: 500), // Thời lượng animation

      // ===== OVERLAY CONTAINER =====
      child: Container(
        color: Colors.black.withAlpha(150), // Nền đen bán trong suốt
        alignment: Alignment.center, // Căn giữa tất cả nội dung

        // ===== MAIN CONTENT COLUMN =====
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Căn giữa theo dọc
          children: [
            // ===== GAME OVER TITLE =====
            const Text(
              'GAME OVER',
              style: TextStyle(
                color: Colors.white, // Chữ trắng để tương phản tốt
                fontSize: 48, // Font size lớn để bắt mắt
                fontWeight: FontWeight.bold, // Bold để hiệu ứng kịch tính
              ),
            ),
            const SizedBox(height: 20), // Khoảng cách giữa title và score

            // ===== FINAL SCORE DISPLAY =====
            Text(
              'SCORE: ${widget.game.score}',
              style: TextStyle(
                color: Colors.amber, // Màu vàng nổi bật cho điểm
                fontSize: 36, // Lớn nhưng nhỏ hơn GAME OVER
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.8),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30), // Khoảng cách giữa score và buttons

            // ===== PLAY AGAIN BUTTON =====
            TextButton(
              onPressed: () {
                // ===== BUTTON CLICK SEQUENCE =====
                widget.game.audioManager
                    .playSound('click'); // Play click sound effect
                widget.game.restartGame(); // Reset game về trạng thái ban đầu
                setState(() {
                  _opacity = 0.0; // Trigger fade out animation
                });
                // Note: Overlay sẽ tự động remove trong onEnd callback
              },

              // ===== BUTTON STYLING =====
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 25), // Padding của button
                backgroundColor: Colors.blue, // Nền màu xanh
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(50), // Rounded corners (pill shape)
                ),
              ),

              // ===== BUTTON TEXT =====
              child: const Text(
                'PLAY AGAIN',
                style: TextStyle(
                  color: Colors.white, // White text trên blue background
                  fontSize: 28, // Large readable font
                ),
              ),
            ),
            const SizedBox(height: 15), // Khoảng cách giữa 2 buttons

            // ===== QUIT GAME BUTTON =====
            TextButton(
              onPressed: () {
                // ===== BUTTON CLICK SEQUENCE =====
                widget.game.audioManager
                    .playSound('click'); // Play click sound effect
                widget.game.quitGame(); // Về main menu (keep background stars)
                setState(() {
                  _opacity = 0.0; // Trigger fade out animation
                });
                // Note: Overlay sẽ tự động remove trong onEnd callback
              },

              // ===== BUTTON STYLING (GIỐNG NHƯ PLAY AGAIN) =====
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    vertical: 10, horizontal: 25), // Padding của button
                backgroundColor:
                    Colors.blue, // Nền màu xanh (styling nhất quán)
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(50), // Rounded corners (pill shape)
                ),
              ),

              // ===== BUTTON TEXT =====
              child: const Text(
                'QUIT GAME',
                style: TextStyle(
                  color: Colors.white, // White text trên blue background
                  fontSize: 28, // Large readable font
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===============================================
// 📝 IMPLEMENTATION NOTES
// ===============================================
//
// 🎯 USER FLOW:
// 1. Player dies → MyGame.playerDied() → overlays.add('GameOver')
// 2. GameOverOverlay shows với fade-in animation (500ms)
// 3. User nhấn button → play sound + action + fade out
// 4. Khi fade out xong → overlay tự động remove
//
// 🎨 DESIGN PRINCIPLES:
// - Semi-transparent background: không che khuất hoàn toàn game
// - Large fonts: dễ đọc trên mobile devices
// - Blue buttons: eye-catching nhưng không aggressive
// - Pill-shaped buttons: modern, friendly UI
//
// 🔊 AUDIO INTEGRATION:
// - Click sounds cho immediate feedback
// - Sử dụng AudioManager để consistent với game sounds
//
// 📱 RESPONSIVE CONSIDERATIONS:
// - Fixed font sizes: 48px title, 28px buttons
// - Works well trên phone/tablet/desktop
// - Center alignment: safe cho mọi screen ratio
