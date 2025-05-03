defmodule PromptManager.TemplateStore do
  use GenServer
  alias PromptManager.Template

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    # Using an ETS table for in-memory storage
    table = :ets.new(:templates, [:set, :protected, :named_table])
    {:ok, %{table: table, next_id: 1}}
  end

  def all_templates do
    GenServer.call(__MODULE__, :all_templates)
  end

  def get_template(id) do
    GenServer.call(__MODULE__, {:get_template, id})
  end

  def create_template(name, body) do
    GenServer.call(__MODULE__, {:create_template, name, body})
  end

  def update_template(id, name, body) do
    GenServer.call(__MODULE__, {:update_template, id, name, body})
  end

  def delete_template(id) do
    GenServer.call(__MODULE__, {:delete_template, id})
  end

  @impl true
  def handle_call(:all_templates, _from, state) do
    templates =
      :ets.tab2list(:templates)
      |> Enum.map(fn {_, template} -> template end)
      |> Enum.sort_by(& &1.id)

    {:reply, templates, state}
  end

  @impl true
  def handle_call({:get_template, id}, _from, state) do
    case :ets.lookup(:templates, id) do
      [{_, template}] -> {:reply, template, state}
      [] -> {:reply, nil, state}
    end
  end

  @impl true
  def handle_call({:create_template, name, body}, _from, %{next_id: next_id} = state) do
    template = %Template{id: next_id, name: name, body: body}
    :ets.insert(:templates, {next_id, template})
    Phoenix.PubSub.broadcast(PromptManager.PubSub, "templates", {:template_created, template})
    {:reply, template, %{state | next_id: next_id + 1}}
  end

  @impl true
  def handle_call({:update_template, id, name, body}, _from, state) do
    case :ets.lookup(:templates, id) do
      [{_, template}] ->
        updated_template = %{template | name: name, body: body}
        :ets.insert(:templates, {id, updated_template})
        Phoenix.PubSub.broadcast(PromptManager.PubSub, "templates", {:template_updated, updated_template})
        {:reply, {:ok, updated_template}, state}
      [] ->
        {:reply, :error, state}
    end
  end

  @impl true
  def handle_call({:delete_template, id}, _from, state) do
    case :ets.lookup(:templates, id) do
      [{_, template}] ->
        :ets.delete(:templates, id)
        Phoenix.PubSub.broadcast(PromptManager.PubSub, "templates", {:template_deleted, template})
        {:reply, :ok, state}
      [] ->
        {:reply, :error, state}
    end
  end
end
