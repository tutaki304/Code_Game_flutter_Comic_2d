import 'package:cosmic_havoc/my_game.dart'; // Game chính để truy cập game state
import 'package:flutter/material.dart'; // Flutter UI components

// TitleOverlay - Màn hình chính khi mở game
class TitleOverlay extends StatefulWidget {
  final MyGame game; // Reference tới game instance để điều khiển

  const TitleOverlay({super.key, required this.game});

  @override
  State<TitleOverlay> createState() => _TitleOverlayState();
}

// State class cho TitleOverlay
class _TitleOverlayState extends State<TitleOverlay> {
  double _opacity = 0.0; // Độ mờ cho hiệu ứng fade-in (0=trong suốt, 1=đầy đủ)

  // Hàm khởi tạo state - được gọi khi widget được tạo
  @override
  void initState() {
    super.initState();

    // Tạo hiệu ứng fade-in ngay sau khi widget được tạo
    Future.delayed(
      const Duration(milliseconds: 0), // Delay 0ms (ngay lập tức)
      () {
        setState(() {
          // Cập nhật state để trigger rebuild
          _opacity = 1.0; // Thay đổi opacity từ 0 -> 1 (hiện dần)
        });
      },
    );
  }

  // Hàm build UI - được gọi mỗi khi state thay đổi
  @override
  Widget build(BuildContext context) {
    // Lấy màu tàu hiện tại được chọn từ game
    final String playerColor =
        widget.game.playerColors[widget.game.playerColorIndex];

    // Widget chính với hiệu ứng fade
    return AnimatedOpacity(
      onEnd: () {
        // Callback khi animation kết thúc
        if (_opacity == 0.0) {
          // Nếu đang fade-out (opacity = 0)
          widget.game.overlays.remove('Title'); // Xóa overlay này khỏi game
        }
      },
      opacity: _opacity,
      duration: const Duration(milliseconds: 500),
      child: Container(
        alignment: Alignment.center,
        child: Column(
          children: [
            const SizedBox(height: 60),
            SizedBox(
              width: 270,
              child: Image.asset('assets/images/title.png'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () {
                    widget.game.audioManager.playSound('click');
                    setState(() {
                      widget.game.playerColorIndex--;
                      if (widget.game.playerColorIndex < 0) {
                        widget.game.playerColorIndex =
                            widget.game.playerColors.length - 1;
                      }
                    });
                  },
                  child: Transform.flip(
                    flipX: true,
                    child: SizedBox(
                      width: 30,
                      child: Image.asset('assets/images/arrow_button.png'),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 30, right: 30, top: 30),
                  child: SizedBox(
                    width: 100,
                    child: Image.asset(
                      'assets/images/player_${playerColor}_off.png',
                      gaplessPlayback: true,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    widget.game.audioManager.playSound('click');
                    setState(() {
                      widget.game.playerColorIndex++;
                      if (widget.game.playerColorIndex ==
                          widget.game.playerColors.length) {
                        widget.game.playerColorIndex = 0;
                      }
                    });
                  },
                  child: SizedBox(
                    width: 30,
                    child: Image.asset('assets/images/arrow_button.png'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                widget.game.audioManager.playSound('start');
                widget.game.startGame();
                setState(() {
                  _opacity = 0.0;
                });
              },
              child: SizedBox(
                width: 200,
                child: Image.asset('assets/images/start_button.png'),
              ),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            widget.game.audioManager.toggleMusic();
                          });
                        },
                        icon: Icon(
                          widget.game.audioManager.musicEnabled
                              ? Icons.music_note_rounded
                              : Icons.music_off_rounded,
                          color: widget.game.audioManager.musicEnabled
                              ? Colors.white
                              : Colors.grey,
                          size: 30,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            widget.game.audioManager.toggleSounds();
                          });
                        },
                        icon: Icon(
                          widget.game.audioManager.soundsEnabled
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                          color: widget.game.audioManager.soundsEnabled
                              ? Colors.white
                              : Colors.grey,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
