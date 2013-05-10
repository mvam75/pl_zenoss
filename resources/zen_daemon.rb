actions :start, :stop, :restart, :status

#default_action :status

#attribute :service_name, :name_attribute => true
attribute :name, :kind_of => String
attribute :enabled, :default => true
attribute :running, :default => false
attribute :variables, :kind_of => Hash
attribute :supports, :default => { :restart => true, :status => true }
