# pixivswift
A port of (https://github.com/upbit/pixivpy)[upbit's pixivpy] library.

## Disclaimer

This whole peace is provided as is, and I am not responsible for any damage or law breakings, i. e. damage to your hardware or consumption of questionable content.

Also, please do not overuse this. Pixiv has no financial benefit from this, and they somehow have to finance their servers, too...

## Features

- Headless login
- Access to both the public API and the API used by the Pixiv app
- Directly download images (although ugoiras require further handling, more on that will follow)

## Documentation

It's basicaly the same usage like (https://github.com/upbit/pixivpy)[upbit's pixivpy]: This API is synchronous, meaning that we wait for every single request to be completed. 

### Examples
WIP, please have a look at pixivpy ^^'.

### Tips & Tricks
- You may use both the PublicAPI and the AppAPI class if nescessary 
- The public API grants access to searches by illustration popularity, which the AppAPI doesn't, even with the correct keyword
- ugoiras are essentially image sequences which have to be assembled manually -> the image urls contain a link to a zip file containing the images. Fetch this first, (https://github.com/marmelroy/zip)[unzip], fetch metadata via ```AppPixivAPI.ugoira_metadata``` and use the first given frame delay for assembling. Code will follow.

## TODO
- Improve this documentation (provide code examples)
- Create tests
- Write a codeable class for (far) easier response handling

## Announcements
I'll release a repo of an iOS/macOS app using this API in a few weeks.

