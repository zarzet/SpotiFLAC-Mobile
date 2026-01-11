[![GitHub All Releases](https://img.shields.io/github/downloads/zarzet/SpotiFLAC-Mobile/total?style=for-the-badge)](https://github.com/zarzet/SpotiFLAC-Mobile/releases)
[![VirusTotal](https://img.shields.io/badge/VirusTotal-Safe-brightgreen?style=for-the-badge&logo=virustotal)](https://www.virustotal.com/gui/file/09c6260e9ebaf2ff0d15f30deda939642f41887f11aad602ac697cb37fa0308c/)

<div align="center">

<img src="icon.png" width="128" />

Get Spotify tracks in true FLAC from Tidal, Qobuz & Amazon Music — no account required.

![Android](https://img.shields.io/badge/Android-7.0%2B-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![iOS](https://img.shields.io/badge/iOS-14.0%2B-000000?style=for-the-badge&logo=apple&logoColor=white)

</div>

### [Download](https://github.com/zarzet/SpotiFLAC-Mobile/releases)

## Screenshots

<p align="center">
  <img src="assets/images/1.jpg?v=2" width="200" />
  <img src="assets/images/2.jpg?v=2" width="200" />
  <img src="assets/images/3.jpg?v=2" width="200" />
  <img src="assets/images/4.jpg?v=2" width="200" />
</p>

## Metadata Source

SpotiFLAC supports two metadata sources for searching tracks:

| Source | Pros | Cons |
|--------|------|------|
| **Deezer** (Default) | No developer account needed, rate limit per user IP | Slightly less comprehensive catalog |
| **Spotify** | More comprehensive catalog, better search results | Requires developer API credentials to avoid rate limiting |

### Using Spotify
To use Spotify as your search source without hitting rate limits:
1. Create a Spotify Developer account at [developer.spotify.com](https://developer.spotify.com)
2. Create an app to get your Client ID and Client Secret
3. Go to **Settings > Options > Spotify API > Change from Deezer to Spotify > Input Custom Credentials**
4. Enter your Client ID and Secret
5. Change **Search Source** to Spotify

## Extensions (Alpha)

> **Alpha Feature**: Extensions are now available in alpha. Some features may be unstable or change in future releases.

SpotiFLAC supports extensions to add custom metadata and download providers. Extensions are written in JavaScript and run in a secure sandbox.

### Features
- **Metadata Providers**: Add new sources for track/album/artist search
- **Download Providers**: Add new sources for audio downloads
- **Custom Settings**: Extensions can have user-configurable settings
- **Provider Priority**: Set the order in which providers are tried

### Installing Extensions
1. Download a `.spotiflac-ext` file
2. Go to **Settings > Extensions**
3. Tap **Install Extension** and select the file
4. Configure extension settings if needed
5. Set provider priority in **Settings > Extensions > Provider Priority**

### Developing Extensions
Want to create your own extension? Check out the [Extension Development Guide](docs/EXTENSION_DEVELOPMENT.md) for complete documentation.

### Example Extensions
Sample extensions are available in the [docs/extensions_example](docs/extensions_example) folder:

## Other project

### [SpotiFLAC (Desktop)](https://github.com/afkarxyz/SpotiFLAC)
Get Spotify tracks in true FLAC from Tidal, Qobuz & Amazon Music for Windows, macOS & Linux

[![Ko-fi](https://img.shields.io/badge/Ko--fi-Support%20Me-FF5E5B?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/zarzet)

## Disclaimer

> **iOS Support**: This app is primarily tested on Android. iOS support is experimental and may have bugs — the developer is too poor to afford an iPhone for proper testing. If you encounter issues on iOS, please report them!

This project is for **educational and private use only**. The developer does not condone or encourage copyright infringement.

**SpotiFLAC** is a third-party tool and is not affiliated with, endorsed by, or connected to Spotify, Tidal, Qobuz, Amazon Music, or any other streaming service.

You are solely responsible for:
1. Ensuring your use of this software complies with your local laws.
2. Reading and adhering to the Terms of Service of the respective platforms.
3. Any legal consequences resulting from the misuse of this tool.

The software is provided "as is", without warranty of any kind. The author assumes no liability for any bans, damages, or legal issues arising from its use.
