defmodule PromptManager.Template do
  @derive {Jason.Encoder, only: [:id, :name, :body]}
  defstruct [:id, :name, :body]
end

