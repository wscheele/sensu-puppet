module Puppet::Parser::Functions
  newfunction(:latest_sensu_msi_url, :type => :rvalue) do
    Puppet::Parser::Functions.function(:latest_sensu_msi_version)
    latest_version = function_latest_sensu_msi_version([])
    "http://repos.sensuapp.org/msi/sensu-#{latest_version}.msi"
  end
end
