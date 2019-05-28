# mpv-config

This is a collection of MPV configuration files, intended for high quality rendering of traditional live TV and video disc formats. Beyond upscaling, my configuration files include optimizations for resolution, colorspace, dithering, debanding, motion interpolation, and anti-ringing. Additionally, FFMPEG’s bwdif filter for motion adaptive deinterlacing is applied to interlaced video, such as live TV.

For now, my mpv.conf is tailored for rendering on Macs (e.g. current Macbooks and iMacs). Because Macs do not support Vulkan and MPV does not support Metal, Mac's deprecated OpenGL subsystem is used. Your performance will vary depending on the Mac that you use. You may need to disable shaders. On Macs, you can download and install them in your ~[user profile]/.config/mpv folder.

My long term goal is to optimize MPV for Apple TV and 4K displays. For this, a Metal RA is a dependancy.

If you have a Vulkan-enabled device (e.g. Windows or Linux), you can uncomment the relevant lines to use that graphics subsystem instead of OpenGL. If you are using Windows or have your configuration files in a different location, then you should modify mpv.conf accordingly. 

For more details including performance benchmarks, see https://freetime.mikeconnelly.com/archives/5371
