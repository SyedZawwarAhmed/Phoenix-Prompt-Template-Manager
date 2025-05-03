defmodule PromptManagerWeb.TemplateLive.Index do
  use PromptManagerWeb, :live_view
  alias PromptManager.{Template, TemplateStore}

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Phoenix.PubSub.subscribe(PromptManager.PubSub, "templates")

    templates = TemplateStore.all_templates()

    {:ok,
     socket
     |> assign(:templates, templates)
     |> assign(:active_template, nil)
     |> assign(:current_template, %Template{name: "", body: ""})
     |> assign(:show_form, false)
     |> assign(:editing, false)
     |> assign(:model_input, "")
     |> assign(:processed_prompt, nil)}
  end

  @impl true
  def handle_event("new", _, socket) do
    {:noreply,
     socket
     |> assign(:current_template, %Template{name: "", body: ""})
     |> assign(:show_form, true)
     |> assign(:editing, false)}
  end

  @impl true
  def handle_event("edit", %{"id" => id}, socket) do
    id = String.to_integer(id)
    template = TemplateStore.get_template(id)

    {:noreply,
     socket
     |> assign(:current_template, template)
     |> assign(:show_form, true)
     |> assign(:editing, true)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    id = String.to_integer(id)
    :ok = TemplateStore.delete_template(id)
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel", _, socket) do
    {:noreply,
     socket
     |> assign(:show_form, false)
     |> assign(:current_template, %Template{name: "", body: ""})}
  end

  @impl true
  def handle_event("save", %{"template" => params}, socket) do
    if socket.assigns.editing do
      {:ok, template} =
        TemplateStore.update_template(
          socket.assigns.current_template.id,
          params["name"],
          params["body"]
        )

      {:noreply,
       socket
       |> assign(:show_form, false)
       |> assign(:current_template, %Template{name: "", body: ""})}
    else
      template = TemplateStore.create_template(params["name"], params["body"])

      {:noreply,
       socket
       |> assign(:show_form, false)
       |> assign(:current_template, %Template{name: "", body: ""})}
    end
  end

  @impl true
  def handle_event("run", %{"id" => id}, socket) do
    id = String.to_integer(id)
    template = TemplateStore.get_template(id)

    {:noreply,
     socket
     |> assign(:active_template, template)
     |> assign(:model_input, "")
     |> assign(:processed_prompt, nil)}
  end

  @impl true
  def handle_event("process_prompt", %{"model" => model}, socket) do
    template = socket.assigns.active_template
    today = Date.utc_today() |> Date.to_string()

    processed_prompt =
      template.body
      |> String.replace("[[today]]", today)
      |> String.replace("[[model]]", model)

    {:noreply,
     socket
     |> assign(:model_input, model)
     |> assign(:processed_prompt, processed_prompt)}
  end

  @impl true
  def handle_event("close_prompt", _, socket) do
    {:noreply,
     socket
     |> assign(:active_template, nil)
     |> assign(:model_input, "")
     |> assign(:processed_prompt, nil)}
  end

  @impl true
  def handle_info({:template_created, template}, socket) do
    templates = [template | socket.assigns.templates]
    {:noreply, assign(socket, :templates, templates)}
  end

  @impl true
  def handle_info({:template_updated, updated_template}, socket) do
    templates =
      Enum.map(socket.assigns.templates, fn t ->
        if t.id == updated_template.id, do: updated_template, else: t
      end)

    {:noreply, assign(socket, :templates, templates)}
  end

  @impl true
  def handle_info({:template_deleted, deleted_template}, socket) do
    templates = Enum.filter(socket.assigns.templates, &(&1.id != deleted_template.id))
    {:noreply, assign(socket, :templates, templates)}
  end
end
