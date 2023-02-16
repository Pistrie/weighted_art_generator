defmodule Mix.Tasks.PossibleCombinations do
  use Mix.Task

  @shortdoc "Prints the amount of possible combinations"
  @moduledoc """
  Prints the amount of possible combinations

  ## Examples

  ```
  mix possible_combinations
  ```
  """

  def run(_) do
    WeightedArtGenerator.get_possible_combinations_amount()
    |> IO.puts()
  end
end
