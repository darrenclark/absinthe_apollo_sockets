defmodule ApolloCowboyExample.HttpHandler do
  require Logger

  def init(_, request, options) do
    Logger.debug("HttpHandler.init #{inspect options}")
    {:ok, request, {Keyword.get(options, :schema), Keyword.get(options, :pubsub)}}
  end

  def handle(request, {schema, pubsub}) do
    req2 = 
      request
      |> validate_method()
      |> read_body()
      |> parse_json()
      |> run(schema, pubsub)
      |> to_json()
      |> reply()
    {:ok, req2, :no_state}
  end

  def terminate(_reason, _req, _state), do: :ok

  defp validate_method(request) do
    {"POST", req2} = :cowboy_req.method(request)
    req2
  end

  defp read_body(request) do
    read_body("", :cowboy_req.body(request))
  end
  defp read_body(acc, {:ok, data, req2}), do: {acc <> data, req2}
  defp read_body(acc, {:more, data, req2}) do
    read_body(acc <> data, :cowboy_req.body(req2))
  end
  defp read_body(_acc, {:error, reason}) do
    raise "Failed to read body #{reason}"
  end

  defp parse_json({body, request}), do: {Jason.decode!(body), request}
  defp to_json({query_response, request}), do: {Jason.encode!(query_response), request}

  defp run({%{"query" => query} = json, request}, schema, pubsub) do
    opts = 
      [context: %{pubsub: pubsub}]
      |> add_variables(json["variables"])

    result = Absinthe.run(query, schema, opts)
    case result do
      {:ok, %{"subscribed" => _}} ->
        {%{errors: [%{message: "Please use websockets for subscriptions"}]}, request}

      {:ok, query_response } -> 
        {query_response, request}
    end
  end

  defp add_variables(opts, nil), do: opts
  defp add_variables(opts, variables), do: Keyword.put(opts, :variables, variables)

  defp reply({result_body, request}) do
    {:ok, req2} = :cowboy_req.reply(200, [{"Content-type", "application/json"}], result_body, request)
    req2
  end

end
