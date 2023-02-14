defmodule Mix.Tasks.Kickoff do
  use Mix.Task

  @shortdoc "Creates amount of images equal to the supplied parameter"
  @moduledoc """
  Creates the amount of images equal to the supplied parameter

  ## Examples

  ```
  mix kickoff 10
  ```
  """

  def run([amount | _]) do
    String.to_integer(amount)
    |> WeightedArtGenerator.kickoff()
  end
end
