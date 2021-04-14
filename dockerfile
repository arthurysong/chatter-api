FROM elixir

# Set exposed ports
EXPOSE 4000
# ENV PORT=4000 MIX_ENV=prod APP_ID=1 RMQ_URL=amqp://test:test@rmq-791691136.us-west-1.elb.amazonaws.com:5672

# Cache elixir deps
ADD mix.exs mix.lock ./
RUN mix local.hex --force
RUN mix local.rebar --force
RUN mix do deps.get, deps.compile

# Same with npm deps
# ADD assets/package.json assets/
# RUN cd assets && \
#     npm install

ADD . .

# Run frontend build, compile, and digest assets
# RUN cd assets/ && \
#     npm run deploy && \
#     cd - && \
#     mix do compile, phx.digest

# USER default

CMD ["iex", "-S", "mix"]