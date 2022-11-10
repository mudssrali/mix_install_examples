Mix.install([
  {:tesla, "~> 1.4"},
  {:hackney, "~> 1.18"},
  {:jason, "~> 1.4"}
])

defmodule CoinGecko do
  @moduledoc """
  Provides helper functions to interact with CoinGecko API
  """
  require Logger

  @api_host "https://api.coingecko.com/api/v3"

  @recv_timeout 30_000
  @currency "usd"
  @days_ago 14
  @data_interval "daily"

  @doc """
  Searches for coins, categories and markets listed on CoinGecko ordered by largest Market Cap first
  """
  @spec search(query :: String.t()) :: {:ok, map()} | {:error, any()}
  def search(query) when is_binary(query) do
    client = client()

    case Tesla.get(client, "/search", query: [query: query]) do
      {:ok, response} ->
        {:ok, response.body}

      {:error, reason} = error ->
        Logger.error(fn -> "coins search by name: " <> inspect(reason) end)

        error
    end
  end

  def search(_), do: {:error, "invalid search text."}

  @doc """
  Get current data (name, price, market, ... including exchange tickers) for a coin
  """
  @spec get_by_id(id :: String.t()) :: {:ok, map()} | {:error, any()}
  def get_by_id(id) when is_binary(id) do
    client = client()

    path = "/coins/#{id}"

    case Tesla.get(client, path) do
      {:ok, response} ->
        {:ok, response.body}

      {:error, reason} = error ->
        Logger.error(fn -> "get coin by id: " <> inspect(reason) end)
        error
    end
  end

  def get_by_id(_), do: {:error, "invalid coin id."}

  @doc """
  Get historical market data include price, market cap, and 24h volume (granularity auto) for a coin
  """
  @spec get_market_chart(
          id :: String.t(),
          currency :: String.t(),
          days :: non_neg_integer(),
          interval :: String.t()
        ) :: {:ok, map()} | {:error, any()}
  def get_market_chart(id, currency \\ @currency, days \\ @days_ago, interval \\ @data_interval)

  def get_market_chart(id, currency, days, interval) when is_binary(id) do
    client = client()

    path = "/coins/#{id}/market_chart"

    case Tesla.get(client, path,
           query: [
             vs_currency: currency,
             days: days,
             interval: interval
           ]
         ) do
      {:ok, response} ->
        {:ok, response.body}

      {:error, reason} = error ->
        Logger.error(fn -> "coin historical market data: " <> inspect(reason) end)
        error
    end
  end

  def get_market_chart(_, _, _, _), do: {:error, "invalid coin id."}

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
