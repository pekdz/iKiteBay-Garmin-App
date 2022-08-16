# iKiteBay for Garmin watch
This is an app for Garmin watches that shows live wind sensor readings and tide data from iKitesurf.com. 

This is designed for SF Bay Area kitesurfers for private usage, only two kite spots are supported now.

- 3rd Avenue
- Sunnyvale Pond

# Demo

![](https://github.com/pekdz/iKiteBay-Garmin-App/raw/master/resources/images/demo.gif)

# How to install

This App is not submited to Garmin ConnectIQ store, user has to download the source code, modify config.mc file with your own weatherflow API key and iKitesurf credentials, compile the `prg` package and upload to the your watch App folder via USB cable.

To build the App package, you need to install - 
- [Garmin SDK](https://developer.garmin.com/connect-iq/sdk/)
- [Virtual Studio Code](https://code.visualstudio.com/download)
- [Monkey C plugin](https://marketplace.visualstudio.com/items?itemName=garmin.monkey-c)

# How to use

To use the app, a Pro/Plus/Gold account from iKitesurf is required, and the following weather stations need to be added into your favorite profile in your iKitesutf account - 

- 3rd Ave
  - 3rd Ave Beach
  - 3rd Ave Channel
- Pond
  - Palo Alto
  - San Jose Airport
  - Moffett NASA
  - Shoreline Lake

# Weatherflow API key
Before compiling this project you need to add your WeatherFlow API key to the config.mc file.
Contact WeatherFlow (support@weatherflow.com) to obtain an API key.
Then copy the file config.mc.template to config.mc (in source folder) and add your API to the file.
