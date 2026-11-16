# Daily Bread

A one-page site for Sam Podgoreanu's MEJO 121 project on Chef Alan Wren, the chef at
UNC's Beta Upsilon Chi house. It presents the four E3 infographics in order, then
scrolls down to the interview film, which plays on the page.

## View it

Double-click `index.html`, or run the local server (needed if you want to scrub
through the film in every browser):

```bash
python3 tools/serve.py
```

Then open http://localhost:4173.

## What's here

| Path | What it is |
| --- | --- |
| `index.html`, `styles.css`, `script.js` | The site. No build step, no dependencies. |
| `assets/graphic-1…4.jpg` | The four infographics at 2560 px wide, plus 1280 px versions for small screens. |
| `assets/chef-alan-interview.mp4` | The film, re-encoded from the 4K master to 1080p H.264 at about 4.7 Mbps (80 MB). |
| `assets/poster.jpg` | The frame shown before the film plays. |
| `tools/encode.swift` | The script that made the web encode of the film. |
| `tools/serve.py` | A small local server that supports video seeking. |

The original PNGs and the 4K master stay in the parent project folder (`E3/` and
`Chef_Alan_Interview_Final.mp4`) and are not copied into this repository.

## Rebuilding the assets

```bash
swift tools/encode.swift ../Chef_Alan_Interview_Final.mp4 assets/chef-alan-interview.mp4 4.5
```

```bash
sips -s format jpeg -s formatOptions 88 -Z 2560 "../E3/1 - Chef Alan Timeline.png" --out assets/graphic-1.jpg
```

## Notes

- Fonts (Gloock and Instrument Sans) load from Google Fonts. Offline, the page falls
  back to Georgia and Helvetica.
- The film file is under GitHub's 100 MB per-file limit, so the repository can be
  pushed and served from GitHub Pages as is.
