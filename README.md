# mpv-config

This is a collection of MPV configuration files, intended for high quality rendering of traditional live TV and video disc formats. Beyond upscaling, my configuration files include optimizations for resolution, colorspace, dithering, debanding, motion interpolation, and anti-ringing. Additionally, FFMPEG’s bwdif filter for motion adaptive deinterlacing is applied to interlaced video, such as live TV.

My mpv.conf is tailored for rendering on current Macbooks and iMacs including using vo_gpu_next, libplacebo, Vulkan & MoltenVK for enhanced performance, as compared to legacy OpenGL rendering.

Your performance will vary depending on the Mac that you use. You may need to disable shaders. On Macs, you can download and install them in your ~[user profile]/.config/mpv folder.

For more details including performance benchmarks, see https://freetime.mikeconnelly.com/archives/5371
