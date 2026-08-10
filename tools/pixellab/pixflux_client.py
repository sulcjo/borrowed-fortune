"""Shared pixflux request/response handling for this project's art generators.

Bypasses client.generate_image_pixflux() entirely and posts to the endpoint
directly: the installed pixellab SDK's response model hardcodes
usage.type == "usd", but this account's real API responses come back
usage.type == "generations" (subscription/generation-allowance plan), which
crashes the SDK's Pydantic validation and discards the successfully
generated image along with it. Still uses the SDK's Client for auth/config
(client.base_url, client.headers()).
"""
from __future__ import annotations

import base64
import hashlib
from io import BytesIO
from typing import Optional

import PIL.Image

STYLE_CLAUSE = (
    "Persian miniature painting, flat gouache color fields, ochre and lapis "
    "palette, 11th-century Khorasan architecture, illuminated manuscript "
    "background"
)
NEGATIVE_DESCRIPTION = (
    "photorealistic, 3d render, modern clothing, modern buildings, gradient "
    "shading, blur, text, watermark, signature"
)


def compute_seed(key: str) -> int:
    """Deterministic seed from any string key, so re-running a generation
    for the same subject reproduces the same image rather than drawing a
    new random one."""
    digest = hashlib.sha256(key.encode("utf-8")).hexdigest()
    return int(digest[:8], 16) % 1_000_000


PORTRAIT_STYLE_CLAUSE = (
    "Persian miniature painting, flat gouache color fields, ochre and lapis "
    "palette, 11th-century Khorasan dress and bearing"
)


def build_description(subject_description: str, style_clause: str = STYLE_CLAUSE) -> str:
    """style_clause defaults to the full-scene backgrounds style. Portraits
    use PORTRAIT_STYLE_CLAUSE instead - it drops "illuminated manuscript
    background," which would otherwise fight no_background=true and leave
    scene fragments around an otherwise-transparent bust."""
    return f"{style_clause}, {subject_description}"


def _encode_image(image: Optional[PIL.Image.Image]) -> Optional[dict]:
    if image is None:
        return None
    buffered = BytesIO()
    image.save(buffered, format="PNG")
    return {
        "type": "base64",
        "base64": base64.b64encode(buffered.getvalue()).decode(),
        "format": "png",
    }


def generate_pixflux(
    client,
    description: str,
    image_size: dict,
    seed: int,
    no_background: bool = False,
    init_image: Optional[PIL.Image.Image] = None,
    color_image: Optional[PIL.Image.Image] = None,
    outline: str = "single color black outline",
    shading: str = "flat shading",
    detail: str = "low detail",
    view: str = "side",
    text_guidance_scale: int = 8,
) -> tuple[PIL.Image.Image, dict]:
    """POSTs to /generate-image-pixflux and parses the JSON ourselves.
    Returns (generated PIL.Image, raw usage dict - shape varies by account
    plan, caller decides how to report it)."""
    import requests

    request_data = {
        "description": description,
        "image_size": image_size,
        "negative_description": NEGATIVE_DESCRIPTION,
        "text_guidance_scale": text_guidance_scale,
        "outline": outline,
        "shading": shading,
        "detail": detail,
        "view": view,
        "direction": None,
        "isometric": False,
        "no_background": no_background,
        "coverage_percentage": None,
        "init_image": _encode_image(init_image),
        "init_image_strength": 300,
        "color_image": _encode_image(color_image),
        "seed": seed,
    }
    response = requests.post(
        f"{client.base_url}/generate-image-pixflux",
        headers=client.headers(),
        json=request_data,
    )
    response.raise_for_status()
    payload = response.json()

    image_bytes = base64.b64decode(payload["image"]["base64"])
    image = PIL.Image.open(BytesIO(image_bytes))
    return image, payload.get("usage", {})
