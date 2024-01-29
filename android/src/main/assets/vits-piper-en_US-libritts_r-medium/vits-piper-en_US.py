#!/usr/bin/env python3

import json
import os
from typing import Any, Dict

import onnx


def add_meta_data(filename: str, meta_data: Dict[str, Any]):
    """Add meta data to an ONNX model. It is changed in-place.

    Args:
      filename:
        Filename of the ONNX model to be changed.
      meta_data:
        Key-value pairs.
    """
    model = onnx.load(filename)
    for key, value in meta_data.items():
        meta = model.metadata_props.add()
        meta.key = key
        meta.value = str(value)

    onnx.save(model, filename)


def load_config(model):
    with open(f"{model}.json", "r") as file:
        config = json.load(file)
    return config


def generate_tokens(config):
    id_map = config["phoneme_id_map"]
    with open("tokens.txt", "w", encoding="utf-8") as f:
        for s, i in id_map.items():
            f.write(f"{s} {i[0]}\n")
    print("Generated tokens.txt")


# for en_US-lessac-medium.onnx
# export TYPE=lessac
# export NAME=medium
def main():
    t = os.environ.get("TYPE", None)
    if not t:
        print("Please provide the environment variable TYPE")
        return

    # thorsten or thorsten_emotional
    name = os.environ.get("NAME", None)
    if not t:
        print("Please provide the environment variable NAME")
        return
    print("type", t)

    config = load_config(f"en_US-{name}-{t}.onnx")

    print("generate tokens")
    generate_tokens(config)

    print("add model metadata")
    meta_data = {
        "model_type": "vits",
        "comment": "piper",  # must be piper for models from piper
        "language": "English",
        "voice": config["espeak"]["voice"],  # e.g., en-us
        "has_espeak": int("espeak" in config),
        "n_speakers": config["num_speakers"],
        "sample_rate": config["audio"]["sample_rate"],
    }
    print(meta_data)
    add_meta_data(f"en_US-{name}-{t}.onnx", meta_data)


main()
