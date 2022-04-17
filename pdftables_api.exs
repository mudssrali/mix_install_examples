Mix.install([
  {:tesla, "~> 1.4"},
  {:hackney, "~> 1.18"},
  {:jason, "~> 1.3"}
])

defmodule PdfTablesApi do
  alias Tesla.Multipart

  @api_host "https://pdftables.com/api"
  @api_key ""
  # @output_formats ~w(csv xml html xlsx-single xlsx-multiple)
  @dir_path "./"

  @recv_timeout 30_000

  @doc """
  Converts PDF file to given format

  ## Examples
  iex> PdfTablesApi.convert("example.pdf")
  :ok
  iex PdfTablesApi.convert("example2.pdf", "csv")
  :ok
  """
  @spec convert(filename :: String.t(), format :: String.t()) :: :ok | {:error, any()}
  def convert(filename, format \\ "xlsx-multiple") do
    file_path = @dir_path <> filename

    # Remove extension from filename
    filename = String.replace(filename, ~r/\.[^.]*$/, "")

    client = client()

    mp =
      Multipart.new()
      |> Multipart.add_file(file_path,
        name: "f",
        headers: [{"content-type", "multipart/form-data"}]
      )

    # Base URL is configured to call the API, so
    # path would be empty string
    path = ""

    case Tesla.post(client, path, mp,
           query: [
             key: @api_key,
             format: format
           ]
         ) do
      {:ok, res} ->
        # Create extension from given format
        extension = if String.contains?(format, "xlsx"), do: ".xlsx", else: "." <> format

        # Output file path
        output_path = @dir_path <> filename <> extension

        File.write!(output_path, res.body)

      {:error, reason} ->
        IO.inspect(reason)
    end
  end

  @doc """
  Return remaining pages balance

  ## Examples
  iex> PdfTablesApi.get_remaining_pages()
  {:ok, 69}
  """
  @spec get_remaining_pages() :: {:ok, neg_integer()} | {:error, any()}
  def get_remaining_pages() do
    client = client()

    path = "/remaining"

    case Tesla.get(client, path,
           query: [
             key: @api_key
           ]
         ) do
      {:ok, res} ->
        {pages, _rem} = res.body |> Integer.parse()
        {:ok, pages}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp client() do
    Tesla.client(
      [
        {Tesla.Middleware.BaseUrl, @api_host},
        {Tesla.Middleware.JSON, engine: Jason}
      ],
      {
        Tesla.Adapter.Hackney,
        ssl_options: [verify: :verify_none], recv_timeout: @recv_timeout
      }
    )
  end
end
