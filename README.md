# Okano's Shaders

Okano's Unity Shaders. Big mishmash of reworked, original, and mixed shaders.

Built and tested in Unity 5.6.3p1 & 2017.4.15f1 for VRChat, and partially tested in recent-ish 2018.

Most of these do not replace the real shaders for most uses, some of these are also archaic versions of these base shaders. There may be weird things that happen.

[Download the pack here](https://github.com/kayteh/shaders/releases/latest)

## Shaders

- **bLACK** - Literally just black.
- **Camo** - Sine wave lerp between two standard shaders.
- **Corrupted** - Moves vertices based on perlin noise, with gain, amount. WIP, will change a bit via feedback.
- **Corrupted Grabpass** - Corrupted but without a texture, just a grabpass. Used for geometry-based distortion.
- **Cubed Flat Lit Toon Stencil** - Stencil diffused version of FLT, with custom editor for helping it.
- **Double-sided Unlit** - Puts an unlit-ish texture on both sides of a mesh.
- **Halftone Toon** - *WIP as of 3/Jan/2019* - An *okay* toon shader in the style of Spider-Man Noir from Into the Spiderverse movie.
- **LUT Rim Lighting** - Use for edgy darkness with an outline when you're closer to it, LUT ramp included.
- **NoeNoe/Emission Scroll** - Applies the overlay texture scroll mechanics to the emission map.
- **NoeNoe/Opaque Unlit** - *Formerly "Rework"* - Removes lighting calculations in lieu of configurable white light.
- **NoeNoe/Opaque Unlit GIF** - Unlit + Snail GIF overlay, because every effect is not enough effects.
- **NoeNoe/Opaque Stencil** - Stencil diffused version of NoeNoe.
- **NoeNoe/Opaque Sparkle** - Applies a controllable perlin noise light filter over the emission map.
- **NoeNoe/Toon Opaque Sparkle** - Cheaper version of the original NoeNoe with sparkle.
- **NoeNoe/Toon Opaque Eyes** - Highly configurable eye emote and *okay* particle shader based on NoeNoe Toon
- **NoeNoe/Toon Opaque Iridescent** - Triplanar-ish reflections on top of NoeNoe Toon.
- **Silent Flat Lit Toon Sparkle** - Silent's FLT with sparkle, with custom editor.
- **Silent Flat Lit Toon Iridescent** - **SCUFFED** Older try at iridescent, please use NoeNoe Toon Iridescent for the same effect.
- **Stencil Mask** - Helper shader for mask materials, allows per-material Ref values.
- **Transparent** - Very efficient way to throw away pixels for lazy people.
- **Wireframe Overlay** - ([See docs](https://github.com/kayteh/shaders/blob/master/Docs/Wireframe.md)) An optionally shaded wireframe overlay texture with a scrolling wireframe texture.

### Libraries

- **Sparkle** - Effect processor for sparkle effect
- **SimplexNoise** - Noise generators

### Experiments

- **Simple Lit Toon** - R&Ding a toon shader from scratch.
- **Deep Fried** - A very very very very meme-y shader. Fakes JPEG crushing and yellowing. Use at your own risk.
- **Scuffed Glitter** - **SCUFFED** glitter-y effect. WIP.

### TODO

## Examples

### NoeNoe Opaque Unlit

<a href="https://gfycat.com/BronzeLawfulBedbug" target="_blank"><img src="https://thumbs.gfycat.com/BronzeLawfulBedbug-size_restricted.gif" /></a>  
([Higher Res](https://gfycat.com/BronzeLawfulBedbug))

### Sparkle variants

<a href="https://gfycat.com/PartialPastelArabianoryx" target="_blank"><img src="https://thumbs.gfycat.com/PartialPastelArabianoryx-size_restricted.gif" /></a>  
([Higher Res](https://gfycat.com/PartialPastelArabianoryx))


### Wireframe Overlay

<a href="https://gfycat.com/WeirdGlaringHake" target="_blank"><img src="https://thumbs.gfycat.com/WeirdGlaringHake-size_restricted.gif" /></a>  
([Higher Res](https://gfycat.com/WeirdGlaringHake))


## Hat Tips

- CubedParadox's [Flat Lit Toon](https://github.com/cubedparadox/Cubeds-Unity-Shaders)
- NoeNoe's [Overlay Shaders](https://vrcat.club/threads/updated-2-2-18-noenoe-overlay-shaders.157/)
- Bail's emotional support
- VRChat friends that stare into my eyes

## Want to support me?

Tips help me live, and living means I can keep making pretty shaders. It's all appreciated, and I'll totally send you a thank you note.

[PayPal](https://paypal.me/kayteh/5)  
[Patreon](https://patreon.com/kata/overview)
