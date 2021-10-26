# pixivswift
A port of [upbit's pixivpy](https://github.com/upbit/pixivpy) library.

## Disclaimer

This whole peace is provided as is, and I am not responsible for any damage or law breakings, i. e. damage to your hardware or consumption of questionable content.

Also, please do not overuse this. Pixiv has no financial benefit from this, and they somehow have to finance their servers, too...

## Features

- Headless login
- Access to both the public API and the API used by the Pixiv app (NOTE: the public API seems dead so I will drop it soon)
- Directly download images (although ugoiras require further handling, more on that will follow)

## Installation

### Swift Package Manager
- simply add https://github.com/theBreadCompany/pixivswift.git to Xcode or
- add `.package(url: "https://github.com/theBreadCompany/pixivswift.git", from: "1.1.0")` to your Package.swift dependencies

## Documentation

It's basicaly the same usage like [upbit's pixivpy](https://github.com/upbit/pixivpy): This API is synchronous, meaning that we wait for every single request to be completed. 

### Examples
WIP, please have a look at pixivpy ^^'.

### Tips & Tricks
- ~~You may use both the PublicAPI and the AppAPI class if nescessary~~ The PublicAPI will be deprecated soon.
- ~~The public API grants access to searches by illustration popularity, which the AppAPI doesn't, even with the correct keyword~~ The PublicAPI seems to have been shutdown even further, now including the search function. You now have to use the AppAPI and look at a bigger collection of illustrations and i. e. filter out by a minimum number of bookmarks or views. You may use the popular search if you have a premium account. The API will automatically switch from using the most popular to the newest populations if you dont have premium, even if using ```SearchMode.popular_desc```.
- ugoiras are essentially image sequences which have to be assembled manually -> the image urls contain a link to a zip file containing the images. Fetch this first, [unzip](https://github.com/marmelroy/zip), fetch metadata via ```AppPixivAPI.ugoira_metadata``` and use the first given frame delay for assembling. Code will follow.

## TODO
- Improve this documentation (provide code examples)
- Create tests

## Announcements
I'll release a repo of an iOS/macOS app using this API in a few weeks.
You can already find my script using this API with an intermediate wrapper [here](https://github.com/theBreadCompany/pixivloader).

## Credits
- [pixiv.net](https://pixiv.net) for their amazing platform
- [upbit](https://github.com/upbit) for providing his work as opensource 
- [Apple](https://github.com/apple) for creating a powerful language that is really nice to learn and use
