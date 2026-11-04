#!/usr/bin/env python3
"""On-demand Wallhaven search and bounded downloads. No background network work."""
import json
from pathlib import Path
import re
import sys
import tempfile
from urllib.parse import urlencode, urlparse
from urllib.request import Request, urlopen

MAX_DOWNLOAD = 30 * 1024 * 1024


def validate_url(url, host):
    parsed = urlparse(url)
    if parsed.scheme != "https" or parsed.hostname != host or parsed.username or parsed.password or parsed.port not in (None, 443):
        raise ValueError("Wallpaper provider returned an unexpected URL")
    return url


def request(url):
    response = urlopen(Request(url, headers={"User-Agent": "illogical-impulse-wallpapers/1.0"}), timeout=20)
    if urlparse(response.url).hostname != urlparse(url).hostname:
        response.close()
        raise ValueError("Wallpaper provider redirected to another host")
    return response


def search(query, page, sorting, resolution, category):
    if len(query) > 250 or not 1 <= page <= 1000:
        raise ValueError("Search is too long or page is invalid")
    if sorting not in ("relevance", "toplist", "date_added"):
        raise ValueError("Invalid sort order")
    if resolution not in ("", "1920x1080", "2560x1440", "3840x2160") or category not in ("111", "100", "010", "001"):
        raise ValueError("Invalid wallpaper filter")
    params = dict(q=query, page=page, sorting=sorting, purity="100", categories=category)
    if resolution:
        params["atleast"] = resolution
    with request("https://wallhaven.cc/api/v1/search?" + urlencode(params)) as response:
        data = json.loads(response.read(2 * 1024 * 1024))
    rows = []
    for item in data["data"][:24]:
        if not re.fullmatch(r"[a-z0-9]{6}", item["id"]):
            continue
        rows.append(dict(id=item["id"], thumb=validate_url(item["thumbs"]["small"], "th.wallhaven.cc"),
                         url=validate_url(item["path"], "w.wallhaven.cc"), resolution=item["resolution"]))
    return dict(results=rows, page=page, lastPage=data["meta"]["last_page"])


def download(url, destination):
    validate_url(url, "w.wallhaven.cc")
    name = Path(urlparse(url).path).name
    if not re.fullmatch(r"wallhaven-[a-z0-9]{6}\.(jpg|jpeg|png|webp)", name):
        raise ValueError("Unsupported wallpaper file")
    destination = Path(destination).expanduser()
    destination.mkdir(parents=True, exist_ok=True)
    path = destination / name
    with request(url) as response:
        if int(response.headers.get("Content-Length", 0)) > MAX_DOWNLOAD:
            raise ValueError("Wallpaper exceeds the 30 MB download limit")
        if response.headers.get_content_type() not in ("image/jpeg", "image/png", "image/webp"):
            raise ValueError("Provider did not return an image")
        temporary = None
        try:
            with tempfile.NamedTemporaryFile(dir=destination, delete=False) as stream:
                temporary = Path(stream.name)
                size = 0
                while chunk := response.read(65536):
                    size += len(chunk)
                    if size > MAX_DOWNLOAD:
                        raise ValueError("Wallpaper exceeds the 30 MB download limit")
                    stream.write(chunk)
                if size == 0:
                    raise ValueError("Downloaded image is empty")
            with temporary.open("rb") as stream:
                header = stream.read(12)
            if not (header.startswith(b"\xff\xd8\xff") or header.startswith(b"\x89PNG\r\n\x1a\n")
                    or (header.startswith(b"RIFF") and header[8:12] == b"WEBP")):
                raise ValueError("Provider did not return a supported image")
            temporary.replace(path)
        finally:
            if temporary:
                temporary.unlink(missing_ok=True)
    return str(path)


if __name__ == "__main__":
    try:
        if sys.argv[1] == "search":
            print(json.dumps(search(sys.argv[2], int(sys.argv[3]), *sys.argv[4:7])))
        elif sys.argv[1] == "download":
            print(download(sys.argv[2], sys.argv[3]))
        else:
            raise ValueError("Unknown wallpaper action")
    except (ValueError, KeyError, OSError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
