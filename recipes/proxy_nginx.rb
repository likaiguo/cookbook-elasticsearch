# Create proxy with HTTP authentication via Nginx
#
template "#{node.elasticsearch[:nginx][:dir]}/conf.d/elasticsearch_proxy_nginx.conf" do
  source "elasticsearch_proxy_nginx.conf.erb"
  owner node.elasticsearch[:nginx][:user] and group node.elasticsearch[:nginx][:user] and mode 0755
  notifies :restart, resources(:service => "nginx")
end

# Try to load data bag item <https://manage.opscode.com/databags/elasticsearch/items/users>
#
users = data_bag_item('elasticsearch', 'users')['users'] rescue []

unless users.empty?

  ruby_block "add users to passwords file" do

    block do

      require 'webrick/httpauth/htpasswd'
      @htpasswd = WEBrick::HTTPAuth::Htpasswd.new(node.elasticsearch[:nginx][:passwords_file])

      users.each do |u|
        STDOUT.print "Adding user '#{u['username']}' to #{node.elasticsearch[:nginx][:passwords_file]}\n"
        @htpasswd.set_passwd( 'Elasticsearch', u['username'], u['password'] )
      end

      @htpasswd.flush

    end
  end

end

file node.elasticsearch[:nginx][:passwords_file] do
  owner node.elasticsearch[:nginx][:user] and group node.elasticsearch[:nginx][:user] and mode 0755
  action :touch
end
