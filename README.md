<div align="center">
  <image alt="App icon of AubAI" height=256 src="https://github.com/BrutalCoding/aub.ai/blob/main/example/assets/appicon_avatar.png?raw=true"/>

  <h1>AubAI</h1>

  <sub>AubAI brings you on-device gen-AI capabilities, including offline text generation and more, directly within your app.</sub>

  ![Pub](https://img.shields.io/pub/v/aub_ai.svg)
  ![GitHub stars](https://img.shields.io/github/stars/BrutalCoding/aub.ai.svg?style=social&label=Star)
</div>

## Intro

Greetings Flutteristas, AI enthusiasts, and forward-thinking developers! Ready to revolutionize your apps with on-device gen-AI, including advanced text generation capabilities? You've landed in the right place.

Meet AubAI: a Flutter/Dart package designed specifically for empowering your apps with on-device gen-AI models. Whether it's generating text, enhancing user interaction, or other AI-driven tasks, AubAI has got you covered.

This package is a game-changer for all major platforms. But don't just take my word for it; see AubAI in action in my YouTube tutorials at [YouTube.com/@BrutalCoding](https://www.youtube.com/@BrutalCoding).

AubAI is not only powerful and versatile but also user-friendly and open-source. It's time to unlock the full potential of your apps with the latest in gen-AI technology.

## Features and Capabilities

### Advanced Gen-AI Integration

- **Text Generation**: Harness the power of cutting-edge language models with AubAI for smooth text generation, elevating the user experience through advanced natural language processing. Effortlessly download and try out any GGUF model from sources such as [HuggingFace](https://huggingface.co/models?library=gguf), bringing top-tier AI functionality into your app with ease.

### Cross-Platform Compatibility

- **Universal Platform Support**: AubAI is meticulously designed for Flutter, ensuring seamless operation across a multitude of platforms. This broad compatibility extends to various operating systems, catering to a diverse range of development needs:

  - macOS (ARM64, x86_64)
  - Windows (x86_64)
  - Linux (x86_64)
  - Android (ARM64, x86_64)
  - iOS (ARM64)
  - iPadOS (ARM64)

### User-Friendly Design

- **Simplified Integration**: At the heart of AubAI is a commitment to simplicity, making sophisticated AI features accessible to developers across all expertise levels.
- **Open Source Community**: Embracing the spirit of collaborative development, AubAI is an open-source package. We encourage and welcome community contributions, driving innovation and fostering an environment of continuous advancement.

### Demonstrations and Tutorials

- **Engaging Live Examples**: Discover AubAI's practical applications and watch it in action on my YouTube channel at [YouTube.com/@BrutalCoding](https://www.youtube.com/@BrutalCoding). Providing clear, real-world examples of how AubAI can transform your apps with on-device gen-AI, learn how to integrate AubAI into your projects with ease.

## Do You Like This Project?

Assuming you have checked out AubAI, and you like it, there are several ways to show your appreciation:

- **Star this project**.
  - It's a great way to show your appreciation, and it helps this project get more exposure.
- **Become a sponsor**.
  - To become a sponsor, visit my [GitHub Sponsor page](https://github.com/sponsors/BrutalCoding).
- **Contribute**.
  - If you're a developer, you can contribute to this project by fixing bugs, adding features, or improving the documentation. See the [CONTRIBUTING.md](CONTRIBUTING.md) file for more information.
- **Spread the word**.
  - Tell your friends, family, and colleagues about this project. The more people know about this project, the closer we get to the goal of making AI accessible to everyone without having to rely on any third-party services.

Consider becoming a sponsor. While the idea of this project is to make AI accessible to everyone, it comes at a cost, in terms of spending a lot of time on this project. My landlord doesn't accept GitHub stars as a form of payment, not yet at least. If you can afford it, please consider becoming a sponsor. It could be as little as $1 one time, $1 per month, or any other amount. Every little bit helps, both mentally and financially.

If you're a wealthy individual that was about to purchase a big luxury yacht, consider one less gold-plated knob on the steering wheel and use that money to add your name to the list of sponsors.

## Download the Example App

### AI for Everyone

The goal is to make AI accessible to everyone, right? That's why I've spent quite some time on making sure that the
example app is available to download on all major platforms. I want to make it as easy as possible for everyone to try out. Nothing better than a real-world example to see what AubAI is capable of.

No technical knowledge required. Just download the app, and you're good to go.

### Download the Example App from the stores

- iOS, iPadOS, macOS
  - [Invite link to TestFlight](https://testflight.apple.com/join/XuTpIgyY)
- Android: (Coming soon)
- Windows: (Coming soon)
- Linux: (Coming soon)

Make sure to to hit the "Star" button on this project if you like it. Perhaps one day my landlord will accept GitHub stars as a form of payment!

## Setup

1. Add the following to your `pubspec.yaml` file:

```yaml
dependencies:
  aub_ai: ^1.0.0
```

2. Run `flutter pub get` to install the package.

3. Import the package in your Dart code:

```dart
import 'package:aub_ai/aub_ai.dart';
```

4. Talk to the AI:

```dart
/// The output of the AI will be stored in this variable.
/// Can be used in a Text() widget, for example.
String outputByAI = '';

/// Example of how to use AubAI to talk to the AI.
Future<void> example() async {
  // Make sure that the model file is in the GGUF format.
  const String filePath = 'path/to/model.gguf';

  // The prompt to start the conversation with.
  const String promptByUser = 'Why is the sky blue?';

  // Pre-defined prompt templates are available.
  final promptTemplate = PromptTemplate.chatML().copyWith(
    prompt: promptByUser,
  );

  // THe main function that does all the magic.
  await talkAsync(
      filePathToModel: filePath,
      promptTemplate: promptTemplate,
      onTokenGenerated: (String token) {
        // This callback is called for every token generated by the AI.
        // A token can be seen as a partial word such as "hel" and "lo!".
        setState(() {
          outputByAI += token;
        });
      },
    );
}
```

## Technical Details

AubAI is leveraging the power of [llama.cpp](https://github.com/ggerganov/llama.cpp). It's a C++ library that allows you to run AI models on your device. It's fast, it's lightweight, and it's open source. It's the perfect fit for AubAI.

While llama.cpp is a great library, it's not trivial to integrate it into a Flutter project. That's where AubAI comes in. It's a Flutter/Dart package that makes it easy to use llama.cpp in your Flutter project.

The vision of AubAI is to make AI accessible to everyone, and AI is more than just generating text. That's why AubAI is designed to be modular. Over time, more AI capabilities will be added to AubAI such as image generation, voice generation, and more.

## Supported Model File Formats

- [x] GGUF

### Resources

If you're looking for a model file, you can find a couple here:
[HuggingFace.co](https://huggingface.co/models?library=gguf).

At the time of writing, there are over 2300 models available. Some of them might be very good with math, others with coding, and others with poetry and some are good at everything. It's up to you to find the model that suits your use case for your app, or let your users choose a model like I did in the [example app](./example/README.md).

## Disclaimer

AubAI, myself, and anyone else involved in this project are not responsible for any damages caused by the use of this project. Use at your own risk.

## Licensing

### Open Source Licensing

See the [LICENSE](LICENSE) file. All files are licensed under the AGPL-3.0 license, unless explicitly stated otherwise.

### Commercial Licensing

AubAI is licensed under the [AGPL-3.0](./LICENSE) license. However, we understand that the AGPL-3.0 license is not always suitable for commercial use. Therefore, we offer a commercial license for those who wish to use AubAI in a commercial setting, but do not want to comply with the AGPL-3.0 license.

Please contact [daniel@brutalcoding.com](mailto:daniel@brutalcoding.com) to enquire about a commercial license.

## Contributing

Please read the [CONTRIBUTING.md](CONTRIBUTING.md) file.

## YouTube

Curious about AubAI? Have a look at my channel where I make videos about AubAI: [YouTube.com/@BrutalCoding](https://www.youtube.com/@BrutalCoding).

Demo's, tutorials, and more.

For your convenience, I have listed some of the videos below:

- [Run Local AI On Any Device. Check Out This Flutter Plugin.](https://www.youtube.com/watch?v=kJ_36Z14Mwg)
- [Running local AI on my iPad Mini. Free & Open Source.](https://www.youtube.com/watch?v=-bRoXvFZVv0)
- [Using My Offline AI App on a Pixel 7 (Android 13), Powered By My Upcoming Flutter Plugin](https://www.youtube.com/watch?v=SBaSpwXRz94)
- [Running Offline LLMs such as Mistral 7B on Linux. Open-Source llama.cpp Wrapper for Flutter.](https://www.youtube.com/watch?v=LOTCvGnO7lg)

## Werkloos

A Dutch word that perfectly describes my current situation: unemployed. But using that word in English might've made you skip this section, yet here you are. I'm glad you're still reading.

Recently, last September, the fintech startup I was working for had to shut down due to the challenging market conditions. While I'm currently looking for a new job, It's not easy to find a company that combines my passion for AI and Flutter.

I've decided to take a leap of faith and work on this project untill I find a new job, or until I run out of money (Jan-Feb 2024). Whichever comes first. Perhaps I'll find a way to make this project sustainable, while keeping it open source. I'm just going with the flow.

## Friends of AubAI

- [shady.ai](https://github.com/BrutalCoding/shady.ai) - The consumer-facing app that uses AubAI to run AI models locally. This is the app that I'm building to showcase AubAI's capabilities, and to make AI accessible to the masses.
- [llama.cpp](https://github.com/ggerganov/llama.cpp) - C++ library for building and running AI models locally.
- [Flutter Perth](https://www.meetup.com/Flutter-Perth/) - Perth's Flutter meetup group. I'm the organizer. Join my regular online meetups to learn more about Flutter and AI.
