# Troubleshooting

This troubleshooting guide is designed to help you diagnose and solve common problems. If you encounter any issues while using AubAI, please refer to this guide for common problems and their solutions.

## Checklist

Please make sure that you've checked the following requirements before proceeding:

- Ensure you have the latest version of AubAI installed.
- Ensure you have the latest version of Flutter installed.
- Ensure you're using one of the supported platforms.
- Ensure you're using a supported model file format, which is '.gguf' at the moment.
- Ensure that the model file is not corrupted. Usually, you can use the
sha256 checksum to verify the integrity of the model file. The sha256 checksum should be provided by the model file provider.
- Ensure that the model file is not too large for your device. For example, if you're using a mobile device, a model file which a 7B parameter model might be too large for your device's memory. In this case, you can try using a smaller model file such as a 3B parameter model, or a 1.5B parameter model.

## Common Problems

### File picker allows any file to be selected

This is not a bug. The file picker is designed to allow any file to be selected. However, the AI will only work with model files that are in the GGUF format.
It's common for model files to have the '.gguf' extension, but it's not a requirement. Thus, you can select any file, but the AI will only work with model files that are in the GGUF format. If you've got a valid GGUF file, such as "model.gguf", you can rename it to "model.kangaroo" for example and see that the AI will still work with it.

### The AI is generating a response, but it doesn't make sense

This is usually caused by one of the following:

- The model is horrible. Some models are just bad. It's not your fault. Try using a different model file.

- The model is not compatible with the prompt template. Make sure that the prompt template you're using is compatible with the model file you're using. For example, if you're using a model file that was trained on the chatML prompt template, you should use the chatML prompt template when talking to the AI. Otherwise, the AI might not generate a response or might generate a response that doesn't make sense.

### The AI did not complete the response / sentence

That's a bummer.

Try changing the context length. A context length is basically the number of tokens (words) that the AI uses to generate a response. However, the prompt template that you've given to the AI is also taken into account. Don't forget, the prompt of the user is included in this prompt template.

Thus, for example, if you've given the AI a context length of 2048 tokens, and your prompt template is 1024 tokens long, the AI will use the 1024 tokens from the prompt template and the other remaining 1024 tokens to generate a response.

Keep in mind that increasing the context length will increase the amount of memory used by the AI, which might cause the app to crash on if the AI context length is too large for your device's memory. The solution is to use a smaller model file, or to use a smaller context length, or increase the amount of memory of your device.
