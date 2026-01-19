[![GitHub All Releases](https://img.shields.io/github/downloads/zarzet/SpotiFLAC-Mobile/total?style=for-the-badge)](https://github.com/zarzet/SpotiFLAC-Mobile/releases)
[![VirusTotal](https://img.shields.io/badge/VirusTotal-Safe-brightgreen?style=for-the-badge&logo=virustotal)](https://www.virustotal.com/gui/file/3257155286587a3596ad5d4380d4576a684aa3d37a5b19a615914a845fbe57f3)
[![Crowdin](https://img.shields.io/badge/HELP%20TRANSLATE%20ON-CROWDIN-%2321252b?style=for-the-badge&logo=crowdin)](https://crowdin.com/project/spotiflac-mobile)

<div align="center">

<img src="icon.png" width="128" />

Download music in true lossless FLAC from Tidal, Qobuz & Amazon Music — no account required.

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

## Search Source

SpotiFLAC supports multiple search sources for finding music metadata:

| Source | Setup |
|--------|-------|
| **Deezer** (Default) | No setup required |
| **Extensions** | Install additional search providers from the Store |

## Extensions

Extensions allow the community to add new music sources and features without waiting for app updates. When a streaming service API changes or a new source becomes available, extensions can be updated independently.

### Installing Extensions
1. Go to **Store** tab in the app
2. Browse and install extensions with one tap
3. Or download a `.spotiflac-ext` file and install manually via **Settings > Extensions**
4. Configure extension settings if needed
5. Set provider priority in **Settings > Extensions > Provider Priority**

### Developing Extensions
Want to create your own extension? Check out the [Extension Development Guide](https://zarz.moe/docs) for complete documentation.

## Other project

### [SpotiFLAC (Desktop)](https://github.com/afkarxyz/SpotiFLAC)
Download music in true lossless FLAC from Tidal, Qobuz & Amazon Music for Windows, macOS & Linux

## FAQ

**Q: Why is my download failing with "Song not found"?**  
A: The track may not be available on Tidal, Qobuz, or Amazon Music. Try enabling more download services in Settings > Download > Provider Priority, or install additional extensions from the Store.

**Q: Why are some tracks downloading in lower quality?**  
A: Quality depends on what's available from the streaming service. Tidal offers up to 24-bit/192kHz, Qobuz up to 24-bit/192kHz, and Amazon up to 24-bit/48kHz. The app automatically selects the best available quality.

**Q: Can I download playlists?**  
A: Yes! Just paste the playlist URL in the search bar. The app will fetch all tracks and queue them for download.

**Q: Why do I need to grant storage permission?**  
A: The app needs permission to save downloaded files to your device. On Android 13+, you may need to grant "All files access" in Settings > Apps > SpotiFLAC > Permissions.

**Q: Is this app safe?**  
A: Yes, the app is open source and you can verify the code yourself. Each release is scanned with VirusTotal (see badge at top of README).

[![Ko-fi](https://img.shields.io/badge/Ko--fi-Support%20Me-FF5E5B?style=for-the-badge&logo=ko-fi&logoColor=white)](https://ko-fi.com/zarzet)

## Disclaimer

This project is for **educational and private use only**. The developer does not condone or encourage copyright infringement.

**SpotiFLAC** is a third-party tool and is not affiliated with, endorsed by, or connected to Tidal, Qobuz, Amazon Music, Deezer, or any other streaming service.

The application is purely a user interface that facilitates communication between your device and existing third-party services.

You are solely responsible for:
1. Ensuring your use of this software complies with your local laws.
2. Reading and adhering to the Terms of Service of the respective platforms.
3. Any legal consequences resulting from the misuse of this tool.

The software is provided "as is", without warranty of any kind. The author assumes no liability for any bans, damages, or legal issues arising from its use.
