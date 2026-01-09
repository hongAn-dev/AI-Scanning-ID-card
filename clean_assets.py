import shutil
import os

targets = [
    r"ios/Runner/Assets.xcassets/AppIcon.appiconset",
    r"ios/Runner/Assets.xcassets/LaunchImage.imageset",
    r"ios/Runner/Assets.xcassets/LaunchBackground.imageset"
]

for t in targets:
    if os.path.exists(t):
        try:
            shutil.rmtree(t)
            print(f"Deleted {t}")
        except Exception as e:
            print(f"Failed to delete {t}: {e}")
    else:
        print(f"Not found: {t}")
