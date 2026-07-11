#!/usr/bin/env python3
"""OCR image files with macOS Vision (on-device, high quality for UI text).

Usage: python3 ocr_vision.py <image1> [image2 ...]
Prints "<path>\t<text-with-newlines-escaped>" per image, or use as a module:
    from ocr_vision import ocr_image
"""
import sys
import Vision
import Quartz
from Foundation import NSURL


def ocr_image(path):
    url = NSURL.fileURLWithPath_(path)
    src = Quartz.CGImageSourceCreateWithURL(url, None)
    if not src:
        return ""
    img = Quartz.CGImageSourceCreateImageAtIndex(src, 0, None)
    if not img:
        return ""
    req = Vision.VNRecognizeTextRequest.alloc().init()
    req.setRecognitionLevel_(Vision.VNRequestTextRecognitionLevelAccurate)
    req.setUsesLanguageCorrection_(True)
    handler = Vision.VNImageRequestHandler.alloc().initWithCGImage_options_(img, None)
    ok = handler.performRequests_error_([req], None)
    if not ok:
        return ""
    lines = []
    for obs in (req.results() or []):
        cand = obs.topCandidates_(1)
        if cand and len(cand):
            lines.append(cand[0].string())
    return "\n".join(lines)


if __name__ == "__main__":
    for p in sys.argv[1:]:
        txt = ocr_image(p)
        print(f"### {p}")
        print(txt)
        print()
