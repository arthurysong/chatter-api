FROM elixir

# Set exposed ports
EXPOSE 4000

# Cache elixir deps
ADD mix.exs mix.lock ./
RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix do deps.get, deps.compile

ADD . .

# USER default

# ENTRYPOINT ["tail", "-f", "/dev/null"]

# CMD ["iex", "-S", "mix"]
CMD ["mix", "run", "--no-halt"]