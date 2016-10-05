require "kemal"
require "pg"
require "json"

CATALOG = JSON.parse(File.read("catalog.json"))
DATABASE_URL = "postgres://#{ENV["PG_USERNAME"]}:#{ENV["PG_PASSWORD"]}@#{ENV["PG_HOST"]}/postgres"
DB = PG.connect(DATABASE_URL)


Kemal.config.add_handler Kemal::Middleware::HTTPBasicAuth.new(ENV["USERNAME"], ENV["PASSWORD"])
before_all do |env|
  env.response.content_type = "application/json"
end

get "/v2/catalog" do |env|
  host = env.request.headers["Host"] || "unknown"
  space = host.match(/whale-db-([^\.]+)\./).try { |x| x[1] } || ""
  CATALOG.tap do |catalog|
    catalog["services"].each do |service|
      service.as_h["id"] = Crypto::MD5.hex_digest("#{host}:service")
      service.as_h["name"] = "WhaleDB#{space}"
      service["plans"].each do |plan|
        plan.as_h["id"] = Crypto::MD5.hex_digest("#{host}:plan")
      end
    end
  end.to_json
end

put "/v2/service_instances/:name" do |env|
  name = env.params.url["name"]
  name = "db" + Crypto::MD5.hex_digest(name)
  # { "a" => "postgres://#{ENV["PG_USERNAME"]}:#{ENV["PG_PASSWORD"]}@#{ENV["PG_HOST"]}:5432/postgres", "name" => name }.to_json

  begin
    DB.exec("CREATE USER #{name} WITH PASSWORD '#{name}'")
    DB.exec("CREATE DATABASE #{name}")
    DB.exec("GRANT ALL PRIVILEGES ON DATABASE #{name} TO #{name}")
    env.response.status_code = 201
    {"dashboard_url" => "postgres://#{name}:#{name}@#{ENV["PG_HOST"]}:5432/#{name}"}.to_json
  rescue e
    env.response.status_code = 502
    {"description" => e.message}.to_json
  end
end

put "/v2/service_instances/:name/service_bindings/:sbid" do |env|
  name = env.params.url["name"]
  name = "db" + Crypto::MD5.hex_digest(name)
  env.response.status_code = 201
  {"credentials" => { "uri" => "postgres://#{name}:#{name}@#{ENV["PG_HOST"]}:5432/#{name}"}}.to_json
end

delete "/v2/service_instances/:name/service_bindings/:sbid" do |env|
  env.response.status_code = 200
  "{}"
end

delete "/v2/service_instances/:name" do |env|
  name = env.params.url["name"]
  name = "db" + Crypto::MD5.hex_digest(name)

  begin
    DB.exec("SELECT pg_terminate_backend(pg_stat_activity.pid) FROM pg_stat_activity WHERE pg_stat_activity.datname='#{name}'")
    DB.exec("DROP DATABASE #{name}")
    DB.exec("DROP USER #{name}")
    env.response.status_code = 200
    "{}"
  rescue e
    env.response.status_code = 502
    {"description" => e.message}.to_json
  end
end


Kemal.run
