# NEJE Laser Engraver

The Neje Laser Engraver DK-8-PRO is an awesome small laser engraver from China.  Unfortunately, the supplied app is Windows only.  There is an OSX App called DBeam available however some functions don't work with my DK-8 (movement keys), and I wanted a little more flexability over the image importing.

So, with a combination of the supported Hex commands (found from https://github.com/AxelTB/nejePrint - commands.txt), and listening to the serial port I wrote my own.

## Features
 - Image importing
 - Auto-resize
 - Dithering or average pixel color settings
 - Editing of imported image
 - Real time progress preview of engraving image

## Requirements
It requires an OSX Serial USB driver - I used the one from here (working on OSX Sierra 10.12.1):  
[https://github.com/adrianmihalko/ch340g-ch34g-ch34x-mac-os-x-driver](https://github.com/adrianmihalko/ch340g-ch34g-ch34x-mac-os-x-driver)


## Usage:
1. Launch app
2. Drag image into preview
3. Connect printer and then press refresh button (engraver should be auto-discovered)
4. Press Connect button to connect to engraver
5. Press Upload button to upload image to engraver
6. Press Start to start engraving process.
