defmodule Mix.Tasks.Kickoff.Scarcity do
  use Mix.Task

  @shortdoc "Creates amount of images equal to 1/3 of the possible combinations"
  @moduledoc """
  Creates the amount of images equal to 1/3 of the possible combinations

  ## Examples

  ```
  mix kickoff.scarcity
  ```
  """

  def run([n_workers | _]) do
    {n_workers, ""} = Integer.parse(n_workers, 10)
    WeightedArtGenerator.kickoff_scarcity(n_workers)
  end
end
