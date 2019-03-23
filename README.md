# mpv-config

This is a collection of MPV configuration files, intended for high quality rendering of traditional live TV and video disc formats. Beyond upscaling, my configuration files include optimizations for resolution, colorspace, dithering, debanding, motion interpolation, and anti-ringing. And, it applies FFMPEG’s bwdif filter for motion adaptive deinterlacing of interlaced video, such as live TV.

For now, the mpv.conf is tailored for rendering on Macs (e.g. current Macbooks and iMacs). Because they do not support Vulkan, OpenGL is enabled. In the future, I hope to solve for Mac's deprecated OpenGL subsystem by either supporting MoltenVK or Metal, directly.

On Macs, you can download and install them in your ~[user profile]/.config/mpv folder.

If you have a Vulkan-enabled device, you can uncomment the relevant lines to use that graphics subsystem instead of OpenGL. If you are using Windows or have your configuration files, you should modify mpv.conf accordingly. 

For more details, see https://freetime.mikeconnelly.com/archives/5371
