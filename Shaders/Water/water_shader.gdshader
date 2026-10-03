shader_type canvas_item;

// Captures the background behind the water geometry EXACTLY ONCE
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

// Noise textures for the swirl / wave ripple step
uniform sampler2D noise_texture : repeat_enable, filter_linear_mipmap;
uniform vec2 wave_speed = vec2(0.05, 0.1);
uniform float wave_strength : hint_range(0.0, 0.1, 0.001) = 0.02;
uniform vec2 noise_scale = vec2(1.0, 1.0);

// Blur settings
uniform float blur_scale : hint_range(0.0, 10.0) = 2.0;

// Tint Settings
uniform vec4 tint : source_color = vec4(1.0, 0.0, 1.0, 0.3);

// --- PLAYER LAGGED VELOCITY & AREA UNIFORMS ---
uniform vec2 player_screen_pos; // Normalized screen position of the player
uniform vec2 lagged_velocity;   // Passed from script, represents lagging movement vector
uniform float effect_radius : hint_range(0.0, 0.5) = 0.15; // Bounding size around player
uniform float velocity_drag_strength : hint_range(0.0, 0.005) = 0.001; // Scaler for velocity distortion

void fragment() {
    // ----------------------------------------------------
    // STEP 1: ANIMATED NOISE & LOCALIZED MOMENTUM DISTORTION
    // ----------------------------------------------------
    
    // 1. Calculate a mask centered around the player's screen position
    vec2 to_player = SCREEN_UV - player_screen_pos;
    float dist = length(to_player);
    // Smoothstep creates a soft radius fade that falls off perfectly to 0.0 at the edges
    float local_mask = smoothstep(effect_radius, 0.0, dist);
    
    // 2. Calculate localized distortion vector
    // Multiplying velocity by the local_mask restricts the pulling effect to just around the player
    vec2 velocity_distortion = lagged_velocity * velocity_drag_strength * local_mask * 0.1;
    
    // 3. Shift the noise map coordinates LOCALLY. 
    // Because velocity_distortion goes to zero outside the mask and when stopping, 
    // the noise layout remains anchored and perfectly snaps back to its default state.
    vec2 moved_uv = (SCREEN_UV * noise_scale) + (wave_speed * TIME) - velocity_distortion;
    vec2 noise_val = texture(noise_texture, moved_uv).rg * 2.0 - 1.0;
    
    // 4. Combine ambient water noise with local background screen texture pulling
    vec2 distorted_uv = SCREEN_UV + (noise_val * wave_strength) - velocity_distortion;

    // ----------------------------------------------------
    // STEP 2: HIGH-PERFORMANCE 2-PASS SEPARATED BLUR APPLIED SEGMENTALLY
    // ----------------------------------------------------
    vec2 ps = SCREEN_PIXEL_SIZE * blur_scale;

    // --- PASS A: Horizontal Blur Step ---
    vec4 h_blur = vec4(0.0);
    h_blur += texture(screen_texture, distorted_uv + vec2(-ps.x, 0.0));
    h_blur += texture(screen_texture, distorted_uv + vec2(0.0, 0.0));
    h_blur += texture(screen_texture, distorted_uv + vec2(ps.x, 0.0));
    vec4 step_1_out = h_blur / 3.0;

    // --- PASS B: Vertical Blur Step (Fed directly by the output coordinates) ---
    vec4 v_blur = vec4(0.0);
    v_blur += texture(screen_texture, distorted_uv + vec2(0.0, -ps.y));
    v_blur += texture(screen_texture, distorted_uv + vec2(0.0, 0.0));
    v_blur += texture(screen_texture, distorted_uv + vec2(0.0, ps.y));
    vec4 blurred_background = (step_1_out + v_blur) / 3.0;

    // ----------------------------------------------------
    // STEP 3: TINT MIXING OVERLAY (Your Tint Math)
    // ----------------------------------------------------
    vec4 boosted_tint = mix(vec4(0.5), tint, 1.4);
    vec3 mixed_rgb = mix(blurred_background.rgb, boosted_tint.rgb, tint.a);

    // ----------------------------------------------------
    // STEP 4: FIT TO DYNAMIC POLYGON PHYSICS (The Edge Clip)
    // ----------------------------------------------------
    COLOR = vec4(mixed_rgb, texture(TEXTURE, UV).a);
}
