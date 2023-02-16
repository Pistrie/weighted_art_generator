defmodule ArtGeneratorWorker do
  def start do
    spawn(fn -> loop() end)
  end

  defp loop do
    receive do
      {:create_image, {config, image_number}} ->
        WeightedArtGenerator.config_to_image(config, image_number)
        IO.puts("created #{image_number}.png")
        loop()

      {:terminate, client_pid} ->
        send(client_pid, {:done})
    end
  end
end
