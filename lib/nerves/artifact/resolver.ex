defmodule Nerves.Artifact.Resolver do
  @callback get(term) :: {:ok, data :: String.t()} | {:error, term}

  @spec get(term, pkg :: Nerves.Package.t()) :: {:ok, file :: String.t()} | {:error, term}



  def get([], _pkg) do
    {:error, :no_result}
  end

  def get([resolver | resolvers], pkg) do
    case get(resolver, pkg) do
      {:ok, _} = result -> result
      _ -> get(resolvers, pkg)
    end
  end

  def get({resolver, opts}, pkg) do
    do_get({resolver, opts}, pkg)
  end

  defp do_get(_, _, _ \\ 0)
  defp do_get({resolver, opts}, pkg, attempt) do
    apply(resolver, :get, [opts])
    |> result({resolver, opts}, pkg)
  end

  defp result({:ok, data}, _resolver, pkg) do
    file = Nerves.Artifact.download_path(pkg)
    File.mkdir_p(Nerves.Env.download_dir())
    File.write(file, data)

    case Nerves.Utils.File.validate(file) do
      :ok ->
        IO.puts "Valid"
        {:ok, file}

      {:error, reason} ->
        bytes = byte_size(data)
        IO.puts "Bytes: #{inspect bytes}"
        IO.puts "Invalid: #{inspect reason}"
        File.rm(file)
        {:error, reason}
    end
  end

  defp result(error, _resolver, _pkg), do: error
end
