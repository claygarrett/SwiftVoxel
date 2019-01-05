/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Header defining preprocessor conditional values that control the configuration of the app
 */

// When enabled, performs specular lighting calculations for the directional light (i.e. the sun).
// When disabled, the directional light only contributes diffuse values.
#define APPLY_DIRECTIONAL_SPECULAR      1

// When enabled, writes depth values in eye space to the g-buffer depth component. This allows the
// deferred pass to calculate the eye space fragment position more easily in order to apply lighting.
// When disabled, the screen depth is written to the g-buffer depth component and an extra inverse
// transform from screen space to eye space is necessary to calculate lighting contributions in
// the deferred pass.
#define USE_EYE_DEPTH                   1

// Whether enabled or disabled, point lighting calculations are always done in the deferred pass.
// When enabled, all lighting, including directional lighting, is done in the deferred pass.
// When disabled, directional lighting is performed in the g-buffer pass. This may use more bandwidth
// because the lighting calculations in the g-buffer pass must be written to a texture. However, If
// depth complexity is low and depending on the GPU architecture, it can sometimes be beneficial to
// perform the directional lighting in the g-buffer pass.
#define DEFER_ALL_LIGHTING              1

// When enabled, uses the stencil buffer to avoid execution of lighting calculations on fragments
// that do not intersect with a 3D light volume.
// When disabled, all fragments covered by a light in screen space will have lighting calculations
// executed. This means that considerably more fragments will have expensive lighting calculations
// executed than is actually necessary.
#define LIGHT_STENCIL_CULLING           1

// Enables toggling of buffer examination mode at runtime. Code protected by this definition
// is only useful to examine parts of the underlying implementation (i.e. it's a debug feature).
#define SUPPORT_BUFFER_EXAMINATION_MODE 1
