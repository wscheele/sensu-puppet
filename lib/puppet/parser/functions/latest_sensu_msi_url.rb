module Puppet::Parser::Functions
  newfunction(:latest_sensu_msi_version) do
    require 'net/http'
    require 'rexml/document'

    # Web check available sensu versions
    url = 'http://repos.sensuapp.org/'

    # get the XML data as a string
    xml_data = Net::HTTP.get_response(URI.parse(url)).body

    # extract version information
    doc = REXML::Document.new(xml_data)
    versions = []
    doc.elements.each('ListBucketResult/Contents/Key') do |ele|
      versions << ele.text.gsub(/msi\/sensu-(.*).msi/, '\1') if ele.text =~ /\.msi$/
    end

    # splits version number (x.y.z-n) into its int components and calculates 10^12*x + 10^8*y + 10^4*z + n
    # in order to allow for easy sorting of version numbers
    def ordered_version_hash(version)
      version.split(/[\.-]/).map { |x| x.to_i }.zip([10e12, 10e8, 10e4, 1]).map{|i, j| i * j }.inject(:+)
    end

    versions.sort {|x, y|
      ordered_version_hash(x) <=> ordered_version_hash(y)
    }[-1]
  end
  newfunction(:latest_sensu_msi_url) do
    url = 'http://repos.sensuapp.org/'
    Puppet::Parser::Functions.function('latest_sensu_msi_version')
    latest_version = function_latest_sensu_msi_version()
    "#{url}/msi/sensu-#{latest_version}.msi"
  end
end
