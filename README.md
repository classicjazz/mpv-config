# mpv-config

This is a collection of MPV configuration files, intended for high quality video rendering of traditional video. Beyond upscaling, my configuration files include optimizations for resolution, colorspace, dithering, debanding, motion interpolation, and anti-ringing.

For now, these files are tailored for rendering on Macs (e.g. current Macbooks and iMacs) that do not support Vulkan. Therefore, OpenGL is enabled. In the future, I hope to solve for Mac's deprecated OpenGL subsystem by either supporting MoltenVK or Metal, directly.

On Macs, you can download and install them in your ~[user profile]/.config/mpv folder.

If you have a Vulkan-enabled device, you can uncomment the relevant lines to use that graphics subsystem instead of OpenGL. 

For more details, see https://freetime.mikeconnelly.com/archives/5371
