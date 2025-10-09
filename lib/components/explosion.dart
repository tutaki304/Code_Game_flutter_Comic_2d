import 'dart:async'; // Async/await support
import 'dart:math'; // Random number generation

import 'package:cosmic_havoc/my_game.dart'; // Game instance access
import 'package:flame/components.dart'; // Flame components
import 'package:flame/effects.dart'; // Animation effects
import 'package:flame/particles.dart'; // Particle system
import 'package:flutter/widgets.dart'; // Color class

/**
 * ExplosionType - Enum defines explosion visual styles
 * 
 * 💥 EXPLOSION TYPES:
 * - dust: Brown particles (asteroid destruction)
 * - smoke: Gray particles (general explosions) 
 * - fire: Yellow/orange particles (intense explosions)
 */
enum ExplosionType { dust, smoke, fire }

/**
 * Explosion - Visual effect system cho destruction events
 * 
 * 💥 CHỨC NĂNG CHÍNH:
 * - Multi-layered explosion effects (flash + particles)
 * - Type-based visual variation (dust/smoke/fire)
 * - Size scaling based on source object
 * - Audio integration với random explosion sounds
 * 
 * 🎆 VISUAL COMPONENTS:
 * 1. Flash effect: Bright white circle (immediate impact)
 * 2. Particle system: Scattered colored particles (debris)
 * 3. Auto-cleanup: Removes after 1 second
 * 
 * 🎨 PARTICLE PHYSICS:
 * - Count: 8-12 particles (random variation)
 * - Movement: Radial scatter from center point
 * - Colors: Type-specific color palettes
 * - Lifespan: 0.5-1.0 seconds (random variation)
 * 
 * 🔊 AUDIO INTEGRATION:
 * - Random explosion sounds (explode1.ogg, explode2.ogg)
 * - Immediate audio feedback on creation
 * 
 * 🎮 USAGE SCENARIOS:
 * - Asteroid destruction (dust type)
 * - Player death (fire type)
 * - Bomb detonation (smoke type)
 * - General impact effects
 */
class Explosion extends PositionComponent with HasGameReference<MyGame> {
  // ===============================================
  // 💥 EXPLOSION PROPERTIES
  // ===============================================

  final ExplosionType explosionType; // Visual style (dust/smoke/fire)
  final double explosionSize; // Factor tỷ lệ kích thước
  final Random _random = Random(); // Random generator cho biến thể

  // ===============================================
  // 🏗️ CONSTRUCTOR
  // ===============================================

  /**
   * Explosion Constructor - Tạo explosion tại specified location
   * 
   * @param position - Explosion center point
   * @param explosionSize - Size scaling (larger = bigger explosion)
   * @param explosionType - Visual style (dust/smoke/fire)
   */
  Explosion({
    required super.position,
    required this.explosionSize,
    required this.explosionType,
  });

  // ===============================================
  // 🔄 INITIALIZATION & EFFECTS
  // ===============================================

  /**
   * onLoad() - Initialize explosion với complete effect sequence
   * 
   * Effect creation sequence:
   * 1. Play random explosion sound (explode1 or explode2)
   * 2. Create bright flash effect (immediate visual impact)
   * 3. Generate particle system (debris scatter)
   * 4. Schedule auto-removal (cleanup after 1 second)
   * 
   * Audio variety: 2 different explosion sounds for variation
   */
  @override
  FutureOr<void> onLoad() {
    // ===== AUDIO FEEDBACK =====
    final int num = 1 + _random.nextInt(2); // Random 1 or 2
    game.audioManager
        .playSound('explode$num'); // Play explode1.ogg hoặc explode2.ogg

    // ===== VISUAL EFFECTS CREATION =====
    _createFlash(); // Bright white flash effect
    _createParticles(); // Colored particle debris

    // ===== AUTO-CLEANUP =====
    add(RemoveEffect(delay: 1.0)); // Remove after 1 second

    return super.onLoad();
  }

  // ===============================================
  // 🔆 FLASH EFFECT CREATION
  // ===============================================

  /**
   * _createFlash() - Create bright white flash cho immediate visual impact
   * 
   * Flash properties:
   * - Size: 60% of explosion size (proportional scaling)
   * - Color: Pure white (maximum brightness)
   * - Duration: 0.3 seconds fade out
   * - Shape: Circle (classic explosion flash)
   * 
   * Purpose: Immediate visual feedback before particles appear
   */
  void _createFlash() {
    // ===== FLASH CIRCLE CREATION =====
    final CircleComponent flash = CircleComponent(
      radius: explosionSize * 0.6, // 60% of explosion size
      paint: Paint()
        ..color = const Color.fromRGBO(255, 255, 255, 1.0), // Pure white
      anchor: Anchor.center, // Center on explosion point
    );

    // ===== FADE OUT ANIMATION =====
    final OpacityEffect fadeOutEffect = OpacityEffect.fadeOut(
      EffectController(duration: 0.3), // Quick fade (300ms)
    );

    flash.add(fadeOutEffect); // Áp dụng fade cho flash
    add(flash); // Thêm flash vào explosion
  }

