defmodule Mix.Tasks.Tai.Gen.Migration do
  @shortdoc "Generates migrations for tai"

  @moduledoc """
  Generates database migrations for tai repos:

  - Tai.NewOrders.OrderRepo
  """
  use Mix.Task

  import Mix.Ecto
  import Mix.Generator

  @doc false
  def run(args) do
    # TODO: Is this check actually required?
    # no_umbrella!("ecto.gen.migration")
    tai_app_dir = Application.app_dir(:tai)

    args
    |> tai_repos()
    |> Enum.each(fn repo ->
      ensure_repo(repo, args)

      repo_migrations_destination_dir_path = Ecto.Migrator.migrations_path(repo)
      create_directory(repo_migrations_destination_dir_path)

      tai_migration_templates_dir_path =
        Path.join(tai_app_dir, "priv/repo_templates/#{repo_template_dir(repo)}/migrations")

      tai_migration_templates_dir_path
      |> File.ls!()
      |> Enum.map(&Path.join(tai_migration_templates_dir_path, &1))
      |> Enum.map(fn migration_template_path ->
        basename = Path.basename(migration_template_path, ".eex")
        destination_path = Path.join(repo_migrations_destination_dir_path, basename)
        generated_migration = EEx.eval_file(migration_template_path, module_prefix: app_module())
        create_file(destination_path, generated_migration)
      end)
    end)
  end

  @tai_repos [Tai.NewOrders.OrderRepo]
  defp tai_repos(args) do
    args
    |> parse_repo()
    |> Enum.filter(fn r -> Enum.member?(@tai_repos, r) end)
  end

  defp repo_template_dir(repo) do
    repo
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
  end

  defp app_module do
    Mix.Project.config()
    |> Keyword.fetch!(:app)
    |> to_string()
    |> Macro.camelize()
  end
end
