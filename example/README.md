<div align="center">
  <image alt="App icon of AubAI" height=256 src="https://github.com/BrutalCoding/aub.ai/blob/main/example/assets/appicon_rounded.png?raw=true"/>

  <h1>AubAI</h1>
  <h3>The Example App</h3>

  <sub>This is the included example app that makes use of AubAI, a Flutter/Dart package that allows you to supercharge apps with on-device AI capabilities.<br/>

  ![Pub](https://img.shields.io/pub/v/aub_ai.svg)
  ![GitHub stars](https://img.shields.io/github/stars/BrutalCoding/aub.ai.svg?style=social&label=Star)
</div>

# AubAI (Example App)

This example app is bundled with the AubAI package and demonstrates how to use it to add on-device AI capabilities to your Flutter app.

## Table of Contents

- [Getting Started](#getting-started)
- [Requirements](#requirements)
- [Installation](#installation)
- [Usage](#usage)
- [Features Demonstrated](#features-demonstrated)
- [Troubleshooting](#troubleshooting)
- [Feedback](#feedback)
- [License](#license)

## Getting Started

To get started with this example, clone the AubAI repository and navigate to the `example` directory. This example is designed to provide a hands-on experience with the key features of AubAI, demonstrating its ease of use and versatility.

## Requirements

Ensure you have the following prerequisites installed:

- Flutter SDK (latest stable version)
- Dart SDK (compatible with the Flutter SDK)
- A suitable IDE (like Visual Studio Code)
- Depending on the platform you're targeting, you may need to install additional tools. See the [Flutter documentation](https://flutter.dev/docs/get-started/install) for more information.

## Installation

1. Clone the AubAI repository.
2. Navigate to the `example` directory.
3. Run `flutter pub get` in your terminal to fetch the necessary dependencies.

## Usage

Open the project in your preferred IDE and run the app on a supported platform. The example app is designed to be very simplistic, with a minimal UI and a single screen. It allows you to send a message to the AI and receive a response.

## Features Demonstrated

- **File picker**: The example app allows you to select a model file from your device's storage. This is done using the [file_picker](https://pub.dev/packages/file_picker) package.
- **Sending messages to the AI**: The example app allows you to send a message (prompt) to the AI. This is done using the `AubAI`'s exposed `talkAsync` method.
- **Receiving responses from the AI in real-time**: After sending a message to the AI, the example app displays the response it received from the AI in real-time. This is done using the `AubAI`'s exposed `onTokenGenerated` callback which is invoked every time the AI generates a token (word).
- **Isolates out of the box**: The example app uses isolates out of the box. This is done by default, and you don't have to do anything to enable it. Without isolates, the UI would freeze while the AI is generating a response. This is because the AI is computationally expensive and would block the main thread (UI thread) while generating a response. Isolates allow the AI to run in the background, without blocking the main thread. This ensures a smooth user experience.

## Troubleshooting

If you encounter any issues while using this example, please refer to the project's main [README.md](../README.md) file and the [Troubleshooting Guide](../TROUBLESHOOTING.md) for common problems and their solutions.

## Feedback

Your feedback is invaluable in improving this example app. For suggestions, bug reports, or contributions, please open an issue or a pull request in the main AubAI repository.

## License

This example app is part of the AubAI project and is distributed under the same [AGPL-3.0 license](../LICENSE).