  // ===============================================
  // 🎨 COLOR PALETTE GENERATION
  // ===============================================

  /**
   * _generateColors() - Get color palette based on explosion type
   * 
   * Color palettes cho different explosion contexts:
   * - DUST: Brown shades (asteroid destruction debris)
   * - SMOKE: Gray shades (general explosion smoke)  
   * - FIRE: Yellow/orange shades (intense fire explosion)
   * 
   * Each palette has 3 colors để variation trong particles
   */
  List<Color> _generateColors() {
    switch (explosionType) {
      case ExplosionType.dust:
        // ===== DUST COLORS (BROWN SHADES) =====
        return [
          const Color(0xFF5A4632), // Dark brown
          const Color(0xFF6B543D), // Medium brown
          const Color(0xFF8A6E50), // Light brown
        ];
      case ExplosionType.smoke:
        // ===== SMOKE COLORS (GRAY SHADES) =====
        return [
          const Color(0xFF404040), // Dark gray
          const Color(0xFF606060), // Medium gray
          const Color(0xFF808080), // Light gray
        ];
      case ExplosionType.fire:
        // ===== FIRE COLORS (YELLOW/ORANGE SHADES) =====
        return [
          const Color(0xFFFFD700), // Gold yellow
          const Color(0xFFFFA500), // Orange
          const Color(0xFFFFC107), // Amber
        ];
    }
  }

  // ===============================================
  // 🎆 PARTICLE SYSTEM CREATION
  // ===============================================

  /**
   * _createParticles() - Generate scattered particle debris system
   * 
   * Particle generation:
   * 1. Get type-specific color palette
   * 2. Create 8-12 particles (random count)
   * 3. Each particle: random color, size, direction, lifespan
   * 
   * Particle physics:
   * - Movement: Radial scatter from center (explosion outward)
   * - Size: 10-15% of explosion size (proportional scaling)
   * - Alpha: 40-80% transparency (semi-transparent debris)
   * - Lifespan: 0.5-1.0 seconds (realistic debris fall time)
   */
  void _createParticles() {
    // ===== COLOR PALETTE =====
    final List<Color> colors = _generateColors(); // Lấy màu theo loại explosion

    // ===== PARTICLE SYSTEM CREATION =====
    final ParticleSystemComponent particles = ParticleSystemComponent(
      particle: Particle.generate(
        count: 8 + _random.nextInt(5), // 8-12 particles (random variation)
        generator: (index) {
          return MovingParticle(
            // ===== PARTICLE VISUAL PROPERTIES =====
            child: CircleParticle(
              paint: Paint()
                ..color = colors[_random.nextInt(colors.length)].withValues(
                  alpha: 0.4 + _random.nextDouble() * 0.4, // Alpha: 40-80%
                ),
              radius: explosionSize *
                  (0.1 +
                      _random.nextDouble() * 0.05), // Size: 10-15% of explosion
            ),
            // ===== PARTICLE MOVEMENT =====
            to: Vector2(
              (_random.nextDouble() - 0.5) *
                  explosionSize *
                  2, // X: Random scatter
              (_random.nextDouble() - 0.5) *
                  explosionSize *
                  2, // Y: Random scatter
            ),
            // ===== PARTICLE LIFESPAN =====
            lifespan: 0.5 + _random.nextDouble() * 0.5, // 0.5-1.0 seconds
          );
        },
      ),
    );

    add(particles); // Thêm hệ thống particle vào explosion
  }
}

// ===============================================
// 📝 IMPLEMENTATION NOTES
// ===============================================
//
// 💥 EXPLOSION VISUAL DESIGN:
// - Flash + particles = realistic explosion feel
// - Type-based colors = contextual visual feedback
// - Size scaling = consistent với source object importance
//
// 🎨 PARTICLE PHYSICS SIMULATION:
// - Radial scatter: Mimics real explosion debris
// - Random variation: No two explosions look identical
// - Alpha transparency: Realistic semi-solid debris
//
// 🔊 AUDIO INTEGRATION:
// - Two explosion sounds prevent monotony
// - Immediate audio feedback enhances impact
//
// 🎮 GAMEPLAY INTEGRATION:
// - Called by asteroid destruction, player death
// - Size parameter allows scaling cho different events
// - Auto-cleanup prevents performance issues
//
// 🔧 PERFORMANCE CONSIDERATIONS:
// - Limited particle count (8-12) cho mobile performance
// - Short lifespan (max 1s) prevents accumulation
// - Auto-removal (1s) ensures cleanup
