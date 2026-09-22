# Custom card back image

To use your own card-back artwork, add an image file named exactly:

```text
card_back.png
```

into this folder (`assets/`).

Requirements:
- File name must be `card_back.png`.
- Portrait orientation works best, roughly the aspect ratio of a playing card (about 0.70 width/height).
- Make sure you own the rights to the image, or it is licensed for your use. Copyrighted character art (for example, official Star Wars/Yoda artwork) cannot be redistributed here.

If no `card_back.png` is present, the app automatically falls back to its built-in card-back design, so the app keeps working either way. The app only checks for the file once per run, so a missing file will not be re-fetched repeatedly.

After adding the file, run:

```bash
flutter pub get
flutter run
```
