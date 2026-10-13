"""Upload local project documents to SharePoint using an app-only service principal."""
from __future__ import annotations

import argparse
import os
from pathlib import Path
from urllib.parse import quote, urlparse

import requests

GRAPH = "https://graph.microsoft.com/v1.0"


class Graph:
    def __init__(self, tenant_id: str, client_id: str, client_secret: str) -> None:
        token_response = requests.post(
            f"https://login.microsoftonline.com/{tenant_id}/oauth2/v2.0/token",
            data={
                "client_id": client_id,
                "client_secret": client_secret,
                "scope": "https://graph.microsoft.com/.default",
                "grant_type": "client_credentials",
            },
            timeout=60,
        )
        if not token_response.ok:
            raise RuntimeError(f"Could not obtain a Microsoft Graph service-principal token ({token_response.status_code}): {token_response.text}")
        token = token_response.json().get("access_token")
        if not token:
            raise RuntimeError("The token response did not contain an access token.")
        self.session = requests.Session()
        self.session.headers.update({"Authorization": f"Bearer {token}"})

    def request(self, method: str, path: str, *, body: object | None = None, data: object | None = None) -> requests.Response:
        response = self.session.request(method, f"{GRAPH}{path}", json=body, data=data, timeout=120)
        if not response.ok:
            raise RuntimeError(f"Microsoft Graph {method} {path} failed ({response.status_code}): {response.text}")
        return response

    def exists(self, path: str) -> bool:
        response = self.session.get(f"{GRAPH}{path}", timeout=60)
        if response.status_code == 404:
            return False
        if not response.ok:
            raise RuntimeError(f"Microsoft Graph GET {path} failed ({response.status_code}): {response.text}")
        return True


def graph_path(path: str) -> str:
    return "/".join(quote(part, safe="") for part in path.split("/") if part)


def ensure_folder(graph: Graph, drive_id: str, folder_path: str) -> None:
    current = ""
    for component in (part for part in folder_path.split("/") if part):
        current = f"{current}/{component}" if current else component
        if graph.exists(f"/drives/{drive_id}/root:/{graph_path(current)}"):
            continue
        parent = current.rsplit("/", 1)[0] if "/" in current else ""
        endpoint = f"/drives/{drive_id}/root:/{graph_path(parent)}:/children" if parent else f"/drives/{drive_id}/root/children"
        graph.request("POST", endpoint, body={"name": component, "folder": {}, "@microsoft.graph.conflictBehavior": "fail"})


def resolve_drive(graph: Graph, site_url: str, library_name: str) -> str:
    uri = urlparse(site_url)
    if uri.scheme != "https" or not uri.netloc:
        raise RuntimeError("SHAREPOINT_SITE_URL must be a full HTTPS SharePoint site URL.")
    site_path = f"/sites/{uri.netloc}:{quote(uri.path, safe='/')}" if uri.path.strip("/") else "/sites/root"
    site = graph.request("GET", site_path).json()
    drives = graph.request("GET", f"/sites/{site['id']}/drives").json().get("value", [])
    drive = next((item for item in drives if item.get("name") == library_name), None)
    if not drive:
        raise RuntimeError(f"SharePoint library {library_name!r} was not found.")
    return drive["id"]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-folder", required=True)
    parser.add_argument("--tenant-id", required=True)
    parser.add_argument("--client-id", required=True)
    parser.add_argument("--site-url", required=True)
    parser.add_argument("--library-name", required=True)
    parser.add_argument("--destination-folder", required=True)
    args = parser.parse_args()
    source = Path(args.source_folder).resolve()
    if not source.is_dir():
        raise RuntimeError(f"SharePoint source folder does not exist: {source}")
    files = [file for file in source.rglob("*") if file.is_file()]
    if not files:
        raise RuntimeError(f"SharePoint source folder contains no files: {source}")
    if args.destination_folder.startswith("/") or ".." in Path(args.destination_folder).parts:
        raise RuntimeError("SHAREPOINT_DESTINATION_FOLDER must be a relative folder path.")

    client_secret = os.environ.get("SHAREPOINT_CLIENT_SECRET")
    if not client_secret:
        raise RuntimeError("SHAREPOINT_CLIENT_SECRET is unavailable in the process environment.")
    graph = Graph(args.tenant_id, args.client_id, client_secret)
    drive_id = resolve_drive(graph, args.site_url, args.library_name)
    for local_file in files:
        relative = local_file.relative_to(source).as_posix()
        destination = "/".join(part for part in [args.destination_folder.strip("/"), relative] if part)
        parent = destination.rsplit("/", 1)[0] if "/" in destination else ""
        ensure_folder(graph, drive_id, parent)
        item_path = f"/drives/{drive_id}/root:/{graph_path(destination)}"
        if graph.exists(item_path):
            raise RuntimeError(f"Refusing to overwrite an existing SharePoint file: {destination}")
        if local_file.stat().st_size > 250 * 1024 * 1024:
            raise RuntimeError(f"{relative} exceeds the 250 MB simple-upload limit.")
        with local_file.open("rb") as content:
            result = graph.request("PUT", f"{item_path}:/content", data=content).json()
        if result.get("size") != local_file.stat().st_size:
            raise RuntimeError(f"SharePoint returned an unexpected size for {relative}.")
        print(f"Uploaded {relative}")
    print(f"Uploaded {len(files)} document(s) to SharePoint.")


if __name__ == "__main__":
    main()
