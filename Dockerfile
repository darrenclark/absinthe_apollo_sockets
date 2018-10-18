FROM elixir:1.7.3

COPY . /app
WORKDIR /app/examples/apollo_cowboy/
RUN mix local.hex --force
RUN mix deps.get

EXPOSE 8080
CMD mix run --no-halt
