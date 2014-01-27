module Puppet::Parser::Functions
  newfunction(:latest_sensu_msi_url) do
    url = 'http://repos.sensuapp.org/'
    Puppet::Parser::Functions.function('latest_sensu_msi_version')
    latest_version = function_latest_sensu_msi_version()
    "#{url}/msi/sensu-#{latest_version}.msi"
  end
end
