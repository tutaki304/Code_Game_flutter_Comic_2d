// Import các class cần thiết cho game
import 'package:cosmic_havoc/my_game.dart'; // Class chính quản lý game logic
import 'package:cosmic_havoc/overlays/game_over_overlay.dart'; // Màn hình khi thua game
import 'package:cosmic_havoc/overlays/title_overlay.dart'; // Màn hình chính khi mở game
import 'package:flame/game.dart'; // Flame game engine
import 'package:flutter/material.dart'; // Flutter UI framework
//CODE BY TUCODEDAO @tutaki304 
// Hàm main - điểm bắt đầu của ứng dụng Flutter
void main() {
  // Tạo instance của game chính
  final MyGame game = MyGame();

  // Khởi chạy ứng dụng Flutter với GameWidget
  runApp(GameWidget(
    game: game, // Truyền game instance vào
    overlayBuilderMap: {
      // Map các overlay (màn hình UI phủ lên game)
      // Overlay khi game over - hiện khi người chơi thua
      'GameOver': (context, MyGame game) => GameOverOverlay(game: game),
      // Overlay title - màn hình chào mừng ban đầu
      'Title': (context, MyGame game) => TitleOverlay(game: game),
    },
    initialActiveOverlays: const [
      'Title'
    ], // Overlay sẽ hiển thị đầu tiên (Title screen)
  ));
}


