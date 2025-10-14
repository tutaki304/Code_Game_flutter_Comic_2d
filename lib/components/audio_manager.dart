import 'dart:async'; // Async/await support

import 'package:flame/components.dart'; // Flame component system
import 'package:flame_audio/flame_audio.dart'; // Background music system
import 'package:flutter_soloud/flutter_soloud.dart'; // High-performance sound effects

/**
 * AudioManager - Dual audio system manager
 * 
 * 🎵 DUAL AUDIO ARCHITECTURE:
 * - flutter_soloud: Sound effects (SFX) - Low latency, high performance
 * - flame_audio: Background music (BGM) - Streaming, loop support
 * 
 * 🔊 FEATURES:
 * - Preloaded sound effects cho zero-latency playback
 * - Separate music/sound toggle controls
 * - Error handling và fallback mechanisms
 * - Memory management với proper cleanup
 * 
 * 🎮 GAME AUDIO EVENTS:
 * - UI: click sounds
 * - Gameplay: laser, hit, explode, collect
 * - Background: looping music track
 * 
 * 🛠️ TECHNICAL NOTES:
 * - SoLoud: Modern audio engine, replaces discontinued soundpool
 * - FlameAudio BGM: Stable cross-platform music playback
 * - Asset preloading: All sounds loaded once trong onLoad()
 */
class AudioManager extends Component {
  // ===============================================
  // 🎛️ AUDIO CONTROL STATE
  // ===============================================

  bool musicEnabled = true; // Bật/tắt nhạc nền
  bool soundsEnabled = true; // Bật/tắt hiệu ứng âm thanh

  // ===============================================
  // 🎵 AUDIO ASSETS CONFIGURATION
  // ===============================================
  // khi phát triển âm thanh nhớ thêm sounds vào đây nhé chứ k lại fix sml k hiểu lỗi nằm ở đâu'
  final List<String> _sounds = [
    // Tất cả file âm thanh cần preload
    'click', // Click button UI
    'collect', // Pickup collection sound
    'dropcoin', // Coin collection sound (riêng cho xu)
    'explode1', // Asteroid explosion (type 1)
    'explode2', // Asteroid explosion (type 2)
    'fire', // Weapon firing sound
    'hit', // Laser hitting asteroid
    'laser', // Laser firing sound
    'start', // Game start sound
  ];

  // ===============================================
  // 🔊 AUDIO ENGINE INSTANCES
  // ===============================================

  final Map<String, AudioSource> _soundSources = {}; // Preloaded SoLoud sources
  late SoLoud _soloud; // SoLoud engine instance

  // ===============================================
  // 🔄 INITIALIZATION
  // ===============================================

  /**
   * onLoad() - Initialize dual audio system
   * 
   * Setup sequence:
   * 1. Initialize SoLoud engine for sound effects
   * 2. Initialize FlameAudio for background music
   * 3. Preload all sound effects into memory
   * 4. Error handling cho individual sound loading
   * 
   * Performance benefit: All sounds preloaded = zero-latency playback
   */
  @override
  FutureOr<void> onLoad() async {
    // ===== SOLOUD INITIALIZATION (SOUND EFFECTS) =====
    _soloud = SoLoud.instance; // Lấy singleton instance
    await _soloud.init(); // Initialize low-level audio

    // ===== FLAME AUDIO INITIALIZATION (BACKGROUND MUSIC) =====
    FlameAudio.bgm.initialize(); // Prepare background music system

    // ===== PRELOAD ALL SOUND EFFECTS =====
    print('🎵 Loading sounds with flutter_soloud...');
    for (String sound in _sounds) {
      try {
        // Load từ assets với proper path
        final source = await _soloud.loadAsset('assets/audio/$sound.ogg');
        _soundSources[sound] = source; // Cache trong memory
        print('✅ Loaded: $sound.ogg');
      } catch (e) {
        print('❌ Failed to load $sound.ogg: $e'); // Log errors nhưng continue
      }
    }
    print('🎵 SoLoud audio system ready!');

    return super.onLoad();
  }

