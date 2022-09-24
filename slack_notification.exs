Mix.install([
  {:tesla, "~> 1.4"},
  {:hackney, "~> 1.18"},
  {:jason, "~> 1.4"}
])

defmodule Slack do
  @moduledoc """
  This modules provide helper functions to send notification to Slack channels
  """
  use Tesla

  @token "PLACE_YOUR_TOKEN_HERE"
  @default_channel "#example"
  @notification_payload %{
    "username" => "elixir-bot",
    "icon_emoji" => ":robot_face:"
  }

  @doc """
  Send an alert with simple or advance formatting

  ## Examples
  iex> Slack.send_alert("Hello World", "#temp")
  :ok

  iex> Slack.send_alert(["*Hello World*", "`Mix.install()` is just awesome. Slack <3 Markdown!"])
  :ok
  """
  @spec send_alert(
          text_or_blocks :: String.t() | [String.t()],
          channel :: String.t()
        ) :: :ok

  def send_alert(text_or_blocks, channel \\ @default_channel)

  def send_alert(text_or_blocks, channel) when is_list(text_or_blocks) do
    blocks = transform_blocks(text_or_blocks)

    @notification_payload
    |> Map.put("blocks", blocks)
    |> Map.put("channel", channel)
    |> send_notification()

    :ok
  end

  def send_alert(text, channel) do
    @notification_payload
    |> Map.put("text", text)
    |> Map.put("channel", channel)
    |> send_notification()

    :ok
  end

  defp send_notification(payload) do
    url = "https://hooks.slack.com/services/" <> @token

    body = Jason.encode!(payload)
    {:ok, _response} = Tesla.post(url, body)
  end

  defp transform_blocks(blocks) do
    Enum.map(blocks, fn text ->
      %{
        type: "section",
        text: %{
          type: "mrkdwn",
          text: text
        }
      }
    end)
  end
end
