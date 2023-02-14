# pixivswift
A port of [upbit's pixivpy](https://github.com/upbit/pixivpy) library.

## Disclaimer

This whole piece is provided as is, and I am not responsible for any psychological/physical damage or law violations, i. e. hardware damage or consumption of questionable content.

Also, please do not overuse this. Pixiv has no financial benefit from this, and they somehow have to finance their servers, too...

## Features

- ~~Headless login~~for now, please use the [pixivauth executable target or build your own login process from it](https://github.com/thebreadcompany/pixivloader)
- Access to ~~both the public API (deprecated) and~~ the API used by the Pixiv app 
- Directly download images (although ugoiras (GIFs) require further handling, see below)

## Installation

### Swift Package Manager
- simply add https://github.com/theBreadCompany/pixivswift.git to Xcode or
- add `.package(url: "https://github.com/theBreadCompany/pixivswift.git", from: "1.1.0")` to your Package.swift dependencies

## Documentation

The project is documented, everything can be found in Xcode's Developer Documentation (```shift```+```cmd```+```0```) 

### Notes
- The PublicAPI is deprecated and will receive no further support.
- ugoiras are essentially image sequences which have to be assembled manually -> the image urls contain a link to a zip file containing the images. Fetch this first, [unzip](https://github.com/Maparoni/Zip), fetch metadata via ```AppPixivAPI.ugoira_metadata``` and use the first given frame delay for assembling. Take a look at ```PixivDownloader.zip_to_ugoira```.

## TODO
- write more tests
- actually finally finish the fix for headless login
- introduce a proper repo structure (like a dev branch) and version management (patches are always pushed without updating the tag, meaning clients using this pkg will have the bugs that are solved in HEAD (aaa))
- swiftify method and class/struct names
- de-curse API methods (underlying request methods use dispatch semaphores in a cursed way, will fix that)

## Announcements
I'll release a repo of an iOS/macOS app using this API soon.
You can already find my script using this API [here](https://github.com/theBreadCompany/pixivloader).

## Credits
- [pixiv.net](https://pixiv.net) for their amazing platform
- [upbit](https://github.com/upbit) for providing his work as opensource 
- [Apple](https://github.com/apple) for creating a powerful language that is really nice to learn and use
