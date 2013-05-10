begin
  require 'net/https'
rescue
end


def initialize(*args)
  super
end

action :fetch do
  location = URI.parse(new_resource.path)
  writeOut = open("#{Chef::Config[:file_cache_path]}/#{new_resource.name}", "wb")
  http = Net::HTTP.new(location.host, location.port)
  if location.scheme =~ /https/ then
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  end
  req = Net::HTTP::Get.new("#{location.path}/#{new_resource.name}")
  req.basic_auth new_resource.username, new_resource.password
  response = http.request(req)
  writeOut.print(response.body)
  writeOut.close
end

action :nothing do
end