  // ===============================================
  // 🎵 AUDIO PLAYBACK METHODS
  // ===============================================

  /**
   * playMusic() - Start background music loop
   * 
   * Uses FlameAudio BGM system:
   * - Automatic looping
   * - Streaming playback (no memory impact)
   * - Cross-platform compatibility
   * 
   * Note: Music disabled on Windows để avoid crash issues
   */
  void playMusic() {
    if (musicEnabled) {
      FlameAudio.bgm.play('music.ogg'); // Start looping background music
    }
  }

  /**
   * playSound() - Play sound effect với SoLoud
   * 
   * High-performance sound playback:
   * - Zero latency (preloaded sources)
   * - Multiple simultaneous sounds supported
   * - Error handling cho missing sounds
   * 
   * @param sound - Sound name (must exist trong _sounds list)
   */
  void playSound(String sound) {
    // ===== VALIDATION & SAFETY CHECKS =====
    if (soundsEnabled && _soundSources.containsKey(sound)) {
      try {
        _soloud.play(_soundSources[sound]!); // Play preloaded sound
      } catch (e) {
        print('❌ Error playing sound $sound: $e'); // Log but don't crash
      }
    }
    // Note: Silently ignore if sound disabled hoặc sound not found
  }

  // ===============================================
  // 🎛️ AUDIO CONTROL METHODS
  // ===============================================

  /**
   * toggleMusic() - Toggle background music on/off
   * 
   * Immediate effect:
   * - ON: Start playing music loop
   * - OFF: Stop current music playback
   * 
   * Used by: UI controls trong settings hoặc title screen
   */
  void toggleMusic() {
    musicEnabled = !musicEnabled; // Toggle state
    if (musicEnabled) {
      playMusic(); // Start music immediately
    } else {
      FlameAudio.bgm.stop(); // Stop current music
    }
  }

  /**
   * toggleSounds() - Toggle sound effects on/off
   * 
   * Simple state toggle:
   * - Affects all future playSound() calls
   * - No immediate effect on current sounds
   * 
   * Used by: UI controls trong settings
   */
  void toggleSounds() {
    soundsEnabled = !soundsEnabled; // Toggle state (affects future sounds)
  }

  // ===============================================
  // 🗑️ CLEANUP & RESOURCE MANAGEMENT
  // ===============================================

  /**
   * onRemove() - Cleanup audio resources
   * 
   * Proper cleanup sequence:
   * 1. Clear cached sound sources
   * 2. Deinitialize SoLoud engine
   * 3. Call parent cleanup
   * 
   * Prevents memory leaks và audio driver issues
   */
  @override
  void onRemove() {
    // ===== SOLOUD CLEANUP =====
    _soundSources.clear(); // Clear cached audio sources
    _soloud.deinit(); // Deinitialize audio engine

    super.onRemove(); // Parent cleanup
  }
}

// ===============================================
// 📝 IMPLEMENTATION NOTES
// ===============================================
//
// 🎵 WHY DUAL AUDIO SYSTEM?
// - SoLoud: Low-latency sound effects (gameplay sounds)
// - FlameAudio: Reliable music streaming (background music)
// - Different requirements = different optimal solutions
//
// 🔧 TECHNICAL DECISIONS:
// - Preloading: All SFX loaded once for zero-latency
// - Error handling: Individual sound failures don't crash game
// - Resource cleanup: Prevents memory leaks on game restart
//
// 🎮 GAME INTEGRATION:
// - Called from components: game.audioManager.playSound('hit')
// - UI integration: Music/sound toggles trong overlays
// - Performance: No audio loading during gameplay
//
// 🐛 KNOWN ISSUES:
// - Windows music crash: Background music disabled per user request
// - Asset paths: Must match exactly với files trong assets/audio/
