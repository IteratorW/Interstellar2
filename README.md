# Latest changelog
* Added "Auto correct" feature to Jump Menu. With this enabled, your movement coords will be corrected as if your ship had X: 1 Z: 0 orientation.
* Fixed wrong destination coordinates in InterstellarProxy if your ship orientation is not X: 1 Z: 0.

# Interstellar2
Interstellar 2 is something like Desktop Environment created to control WarpDrive ships and other components with comfort.

![alt text](https://raw.githubusercontent.com/IteratorW/Interstellar2/master/Pictures/preview.png)

## Installing
`pastebin run 1bVb0fvh`

Please note that you need OpenOS and full level 3 computer for this program.

## Features (sorted by urgency)
- [x] Ship info window
- [x] Ship jump window
- [x] WarpDrive Radar control
- [x] Matter Overdrive Transporter support to easily set coordinates from a WarpRadar scan. (rightclick on a list entry!)
- [x] Logging to Discord using InterstellarProxy
- [x] Full ship settings window
- [ ] Color schemes
- [ ] Other ship features such as crew management
- [ ] Map, showing your ship, planets, other ships, etc.
- [ ] Other WarpDrive components support, such as cloaking device, lasers, etc.

## MO Transporter Notes
Matter Overdrive Transporter support might be buggy at times. Entered coordinates are not being displayed in the transporter since its api is a buggy mess.

To connect a transporter to your computer, you need to use an adapter.

Before setting the points in IS2, remove all points from the transporter and create only one. Don't change it. After that you can start using it in the program.

# Interstellar2 Wrapper
Interstellar2 Wrapper is a library that wraps all components used by IS2 into one library. It is useful in cases when the API of some component changes thus requiring no rewrite in main program.

# InterstellarProxy
InterstellarProxy is a Python web server created to proxy OpenComputers requests to send messages to discord. It is required since Discord API refuses all requests
made from OpenComputers.

![alt text](https://raw.githubusercontent.com/IteratorW/Interstellar2/master/Pictures/is_proxy_preview.png)

## Features
- [x] Embed support
