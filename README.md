# pixivswift
A port of [upbit's pixivpy](https://github.com/upbit/pixivpy) library.

## Disclaimer

This whole peace is provided as is, and I am not responsible for any damage or law breakings, i. e. damage to your hardware or consumption of questionable content.

Also, please do not overuse this. Pixiv has no financial benefit from this, and they somehow have to finance their servers, too...

## Features

- Headless login
- Access to both the public API and the API used by the Pixiv app
- Directly download images (although ugoiras require further handling, more on that will follow)

## Installation

### Swift Package Manager
- simply add https://github.com/theBreadCompany/pixivswift.git to Xcode or
- add `.package(url: "https://github.com/theBreadCompany/pixivswift.git", from: "1.0.0")` to your Package.swift dependencies

## Documentation

It's basicaly the same usage like [upbit's pixivpy](https://github.com/upbit/pixivpy): This API is synchronous, meaning that we wait for every single request to be completed. 

### Examples
WIP, please have a look at pixivpy ^^'.

### Tips & Tricks
- You may use both the PublicAPI and the AppAPI class if nescessary 
- The public API grants access to searches by illustration popularity, which the AppAPI doesn't, even with the correct keyword
- ugoiras are essentially image sequences which have to be assembled manually -> the image urls contain a link to a zip file containing the images. Fetch this first, [unzip](https://github.com/marmelroy/zip), fetch metadata via ```AppPixivAPI.ugoira_metadata``` and use the first given frame delay for assembling. Code will follow.

## TODO
- Improve this documentation (provide code examples)
- Create tests
- Write a codeable class for (far) easier response handling

## Announcements
I'll release a repo of an iOS/macOS app using this API in a few weeks.

## Credits
- [pixiv.net](https://pixiv.net) for their amazing platform
- [upbit](https://github.com/upbit) for providing his work as opensource 
- [Apple](https://github.com/apple) for creating a powerful language that is really nice to learn and use
