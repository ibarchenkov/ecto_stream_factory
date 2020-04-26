defmodule EctoStreamFactory.UndefinedGeneratorError do
  @moduledoc """
  Error raised when trying to build or insert a record using undefined generator.
  """

  defexception [:module, :generator_name]

  @impl true
  def message(%{module: module, generator_name: generator_name}) do
    module = EctoStreamFactory.Factory.module_to_string(module)
    generator_name = inspect(generator_name)

    """
    No generator defined for #{generator_name}.
    Please check for typos or define your generator:

        defmodule #{module} do
          def #{generator_name}_generator do
            ...
          end
        end
    """
  end
end

defmodule EctoStreamFactory.RepoNotSpecifiedError do
  @moduledoc """
  Error raised when `use EctoStreamFactory` is missing `:repo` option
  """

  defexception [:module]

  @impl true
  def message(%{module: module}) do
    module = EctoStreamFactory.Factory.module_to_string(module)
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
