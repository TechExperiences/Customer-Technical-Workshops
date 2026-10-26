"""Create the one prompt agent required in the newly provisioned Foundry project."""
from __future__ import annotations

import argparse
import os
import time

import requests


INSTRUCTIONS = "You are my Supply chain agent."
API_VERSION = "2025-05-01"


def create_agent_when_ready(project_endpoint: str, model_deployment_name: str) -> dict:
    token = os.environ.get("AZURE_FOUNDRY_ACCESS_TOKEN")
    if not token:
        raise RuntimeError("AZURE_FOUNDRY_ACCESS_TOKEN is not available. Run through up.ps1.")

    url = f"{project_endpoint}/agents?api-version={API_VERSION}"
    payload = {
        "name": "SupplyChainAgent",
        "model": model_deployment_name,
        "instructions": INSTRUCTIONS,
    }
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

    for attempt in range(1, 61):
        response = requests.post(url, headers=headers, json=payload, timeout=60)
        if response.status_code in {200, 201}:
            return response.json()
        if response.status_code not in {403, 404, 409} or attempt == 60:
            raise RuntimeError(
                f"Foundry agent creation failed with HTTP {response.status_code}: {response.text}"
            )
        print(f"Foundry project access is not ready; waiting 5 seconds (attempt {attempt}/60)...")
        time.sleep(5)

    raise RuntimeError("Foundry agent creation did not complete.")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--foundry-account-name", required=True)
    parser.add_argument("--project-name", required=True)
    parser.add_argument("--model-deployment-name", required=True)
    args = parser.parse_args()

    project_endpoint = (
        f"https://{args.foundry_account_name}.services.ai.azure.com/"
        f"api/projects/{args.project_name}"
    )
    agent = create_agent_when_ready(project_endpoint, args.model_deployment_name)
    agent_id = agent.get("id")
    if not agent_id:
        raise RuntimeError("Foundry agent creation did not return an agent ID.")
    print(f"Created Foundry agent SupplyChainAgent ({agent_id}).")


if __name__ == "__main__":
    main()
