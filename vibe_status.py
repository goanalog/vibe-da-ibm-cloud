import json, os, urllib.request, urllib.error
def main(args):
    url = os.environ.get("URL")
    if not url: return {"status":"no-url"}
    try:
        with urllib.request.urlopen(url, timeout=30) as resp:
            return {"status":"success" if resp.getcode()==200 else f"http-{resp.getcode()}", "url": url}
    except urllib.error.HTTPError as e: return {"status": f"http-{e.code}", "url": url}
    except Exception as e: return {"status":"error", "error": str(e), "url": url}
