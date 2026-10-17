defmodule FzHttp.Telemetry.PostHog do
  require Logger

  def capture(event, metadata) do
    Logger.debug("Capturing event #{event}")

    Task.start(fn ->
      # Detach from calling process to prevent blocking
      properties = Map.new(metadata)
      {distinct_id, properties} = Map.pop!(properties, :distinct_id)
      PostHog.bare_capture(event, distinct_id, properties)
    end)
  end

  def batch(events) when is_list(events) do
    Logger.debug("Capturing events #{inspect(events)}")

    Task.start(fn ->
      Enum.each(events, fn event ->
        properties = Map.new(event.properties)
        {distinct_id, properties} = Map.pop!(properties, :distinct_id)
        PostHog.bare_capture(event.event, distinct_id, properties)
      end)
    end)
  end
end
