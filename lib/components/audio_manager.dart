import 'dart:async'; // Hỗ trợ async/await

import 'package:flame/components.dart'; // Flame component cơ bản
import 'package:flame_audio/flame_audio.dart'; // Flame audio system

// Class quản lý tất cả âm thanh trong game
class AudioManager extends Component {
  // Cài đặt âm thanh - có thể bật/tắt từ UI
  bool musicEnabled = true; // Có phát nhạc nền không?
  bool soundsEnabled = true; // Có phát sound effects không?

  // Hàm khởi tạo khi component được load vào game
  @override
  FutureOr<void> onLoad() async {
    // Khởi tạo background music player
    FlameAudio.bgm.initialize();
    return super.onLoad();
  }

  // Hàm phát nhạc nền
  void playMusic() {
    if (musicEnabled) {
      // Kiểm tra setting
      FlameAudio.bgm.play('music.ogg'); // Phát file nhạc nền
    }
  }

  // Hàm phát sound effect
  void playSound(String sound) {
    if (soundsEnabled) {
      // Kiểm tra setting
      FlameAudio.play('$sound.ogg'); // Phát file sound với tên được truyền vào
    }
  }

  void toggleMusic() {
    musicEnabled = !musicEnabled;
    if (musicEnabled) {
      playMusic();
    } else {
      FlameAudio.bgm.stop();
    }
  }

  void toggleSounds() {
    soundsEnabled = !soundsEnabled;
  }
}
