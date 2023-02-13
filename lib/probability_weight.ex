defmodule ProbabilityWeight do
  @moduledoc """
  A collection of functions for randomly choosing from a weighted list
  """

  @doc """
  Transforms a list of {item, weight} tuples into two lists: items and weights
  Items with weights less than 1 or non-integer weights are skipped
  """
  def to_cdf(weight_tuples) do
    Enum.reduce(weight_tuples, {[], [0]}, &cdf_trans/2)
  end

  defp cdf_trans({item, weight}, {items, weights}) when weight > 0 and is_integer(weight) do
    {[item | items], [hd(weights) + weight | weights]}
  end

  defp cdf_trans(_, r), do: r

  @doc """
  Matches the first item before the item whose num > sum
  Assumes that the final item in sums is 0 and the total sum has been truncated
  """
  def match_item({[item | items], [sum | sums]}, num) when is_number(num) and num > 0 do
    if num > sum do
      item
    else
      match_item({items, sums}, num)
    end
  end

  @doc """
  Similar to python's random.choices
  each weight tuple is {item, int} representing the relative weight
  """
  def weighted_random(weight_tuples, n \\ 1) do
    weight_tuples
    |> to_cdf
    |> random_cdf(n)
  end

  @doc """
  Returns a list of n random items from the {item, cum_sum} tuple.
  This assumes that len(cum_cum) = len(items) + 1 and that the final element of cum_sum is 0.
  """
  def random_cdf({items, [total | weights]}, n \\ 1) do
    for _ <- 1..n,
        into: [] do
      match_item({items, weights}, Enum.random(1..total))
    end
  end
end
