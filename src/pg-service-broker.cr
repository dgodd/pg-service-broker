require "kemal"
require "pg"
require "json"

VCAP = JSON.parse(ENV["VCAP_APPLICATION"])
CATALOG = JSON.parse(File.read("catalog.json")).tap do |catalog|
  catalog["services"].each do |service|
    service.as_h["id"] = Crypto::MD5.hex_digest("#{VCAP["application_id"]}:service")
    service["plans"].each do |plan|
      plan.as_h["id"] = Crypto::MD5.hex_digest("#{VCAP["application_id"]}:plan")
    end
  end
end
DATABASE_URL = "postgres://#{ENV["PG_USERNAME"]}:#{ENV["PG_PASSWORD"]}@#{ENV["PG_HOST"]}/postgres"
DB = PG.connect(DATABASE_URL)


Kemal.config.add_handler Kemal::Middleware::HTTPBasicAuth.new(ENV["USERNAME"], ENV["PASSWORD"])
before_all do |env|
  env.response.content_type = "application/json"
end

get "/v2/catalog" do |env|
  CATALOG.to_json
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
  "{}"
end

delete "/v2/service_instances/:name" do |env|
  name = env.params.url["name"]
  name = "db" + Crypto::MD5.hex_digest(name)

  begin
    DB.exec("DROP DATABASE #{name}")
    DB.exec("DROP USER #{name}")
    env.response.status_code = 201
    "{}"
  rescue e
    env.response.status_code = 502
    {"description" => e.message}.to_json
  end
end


Kemal.run
