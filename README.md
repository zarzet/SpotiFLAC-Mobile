<div align="center">

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="assets/images/banner-readme-dark.png">
  <source media="(prefers-color-scheme: light)" srcset="assets/images/banner-readme-light.png">
  <img alt="SpotiFLAC Mobile" src="assets/images/banner-readme-light.png" width="650" height="auto">
</picture>

<p align="center">
  <a href="https://trendshift.io/repositories/17247">
    <img src="https://trendshift.io/api/badge/repositories/17247" alt="zarzet%2FSpotiFLAC-Mobile | Trendshift" width="250" height="55">
  </a>
</p>

</div>

<div align="center">

[![GitHub Release](https://img.shields.io/github/v/release/zarzet/SpotiFLAC-Mobile?style=for-the-badge&logo=github)](https://github.com/zarzet/SpotiFLAC-Mobile/releases)
[![VirusTotal](https://img.shields.io/badge/VirusTotal-Safe-brightgreen?style=for-the-badge&logo=virustotal)](https://www.virustotal.com/gui/file/31d1bf3c3b2015c13e83c4f909a7c6093a9423e3e702f0c582a3e0035c849424)
[![Crowdin](https://img.shields.io/badge/HELP%20TRANSLATE%20ON-CROWDIN-%2321252b?style=for-the-badge&logo=crowdin)](https://crowdin.com/project/spotiflac-mobile)

[![Telegram Channel](https://img.shields.io/badge/CHANNEL-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/spotiflac)
[![Telegram Community](https://img.shields.io/badge/COMMUNITY-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/spotiflac_chat)

</div>

## Screenshots

<p align="center">
  <img src="assets/images/1.jpg?v=2" width="200" />
  <img src="assets/images/2.jpg?v=2" width="200" />
  <img src="assets/images/3.jpg?v=2" width="200" />
  <img src="assets/images/4.jpg?v=2" width="200" />
</p>

---

## Extensions

Extensions let the community add new music sources and features without waiting for app updates. When a streaming service API changes or a new source becomes available, extensions can be updated independently.

### Installing Extensions

1. Open the **Store** tab in the app
2. On first launch, enter an **Extension Repository URL** when prompted
3. Browse and install extensions with one tap
4. Or download a `.spotiflac-ext` file and install manually via **Settings > Extensions**
5. Configure extension settings if needed
6. Set provider priority under **Settings > Extensions > Provider Priority**

### Developing Extensions

> [!NOTE]
> Want to build your own extension? The [Extension Development Guide](https://zarzet.github.io/SpotiFLAC-Mobile/docs) has everything you need.

---

## Related Projects

### [SpotiFLAC (Desktop)](https://github.com/afkarxyz/SpotiFLAC)
Download music in true lossless FLAC from Tidal, Qobuz & Amazon Music available for Windows, macOS & Linux.

### [SpotiFLAC (Python Module)](https://github.com/ShuShuzinhuu/SpotiFLAC-Module-Version)
Python library for SpotiFLAC integration, maintained by [@ShuShuzinhuu](https://github.com/ShuShuzinhuu).

---

## FAQ

<details>
<summary><b>Why does the Store tab ask me to enter a URL?</b></summary>
<br>

Starting from version 3.8.0, SpotiFLAC uses a decentralized extension repository system extensions are hosted on GitHub repositories rather than a built-in server, so anyone can create and host their own. Enter a repository URL in the Store tab to browse and install extensions.

</details>

<details>
<summary><b>Why is my download failing with "Song not found"?</b></summary>
<br>

The track may not be available on the streaming services. Try enabling more providers under **Settings > Download > Provider Priority**, or install additional extensions like Amazon Music from the Store.

</details>

<details>
<summary><b>Why are some tracks downloading in lower quality?</b></summary>
<br>

Quality depends on what's available from the streaming service and its extensions. Built-in providers:
- **Tidal** up to 24-bit/192kHz
- **Qobuz** up to 24-bit/192kHz
- **Deezer** up to 16-bit/44.1kHz

</details>

<details>
<summary><b>Can I download playlists?</b></summary>
<br>

Yes! Just paste the playlist URL in the search bar. The app will fetch all tracks and queue them for download.

</details>

<details>
<summary><b>Why do I need to grant storage permission?</b></summary>
<br>

The app needs permission to save downloaded files to your device. On Android 13+, you may need to grant **All files access** under **Settings > Apps > SpotiFLAC > Permissions**.

</details>

<details>
<summary><b>Is this app safe?</b></summary>
<br>

Yes SpotiFLAC is open source and you can verify the code yourself. Each release is also scanned with VirusTotal (see badge above).

</details>

<details>
<summary><b>Why is downloading not working in my country?</b></summary>
<br>

Some countries have restricted access to certain streaming service APIs. If downloads are failing, try using a VPN to connect through a different region.

</details>

<details>
<summary><b>Can I add SpotiFLAC to AltStore or SideStore?</b></summary>
<br>

Yes! Add the official source to receive updates directly within the app. Copy this link:

```
https://raw.githubusercontent.com/zarzet/SpotiFLAC-Mobile/refs/heads/main/apps.json
```

In AltStore/SideStore, go to **Browse > Sources**, tap **+**, and paste the link.

</details>

> [!NOTE]
> If SpotiFLAC is useful to you, consider supporting development:
>
> [![Ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/zarzet)

---

## Contributors

Thanks to everyone who has contributed to SpotiFLAC Mobile!

<a href="https://github.com/zarzet/SpotiFLAC-Mobile/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=zarzet/SpotiFLAC-Mobile" />
</a>

We also appreciate everyone who helped with [translations on Crowdin](https://crowdin.com/project/spotiflac-mobile), reported bugs, suggested features, and spread the word.

Interested in contributing? Check out the [Contributing Guide](CONTRIBUTING.md) to get started!

---

## API Credits

| | | | | |
|---|---|---|---|---|
| [hifi-api](https://github.com/binimum/hifi-api) | [music.binimum.org](https://music.binimum.org) | [qqdl.site](https://qqdl.site) | [squid.wtf](https://squid.wtf) | [spotisaver.net](https://spotisaver.net) |
| [dabmusic.xyz](https://dabmusic.xyz) | [AfkarXYZ](https://github.com/afkarxyz) | [LRCLib](https://lrclib.net) | [Paxsenix](https://lyrics.paxsenix.org) | [Cobalt](https://cobalt.tools) |
| [qwkuns.me](https://qwkuns.me) | [SpotubeDL](https://spotubedl.com) | [Song.link](https://song.link) | [IDHS](https://github.com/sjdonado/idonthavespotify) | [Monochrome](https://monochrome.tf) |

---

## Disclaimer

This repository and its contents are provided strictly for educational and research purposes. The software is provided "as-is" without warranty of any kind, express or implied, as stated in the [MIT License](LICENSE).

- No copyrighted content is hosted, stored, mirrored, or distributed by this repository.
- Users must ensure that their use of this software is properly authorized and complies with all applicable laws, regulations, and third-party terms of service.
- This software is provided free of charge by the maintainer. If you paid a third party for access to this software in its original form from this repository, you may have been misled or scammed. Any redistribution or commercial use by third parties must comply with the terms of the repository license. No affiliation, endorsement, or support by the maintainer is implied unless explicitly stated in writing.
- SpotiFLAC Mobile is an independent project. It is not affiliated with, endorsed by, or connected to any other project or version on other platforms that may share a similar name. The maintainer of this repository has no control over or responsibility for third-party projects.
- The author(s) disclaim all liability for any direct, indirect, incidental, or consequential damages arising from the use or misuse of this software. Users assume all risk associated with its use.
- If you are a copyright holder or authorized representative and believe this repository infringes upon your rights, please contact the maintainer with sufficient detail (including relevant URLs and proof of ownership). The matter will be promptly investigated and appropriate action will be taken, which may include removal of the referenced material.

> [!TIP]
> **Star the repo** to get notified about all new releases directly from GitHub.
