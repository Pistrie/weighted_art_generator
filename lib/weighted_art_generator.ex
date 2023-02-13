defmodule WeightedArtGenerator do
  # https://github.com/elixir-mogrify/mogrify/issues/39#issuecomment-287486610
  # image = Mogrify.open("pixel_punk_images/0_face/face_1.png")
  @image_types [:accessory, :eye, :face, :hair]
  @common_weight 3
  @rare_weight 2
  @epic_weight 1

  def save_copy_to_tmp do
    Mogrify.open("pixel_punk_images/0_face/face_1.png") |> Mogrify.save()
  end

  defp get_images(image_type, rarity) do
    Path.wildcard("pixel_punk_images/#{image_type}_#{rarity}/*.png")
  end

  # turn the file paths into weighted tuples so they can be used by ProbabilityWeight.weighted_random/2
  defp create_weight_tuples do
    accessory_common = get_images(:accessory, :common)
    accessory_rare = get_images(:accessory, :rare)
    accessory_epic = get_images(:accessory, :epic)
    eye_common = get_images(:eye, :common)
    eye_rare = get_images(:eye, :rare)
    eye_epic = get_images(:eye, :epic)
    face_common = get_images(:face, :common)
    hair_common = get_images(:hair, :common)
    hair_rare = get_images(:hair, :rare)

    weighted_accessory_common =
      Enum.map(accessory_common, fn image -> {image, @common_weight} end)

    weighted_accessory_rare = Enum.map(accessory_rare, fn image -> {image, @rare_weight} end)
    weighted_accessory_epic = Enum.map(accessory_epic, fn image -> {image, @epic_weight} end)
    weighted_eye_common = Enum.map(eye_common, fn image -> {image, @common_weight} end)
    weighted_eye_rare = Enum.map(eye_rare, fn image -> {image, @rare_weight} end)
    weighted_eye_epic = Enum.map(eye_epic, fn image -> {image, @epic_weight} end)
    weighted_face_common = Enum.map(face_common, fn image -> {image, @common_weight} end)
    weighted_hair_common = Enum.map(hair_common, fn image -> {image, @common_weight} end)
    weighted_hair_rare = Enum.map(hair_rare, fn image -> {image, @rare_weight} end)

    weighted_accessories =
      List.flatten([
        weighted_accessory_common,
        weighted_accessory_epic,
        weighted_accessory_rare
      ])

    weighted_eyes =
      List.flatten([
        weighted_eye_common,
        weighted_eye_epic,
        weighted_eye_rare
      ])

    weighted_faces =
      List.flatten([
        weighted_face_common
      ])

    weighted_hair =
      List.flatten([
        weighted_hair_common,
        weighted_hair_rare
      ])

    [weighted_faces, weighted_eyes, weighted_hair, weighted_accessories] # the order matters
  end

  # create a config for the art to be used by Mogrify
  defp create_art_config(list_options_with_weight) do
    Enum.flat_map(list_options_with_weight, fn category ->
      ProbabilityWeight.weighted_random(category)
    end)
  end

  @doc """
  This functions will create image configs, without checking the amount of possible combinations
  Use get_possible_combinations_amount to see the amount of possible combinations
  """
  @spec kickoff(integer()) :: non_neg_integer
  def kickoff(amount \\ 10) do
    list_options_with_weight = create_weight_tuples()

    create_n_configs([], list_options_with_weight, amount)
  end

  @doc """
  This function will create image configs, while keeping the artificial scarcity in mind
  It divides by @common_weight in order to have less images than the actual possible combinations
  """
  @spec kickoff_scarcity :: non_neg_integer
  def kickoff_scarcity do
    controlled_amount = get_possible_combinations_amount() / @common_weight
    list_options_with_weight = create_weight_tuples()

    create_n_configs([], list_options_with_weight, controlled_amount)
  end

  @doc """
  Returns the amount of possible layer combinations
  """
  def get_possible_combinations_amount do
    Enum.map(@image_types, fn type ->
      Path.wildcard("pixel_punk_images/#{type}*/*.png") |> length()
    end)
    |> Enum.reduce(1, fn amount, acc -> acc * amount end)
  end

  defp create_n_configs(configs, options, amount, new_config \\ [], generations_amount \\ 0)

  defp create_n_configs(configs, options, amount, new_config, generations_amount)
       when length(configs) < amount do
    new_config = if length(new_config) == 0, do: create_art_config(options), else: new_config

    if Enum.member?(configs, new_config) do
      create_n_configs(configs, options, amount, [], generations_amount + 1)
    else
      create_n_configs([new_config | configs], options, amount, [], generations_amount + 1)
    end
  end

  defp create_n_configs(configs, _, _, _, generations_amount) do
    IO.puts("images: #{length(configs)}")
    IO.puts("took #{generations_amount} tries")
    configs
  end
end
