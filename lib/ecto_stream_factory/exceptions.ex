defmodule EctoStreamFactory.UndefinedGeneratorError do
  @moduledoc false

  defexception [:module, :generator_name]

  @impl true
  def message(%{module: module, generator_name: gen_name}) do
    """
    No generator defined for #{inspect(gen_name)}.
    Please check for typos or define your generator:

        defmodule #{module} do
          def #{EctoStreamFactory.Factory.function_from_generator_name(gen_name)} do
            ...
          end
        end
    """
  end
end

defmodule EctoStreamFactory.RepoNotSpecifiedError do
  @moduledoc false

  defexception [:module]

  @impl true
  def message(%{module: module}) do
    repo_module = module |> String.split(".") |> hd()

    """
    :repo option is missing. Please configure the factory:

        defmodule #{module} do
          use EctoStreamFactory, repo: #{repo_module}.Repo
          ...
        end
    """
  end
end
