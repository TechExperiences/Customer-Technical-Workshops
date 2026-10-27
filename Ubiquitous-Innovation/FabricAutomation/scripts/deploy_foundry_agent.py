"""Create the required prompt agent through the current Foundry Projects SDK."""
from __future__ import annotations

import argparse
import os
import time

from azure.ai.projects import AIProjectClient
from azure.ai.projects.models import (
    ActivityProtocolConfiguration,
    AgentEndpointConfig,
    BotServiceRbacAuthorizationScheme,
    EntraAuthorizationScheme,
    PromptAgentDefinition,
    ProtocolConfiguration,
    ResponsesProtocolConfiguration,
)
from azure.core.exceptions import HttpResponseError
from azure.identity import ClientSecretCredential


INSTRUCTIONS = "You are my Supply chain agent."
AGENT_NAME = "supply-chain-bi-agent"


def credential_from_environment() -> ClientSecretCredential:
    required = ("AZURE_TENANT_ID", "AZURE_CLIENT_ID", "AZURE_CLIENT_SECRET")
    missing = [name for name in required if not os.environ.get(name)]
    if missing:
        raise RuntimeError(f"Missing Foundry credential settings: {', '.join(missing)}")
    return ClientSecretCredential(
        tenant_id=os.environ["AZURE_TENANT_ID"],
        client_id=os.environ["AZURE_CLIENT_ID"],
        client_secret=os.environ["AZURE_CLIENT_SECRET"],
    )


def create_project_client(project_endpoint: str) -> AIProjectClient:
    return AIProjectClient(
        endpoint=project_endpoint,
        credential=credential_from_environment(),
        allow_preview=True,
    )


def create_agent_when_ready(project: AIProjectClient, model_deployment_name: str) -> object:
    for attempt in range(1, 61):
        try:
            return project.agents.create_version(
                agent_name=AGENT_NAME,
                definition=PromptAgentDefinition(
                    model=model_deployment_name,
                    instructions=INSTRUCTIONS,
                ),
            )
        except HttpResponseError as error:
            if error.status_code not in {403, 404, 409} or attempt == 60:
                raise RuntimeError(f"Foundry agent creation failed: {error}") from error
            print(f"Foundry project access is not ready; waiting 5 seconds (attempt {attempt}/60)...")
            time.sleep(5)

    raise RuntimeError("Foundry agent creation did not complete.")


def configure_agent_endpoint_when_ready(project: AIProjectClient) -> object:
    endpoint = AgentEndpointConfig(
        protocol_configuration=ProtocolConfiguration(
            responses=ResponsesProtocolConfiguration(),
            activity=ActivityProtocolConfiguration(),
        ),
        authorization_schemes=[
            EntraAuthorizationScheme(),
            BotServiceRbacAuthorizationScheme(),
        ],
    )
    for attempt in range(1, 61):
        try:
            return project.agents.update_details(
                agent_name=AGENT_NAME,
                agent_endpoint=endpoint,
            )
        except HttpResponseError as error:
            if error.status_code not in {403, 404, 409} or attempt == 60:
                raise RuntimeError(f"Foundry agent endpoint configuration failed: {error}") from error
            print(f"Foundry agent endpoint is not ready; waiting 5 seconds (attempt {attempt}/60)...")
            time.sleep(5)

    raise RuntimeError("Foundry agent endpoint configuration did not complete.")


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
    project = create_project_client(project_endpoint)
    try:
        agent = create_agent_when_ready(project, args.model_deployment_name)
        agent_id = getattr(agent, "id", None)
        agent_version = getattr(agent, "version", None)
        if not agent_id:
            raise RuntimeError("Foundry agent creation did not return an agent ID.")
        configure_agent_endpoint_when_ready(project)
    finally:
        project.close()
    print(f"Created and configured Foundry agent {AGENT_NAME} ({agent_id}), version {agent_version}.")


if __name__ == "__main__":
    main()
