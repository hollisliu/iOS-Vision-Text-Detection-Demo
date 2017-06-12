#  Vision.framework Text Detection Demo

![intro](/demo.gif)

## Introduction
Vision is one of the many exciting new framwork introduced at WWDC 17. Enhanced Text detection is among the many new features in Vision.framwork. But since Apple hasn't provided any demo code on the Vision text detection, here is a quick sample project.

This demo app:
1. takes a live video feed, detect text regions (VNTextObservation) and draws a green box around each region
2. draws blue boxes around each character box detected (VNRectangleObservation)

## Requirements
Running this app requires at least Xcode 9 beta 1 and a physical device running iOS 11 beta 1

## Other Notes
There is no OCR framework in the iOS SDK still. As a result a OCR engine is needed to recognize detected text content.
