# multica-ios-build

Unsigned iOS builds of [multica-ai/multica](https://github.com/multica-ai/multica) `apps/mobile`, for sideloading with SideStore.

- A daily workflow builds each new upstream release. No Apple Developer account is needed.
- SideStore source: `https://jackon.me/multica-ios/source.json`
  - `mirror/` pulls each release onto jackon.me every 30 min, because GitHub is unreliable from the phone.
  - Direct GitHub source, as a fallback: `https://github.com/JackonYang/multica-ios-build/releases/latest/download/source.json`
- SideStore re-signs the app on the phone with a free Apple ID and refreshes it every 7 days.
