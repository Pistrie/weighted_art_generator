defmodule WeightedArtGenerator do
  @image_types [:background, :accessory, :eye, :face, :hair]
  @common_weight 3
  @rare_weight 2
  @epic_weight 1

  @doc """
  This functions will create image configs, without checking the amount of possible combinations
  Use get_possible_combinations_amount to see the amount of possible combinations
  """
  def kickoff(amount \\ 1) do
    if get_possible_combinations_amount() < amount,
      do: raise("supplied amount parameter is larger than the amount of possible combinations")

    weighted_image_layers = create_weight_tuples()

    create_n_configs([], weighted_image_layers, amount)
    |> Enum.reduce(0, fn config, acc ->
      config_to_image(config, acc)
      IO.puts("created #{acc}.png")
      acc + 1
    end)
  end

  @doc """
  This function will create image configs, while keeping the artificial scarcity in mind
  It divides by @common_weight in order to have less images than the actual possible combinations
  """
  def kickoff_scarcity(n_workers) do
    # setup
    workers = for i <- 0..(n_workers - 1), into: %{}, do: {i, ArtGeneratorWorker.start()}
    controlled_amount = get_possible_combinations_amount() / @common_weight
    weighted_image_layers = create_weight_tuples()
    configs = create_n_configs([], weighted_image_layers, controlled_amount)

    # give the workers their tasks until there are no more tasks
    Enum.each(0..(length(configs) - 1), fn config_index ->
      i_worker = rem(config_index, n_workers)
      worker = Map.get(workers, i_worker)
      config = Enum.at(configs, config_index)
      send(worker, {:create_image, {config, config_index}})
    end)

    # terminate all the workers
    workers
    |> Enum.each(fn {_, w} ->
      send(w, {:terminate, self()})

      receive do
        {:done} -> {:nothing}
      end
    end)
  end

  @doc """
  Returns the amount of possible layer combinations
  """
  def get_possible_combinations_amount do
    Enum.map(@image_types, fn type ->
      if type != :background do
        Path.wildcard("pixel_punk_images/#{type}*/*.png") |> length()
      else
        # return one otherwise it returns nil, and you cant multiply by nil
        1
      end
    end)
    |> Enum.reduce(1, fn amount, acc -> acc * amount end)
  end

  # TODO figure out whether elixir waits for imagemagick to finish. i suspect that it will move on to the next layer before the current one is done

  # convert a layer config into an actual image
  def config_to_image(config, nth_image) do
    if not File.exists?("generated_images/"), do: File.mkdir!("generated_images")

    # first layering, creates the file in generated_images/
    System.cmd("convert", [
      "#{Enum.at(config, 0)}",
      "#{Enum.at(config, 1)}",
      "-composite",
      "generated_images/#{nth_image}.png"
    ])

    # rest of the layering based on the first one
    for layer <- 2..(length(config) - 1) do
      System.cmd("convert", [
        "generated_images/#{nth_image}.png",
        "#{Enum.at(config, layer)}",
        "-composite",
        "generated_images/#{nth_image}.png"
      ])
    end
  end

  defp get_images(image_type, rarity) do
    Path.wildcard("pixel_punk_images/#{image_type}_#{rarity}/*.png")
  end

  # turn the file paths into weighted tuples so they can be used by ProbabilityWeight.weighted_random/2
  defp create_weight_tuples do
    # create the different types with their rarity
    background_common = get_images(:background, :common)
    accessory_common = get_images(:accessory, :common)
    accessory_rare = get_images(:accessory, :rare)
    accessory_epic = get_images(:accessory, :epic)
    eye_common = get_images(:eye, :common)
    eye_rare = get_images(:eye, :rare)
    eye_epic = get_images(:eye, :epic)
    face_common = get_images(:face, :common)
    hair_common = get_images(:hair, :common)
    hair_rare = get_images(:hair, :rare)

    # turn the list with rarities into weighted tuples
    weighted_background_common =
      Enum.map(background_common, fn image -> {image, @common_weight} end)

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

    # flatten the list according to their categories
    weighted_backgrounds =
      List.flatten([
        weighted_background_common
      ])

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

    # the order matters
    # lower layer to higher layer -> background, face, eyes, hair, accessories
    [
      weighted_backgrounds,
      weighted_faces,
      weighted_eyes,
      weighted_hair,
      weighted_accessories
    ]
  end

  # create a config for the art to be used by imagemagick
  defp create_art_config(list_with_weighted_categories) do
    # remove the background
    [backgrounds | categories] = list_with_weighted_categories

    config =
      for category <- categories do
        ProbabilityWeight.weighted_random(category)
      end

    # add the background afterwards in order to not create a huge amount of possible configs
    background = ProbabilityWeight.weighted_random(backgrounds)

    [background | config]
  end

  # create a certain amount of configurations depending on the parameter
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
