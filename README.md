# multica-ios-build

Unsigned iOS builds of [multica-ai/multica](https://github.com/multica-ai/multica) `apps/mobile`, for sideloading.

- A daily workflow builds each new upstream release. No Apple Developer account is needed.
- `mac/` re-signs and installs over Wi-Fi from the Mac with xtool, replacing SideStore.
  - LocalDevVPN, which SideStore needs, is not on the China App Store.
  - A launchd job runs every 2 h and re-signs once the last install is 3 days old, or when a new version appears.
  - Free-account signatures last 7 days, so the phone must share a network with the Mac at least once a week.
  - Turn off the phone's Private Wi-Fi Address for this network, or the Mac won't recognize it over Wi-Fi.
  - It downloads the latest release through the GitHub API with `gh`'s token. Run `gh auth login` once on the Mac.
  - launchd does not pass the shell's proxy variables, so the Mac must reach GitHub without them.
- SideStore source, usable only while the repo is public: `https://github.com/JackonYang/multica-ios-build/releases/latest/download/source.json`
