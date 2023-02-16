defmodule Mix.Tasks.Kickoff.Scarcity do
  use Mix.Task

  @shortdoc "Creates amount of images equal to 1/3 of the possible combinations"
  @moduledoc """
  Creates the amount of images equal to 1/3 of the possible combinations. You can supply it with a parameter for the amount of processes that will be used to generate the images

  ## Examples

  ```
  mix kickoff.scarcity
  mix kickoff.scarcity 400
  ```
  """

  def run([n_workers | _] \\ ["100"]) do
    {n_workers, ""} = Integer.parse(n_workers, 10)
    WeightedArtGenerator.kickoff_scarcity(n_workers)
  end
end
