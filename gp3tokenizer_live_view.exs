Application.put_env(:gpt3, Gpt3TokenizerDemo.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 5001],
  server: true,
  live_view: [signing_salt: "random-salt"],
  secret_key_base: String.duplicate("xyz", 21)
)

Mix.install([
  {:plug_cowboy, "~> 2.5"},
  {:jason, "~> 1.4"},
  {:phoenix, "~> 1.7.2"},
  {:phoenix_live_view, "~> 0.19.5"},
  {:gpt3_tokenizer, github: "mudssrali/gpt3-tokenizer-elixir"}
])

defmodule Gpt3TokenizerDemo.ErrorView do
  def render(template, _), do: Phoenix.Controller.status_message_from_template(template)
end

defmodule Gpt3TokenizerDemo.Gpt3Live do
  use Phoenix.LiveView, layout: {__MODULE__, :live}

  @default_state %{
    token_ids: [],
    input_text: "",
    tokenizer_view: :bpe,
    show_example: false
  }

  def mount(_params, _session, socket) do
    {:ok, assign(socket, state: @default_state)}
  end

  def render("live.html", assigns) do
    ~H"""
    <script src="https://cdn.jsdelivr.net/npm/phoenix@1.7.2/priv/static/phoenix.min.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/phoenix_live_view@0.18.18/priv/static/phoenix_live_view.min.js"></script>
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin="">
    <link href="https://fonts.googleapis.com/css2?family=Roboto+Mono:wght@400;700&display=swap" rel="stylesheet">
    <script src="https://cdn.tailwindcss.com"></script>
    <script>
      let liveSocket = new window.LiveView.LiveSocket("/live", window.Phoenix.Socket)
      liveSocket.connect()
    </script>
    <%= @inner_content %>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="relative flex min-h-screen flex-col justify-center overflow-hidden bg-gray-50 py-4 sm:py-10">
      <div class="p-4 w-full md:w-2/5 mx-auto text-gray-700 text-sm">
        <div class="space-y-4">
          <h4 class="text-2xl font-semibold text-gray-900 py-px">Tokenizer</h4>
          <p>
            The GPT family of models process text using <strong>tokens</strong>, which are common
            sequences of characters found in text. The models understand the statistical relationships
            between these tokens, and excel at producing the next token in a sequence of tokens.
          </p>
          <p>
            You can use the tool below to understand how a piece of text would be tokenized by the API, and the
            total count of tokens in that piece of text.
          </p>
          <div class="space-y-2">
            <div class="space-x-1">
              <button class="bg-[#10a37f33] text-sm font-medium text-[#1a7f64] rounded-sm w-12 text-center px-0.5 py-px">GPT-3</button>
              <button class="font-medium  text-sm text-[#1a7f64] rounded-sm w-12 text-center px-0.5 py-px">Codex</button>
            </div>
            <textarea class="w-full p-2.5 min-h-[150px] max-h-[200px] overflow-y-auto border rounded-sm focus:outline-none focus:ring-1 focus:border-[#1a7f64] focus:ring-[#1a7f64]"
              cols="6"
              rows="6"
              phx-keyup="input_text"
              placeholder="Enter some text"><%= @state.input_text %></textarea>
            <div class="space-x-2">
              <button
                class="bg-gray-200 hover:bg-gray-300 rounded-sm px-2.5 py-1.5 text-xs"
                phx-click="clear_input">
                Clear
              </button>
              <button
                disabled={@state.show_example}
                class={[
                  "rounded-sm px-2.5 py-1.5 text-xs",
                  (if @state.show_example, do: "bg-gray-100", else: "bg-gray-200 hover:bg-gray-300")
                ]}
                phx-click="show_example">
                Show Example
              </button>
            </div>
          </div>

          <div class="flex flex-row gap-14 text-lg text-gray-900">
            <div>
              <p class="font-medium">Tokens</p>
              <p><%= length(@state.token_ids) %></p>
            </div>
            <div>
              <p class="font-medium">Characters</p>
              <p><%= String.length(@state.input_text) %></p>
            </div>
          </div>

          <% decoded_text = if @state.tokenizer_view == :text, do: Gpt3Tokenizer.decode_with_text(@state.token_ids), else: [] %>

          <div class="relative block bg-gray-100 rounded-sm min-h-[150px] p-2.5 font-mono text-sm">
              <%= if length(@state.token_ids) > 0 and @state.tokenizer_view == :bpe  do %>
                <div class="max-h-[200px] overflow-y-auto pb-10">
                  <%= "[#{Enum.join(@state.token_ids, ", ")}]" %>
                </div>
              <% end %>

              <%= if @state.tokenizer_view == :text do %>
                <div class="max-h-[200px] overflow-y-auto pb-10">
                  <%= for {token, i}  <- Enum.with_index(decoded_text) do %>
                    <%!--
                      Rendering <br /> for new-line characters. There's one token for two consecutive
                      lines so we need to split the new lines characters and rendering line breaking
                      tags accordingly
                    --%>
                    <%= if String.contains?(token, "\n") do %>
                      <%= for _nl <- String.split(token, "", trim: true) do %>
                        <br/>
                      <% end %>
                    <% else %>
                      <span
                        class={[
                          "whitespace-pre inline-block -mr-[8.5px]",
                          (case rem(i, 5) do
                            0 ->
                              "bg-[#6b40d84d]"
                            1 ->
                              "bg-[#68de7a66]"
                            2 ->
                              "bg-[#f4ac3666]"
                            3 ->
                              "bg-[#ef414666]"
                            4 ->
                              "bg-[#27b5ea66]"
                          end)
                        ]}
                      ><%= if String.valid?(token), do: token, else: "�" %></span>
                    <% end %>
                  <% end %>
                </div>
              <% end %>

            <div class="absolute bottom-2">
              <button
                class={[
                  "rounded px-2.5 py-1.5 text-xs uppercase",
                  (if @state.tokenizer_view == :text, do: "bg-gray-200", else: "bg-gray-100")
                ]}
                phx-click="tokenizer_view_text">
                Text
              </button>
              <button
                class={[
                    "rounded px-2.5 py-1.5 text-xs uppercase",
                    (if @state.tokenizer_view == :bpe, do: "bg-gray-200", else: "bg-gray-100")
                  ]}
                phx-click="tokenizer_view_bpe">
                  Token Ids
              </button>
            </div>
          </div>
          <%= if Enum.any?(decoded_text, fn text -> not String.valid?(text) end) do %>
            <div class="px-2 py-1.5 bg-[#d2f4d3] rounded-sm text-sm text-[#1a7f64]">
              <strong>Note:</strong>
              Your input contained one or more unicode characters that map to multiple tokens.
              The output visualization may display the bytes in each token in a non-standard way.
            </div>
          <% end %>
          <p>
            A helpful rule of thumb is that one token generally corresponds to ~4 characters of text for
            common English text. This translates to roughly ¾ of a word (so 100 tokens ~= 75 words).
          </p>
          <p>
            If you need a programmatic interface for tokenizing text, check out our
            <a href="https://github.com/openai/tiktoken" class="text-[#10a37f] hover:text-[#1a7f64]">tiktoken</a>
            package for Python. For JavaScript, the <a href="https://www.npmjs.com/package/gpt-3-encoder" class="text-[#10a37f] hover:text-[#1a7f64]">gpt-3-encoder</a>
            package for node.js works for most GPT-3 models.</p>
        </div>
      </div>
    </div>
    """
  end

  def handle_event("input_text", %{"value" => text, "key" => _key}, socket) do
    send_reply(
      %{
        token_ids: Gpt3Tokenizer.encode(text),
        input_text: text,
        show_example: false
      },
      socket
    )
  end

  def handle_event("show_example", _params, socket) do
    text = """
    Many words map to one token, but some don't: indivisible.

    Unicode characters like emojis may be split into many tokens containing the underlying bytes: 🤚🏾

    Sequences of characters commonly found next to each other may be grouped together: 1234567890
    """

    send_reply(
      %{
        token_ids: Gpt3Tokenizer.encode(text),
        input_text: text,
        show_example: true
      },
      socket
    )
  end

  def handle_event("clear_input", _params, socket) do
    send_reply(
      %{
        token_ids: [],
        input_text: "",
        show_example: false
      },
      socket
    )
  end

  def handle_event("tokenizer_view_bpe", _params, socket) do
    send_reply(
      %{
        tokenizer_view: :bpe
      },
      socket
    )
  end

  def handle_event("tokenizer_view_text", _params, socket) do
    send_reply(
      %{
        tokenizer_view: :text
      },
      socket
    )
  end

  defp send_reply(new_state, socket) do
    new_state = Map.merge(socket.assigns.state, new_state)
    {:noreply, assign(socket, state: new_state)}
  end
end

defmodule Gpt3TokenizerDemo.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router

  pipeline :browser do
    plug(:accepts, ["html"])
  end

  scope "/", Gpt3TokenizerDemo do
    pipe_through(:browser)

    live("/", Gpt3Live, :index)
  end
end

defmodule Gpt3TokenizerDemo.Endpoint do
  use Phoenix.Endpoint, otp_app: :gpt3
  socket("/live", Phoenix.LiveView.Socket)
  plug(Gpt3TokenizerDemo.Router)
end

{:ok, _} = Supervisor.start_link([Gpt3TokenizerDemo.Endpoint], strategy: :one_for_one)

# unless running from IEx, sleep idenfinitely so we can serve requests
unless IEx.started?() do
  Process.sleep(:infinity)
end
