require "kemal"
require "pg"
require "yaml"
require "json"

CONFIG = JSON.parse(File.read("settings.json"))
Kemal.config.add_handler Kemal::Middleware::HTTPBasicAuth.new("admin", "password")
before_all do |env|
  puts "Setting response content type"
  env.response.content_type = "application/json"
end

get "/v2/catalog" do |env|
  CONFIG["catalog"].to_json
end

put "/v2/service_instances/:name" do |env|
  name = env.params.url["name"]
  name = "db" + Crypto::MD5.hex_digest(name)

  begin
    c = CONFIG["pg"]
    db = PG.connect("postgres://#{c["user"]:c["password"]@c["host"]:c["port"]/c["dbname"]")

    db.exec("CREATE USER #{name} WITH PASSWORD '#{name}'")
    db.exec("CREATE DATABASE #{name}")
    db.exec("GRANT ALL PRIVILEGES ON DATABASE #{name} TO #{name}")
    env.response.status_code = 201
    {"dashboard_url" => "postgres://#{name}:#{name}@c["host"]:c["port"]/#{name}"}.to_json
  rescue e
    env.response.status_code = 502
    {"description" => e.message}.to_json
  end
end

put "/v2/service_instances/:name/service_bindings/:sbid" do |env|
  name = env.params.url["name"]
  name = "db" + Crypto::MD5.hex_digest(name)
  env.response.status_code = 201
  {"credentials" => "postgres://#{name}:#{name}@67.205.131.159:5432/#{name}"}.to_json
end

delete "/v2/service_instances/:name/service_bindings/:sbid" do |env|
  "{}"
end

delete "/v2/service_instances/:name" do |env|
  name = env.params.url["name"]
  name = "db" + Crypto::MD5.hex_digest(name)

  begin
    c = CONFIG["pg"]
    db = PG.connect("postgres://#{c["user"]:c["password"]@c["host"]:c["port"]/c["dbname"]")

    db.exec("DROP DATABASE #{name}")
    db.exec("DROP USER #{name}")
    env.response.status_code = 201
    "{}"
  rescue e
    env.response.status_code = 502
    {"description" => e.message}.to_json
  end
end

Kemal.run
