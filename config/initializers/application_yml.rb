require "erb"
require "yaml"

application_yml_path = Rails.root.join("config", "application.yml")

if application_yml_path.exist?
  raw_config = ERB.new(application_yml_path.read).result
  parsed_config = YAML.safe_load(raw_config, aliases: true) || {}

  env_config = parsed_config.fetch(Rails.env, {})
  default_config = parsed_config.fetch("default", {})

  default_config.merge(env_config).each do |key, value|
    ENV[key.to_s] = value.to_s if value.present? && ENV[key.to_s].blank?
  end
end
