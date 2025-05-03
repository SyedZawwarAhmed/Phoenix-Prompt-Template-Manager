defmodule PromptManager.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      PromptManagerWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: PromptManager.PubSub},
      # Start the Endpoint (http/https)
      PromptManagerWeb.Endpoint,
      # Start a worker by calling: PromptManager.Worker.start_link(arg)
      # {PromptManager.Worker, arg}
      {PromptManager.TemplateStore, []}
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
