import Config

config :bolt_sips, Bolt,
  url: "bolt://localhost:7687",
  basic_auth: [username: "neo4j", password: "password"],
  pool_size: 5

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :urban_way, UrbanWayWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "lKu+mmRESCfCTytOrGbmcMwcWktNfMuSpa4BJuZjKwr4wUJnxsyqaOsiFTCQSDn0",
  server: false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Sort query params output of verified routes for robust url comparisons
config :phoenix,
  sort_verified_routes_query_params: true
