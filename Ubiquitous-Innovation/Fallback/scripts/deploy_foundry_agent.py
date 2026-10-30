"""Create a Foundry agent with ADLS knowledge and the source Fabric Data Agent tool."""
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
    FileSearchTool,
    MCPTool,
    PromptAgentDefinition,
    ProtocolConfiguration,
    ResponsesProtocolConfiguration,
)
from azure.core.exceptions import HttpResponseError
from azure.identity import ClientSecretCredential


INSTRUCTIONS = "You are my Supply chain agent."
AGENT_NAME = "Ubiquitous-Supply-Chain-BI-Agent"
FABRIC_CONNECTION_NAME = "fabric-data-agent"


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


def project_endpoint(account_name: str, project_name: str) -> str:
    return f"https://{account_name}.services.ai.azure.com/api/projects/{project_name}"


def create_project_client(endpoint: str, credential: ClientSecretCredential) -> AIProjectClient:
    return AIProjectClient(endpoint=endpoint, credential=credential, allow_preview=True)


def create_agent_when_ready(
    project: AIProjectClient, model_deployment_name: str, vector_store_id: str, fabric_mcp_url: str
) -> object:
    definition = PromptAgentDefinition(
        model=model_deployment_name,
        instructions=INSTRUCTIONS,
        tools=[
            FileSearchTool(vector_store_ids=[vector_store_id]),
            MCPTool(
                server_label="fabric_data_agent",
                server_url=fabric_mcp_url,
                server_description=(
                    "Governed, read-only Ubiquitous Innovation manufacturing analytics from Microsoft Fabric."
                ),
                project_connection_id=FABRIC_CONNECTION_NAME,
                require_approval="never",
            ),
        ],
    )
    for attempt in range(1, 61):
        try:
            return project.agents.create_version(agent_name=AGENT_NAME, definition=definition)
        except HttpResponseError as error:
            if error.status_code not in {403, 404, 409} or attempt == 60:
                raise RuntimeError(f"Foundry agent creation failed: {error}") from error
            print(f"Foundry agent resources are not ready; waiting 10 seconds (attempt {attempt}/60)...")
            time.sleep(10)
    raise RuntimeError("Foundry agent creation did not complete.")


def configure_agent_endpoint_when_ready(project: AIProjectClient) -> None:
    endpoint = AgentEndpointConfig(
        protocol_configuration=ProtocolConfiguration(
            responses=ResponsesProtocolConfiguration(),
            activity=ActivityProtocolConfiguration(),
        ),
        authorization_schemes=[EntraAuthorizationScheme(), BotServiceRbacAuthorizationScheme()],
    )
    for attempt in range(1, 61):
        try:
            project.agents.update_details(agent_name=AGENT_NAME, agent_endpoint=endpoint)
            return
        except HttpResponseError as error:
            if error.status_code not in {403, 404, 409} or attempt == 60:
                raise RuntimeError(f"Foundry agent endpoint configuration failed: {error}") from error
            print(f"Foundry agent endpoint is not ready; waiting 10 seconds (attempt {attempt}/60)...")
            time.sleep(10)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--foundry-account-name", required=True)
    parser.add_argument("--project-name", required=True)
    parser.add_argument("--model-deployment-name", required=True)
    parser.add_argument("--vector-store-id", required=True)
    parser.add_argument("--fabric-mcp-url", required=True)
    args = parser.parse_args()

    endpoint = project_endpoint(args.foundry_account_name, args.project_name)
    credential = credential_from_environment()
    project = create_project_client(endpoint, credential)
    try:
        agent = create_agent_when_ready(
            project,
            args.model_deployment_name,
            args.vector_store_id,
            args.fabric_mcp_url,
        )
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
