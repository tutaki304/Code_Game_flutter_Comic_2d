import 'dart:async';

import 'package:flame/components.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

class AudioManager extends Component {
  bool musicEnabled = true;
  bool soundsEnabled = true;

  final List<String> _sounds = [
    'click',
    'collect',
    'explode1',
    'explode2',
    'fire',
    'hit',
    'laser',
    'start',
  ];

  final Map<String, AudioSource> _soundSources = {};
  late SoLoud _soloud;

  @override
  FutureOr<void> onLoad() async {
    // Khởi tạo SoLoud
    _soloud = SoLoud.instance;
    await _soloud.init();

    FlameAudio.bgm.initialize();

    print('🎵 Loading sounds with flutter_soloud...');
    // Load sound effects với SoLoud
    for (String sound in _sounds) {
      try {
        final source = await _soloud.loadAsset('assets/audio/$sound.ogg');
        _soundSources[sound] = source;
        print('✅ Loaded: $sound.ogg');
      } catch (e) {
        print('❌ Failed to load $sound.ogg: $e');
      }
    }
    print('🎵 SoLoud audio system ready!');

    return super.onLoad();
  }

  void playMusic() {
    if (musicEnabled) {
      FlameAudio.bgm.play('music.ogg');
    }
  }

  void playSound(String sound) {
    if (soundsEnabled && _soundSources.containsKey(sound)) {
      try {
        _soloud.play(_soundSources[sound]!);
      } catch (e) {
        print('❌ Error playing sound $sound: $e');
      }
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

  @override
  void onRemove() {
    // Cleanup SoLoud resources
    _soundSources.clear();
    _soloud.deinit();
    super.onRemove();
  }
}
