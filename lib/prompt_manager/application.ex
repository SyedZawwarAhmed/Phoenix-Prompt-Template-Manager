defmodule PromptManager.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PromptManagerWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:prompt_manager, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PromptManager.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: PromptManager.Finch},
      # Start a worker by calling: PromptManager.Worker.start_link(arg)
      # {PromptManager.Worker, arg},
      # Start to serve requests, typically the last entry
      PromptManagerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PromptManager.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PromptManagerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
