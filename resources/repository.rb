actions :fetch, :nothing

default_action :fetch

attribute :name, :kind_of => String, :name_attribute => true
attribute :path, :kind_of => String, :required => true
attribute :username, :kind_of => String, :required => true
attribute :password, :kind_of => String, :required => true
