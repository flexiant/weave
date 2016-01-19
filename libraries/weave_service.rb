module WeaveCookbook
  class WeaveService < ChefCompat::Resource
    use_automatic_resource_name
    provides :weave_service

    require 'helper_weave'
    include WeaveHelpers

    Boolean = property_type(
      is: [true, false],
      default: false
    ) unless defined?(Boolean)



    property :docker_hook, Boolean, default: false
    property :version, String, default: lazy { default_version }, desired_state: false
    property :source, String, default: lazy { default_source }, desired_state: false
    property :is_master, Boolean, default: false
    property :ip_alloc_range, default: nil
    property :subnet, default: lazy { default_subnet }
    property :master, String, default: nil
    property :ip, String, default: nil
    property :password, String, default: nil


    action :create do
      action_install
      action_docker_hook
      action_setup
    end


    action :install do
      directory weave_etc_prefix do
        owner 'root'
        group 'root'
        mode '0755'
        recursive true
        action :create
      end

      directory weave_bin_prefix do
        owner 'root'
        group 'root'
        mode '0755'
        recursive true
        action :create
      end

      remote_file weave_cmd do
        path weave_cmd
        source new_resource.source
        owner 'root'
        group 'root'
        mode '0755'
        action :create
        not_if { weave_cmd_exists? }
      end
    end


    action :restart do
      action_stop
      action_start
    end

    action :start do
      service 'weave' do
        provider Chef::Provider::Service::Systemd
        supports status: true
        action [:enable, :start]
        only_if { ::File.exist?('/etc/systemd/system/weave.service') }
      end
    end

    action :stop do
      service 'weave' do
        provider Chef::Provider::Service::Systemd
        supports status: true
        action [:stop]
        only_if { ::File.exist?('/etc/systemd/system/weave.service') }
      end
    end

    action :docker_hook do
      if new_resource.docker_hook and new_resource.ip
        log "Weave bridge ip #{new_resource.ip}"
        package ["bridge-utils","inotify-tools", "linux-image-extra-#{node['kernel']['release']}", "vim"]


        cookbook_file "/tmp/nsenter_2.24.deb" do
          source "nsenter_2.24.deb"
          mode 644
          cookbook 'weave'
        end

        dpkg_package "nsenter" do
          source "/tmp/nsenter_2.24.deb"
          action :install
        end

        file "#{weave_etc_prefix}/default.ip.cidr" do
          content ip
          mode '0644'
        end

        template "/etc/network/interfaces.d/weave.cfg" do
          mode '0644'
          source "etc/network/interfaces.d/weave.cfg.erb"
          variables(
            :cidr => ip
          )
          cookbook 'weave'
        end

        template "/etc/network/interfaces.d/docker.cfg" do
          mode '0644'
          source "etc/network/interfaces.d/docker.cfg.erb"
          cookbook 'weave'
        end

        bash "Creating temporary Docker bridge" do
          user 'root'
          cwd '/tmp'
          code <<-EOH
          if [ -z "$(brctl show | grep docker0)" ]; then
            brctl addbr docker0
            fi
            ip addr add 172.17.42.1/24 dev docker0
            ip link set dev docker0 up
            EOH
            not_if "ip addr show docker0 | grep 172.17.42"
          end

          docker_service 'install' do
            version '1.8.3'
            action :create
            not_if { ::File.exist?("/usr/bin/docker") }
          end

          bash "Creating temporary Weave bridge" do
            user 'root'
            cwd '/tmp'
            code <<-EOH
            WEAVE_NO_FASTDP=1 /usr/local/bin/weave --local create-bridge
            ip addr add dev weave #{ip}
            EOH
            not_if "ip link show weave | grep UP"
          end

          execute "Allowing for intefaces.d to work correctly in Ubuntu" do
            command "echo 'source /etc/network/interfaces.d/*.cfg' >> /etc/network/interfaces"
            not_if "grep source /etc/network/interfaces "
          end

          log "Docker in subnet #{new_resource.subnet}"

          docker_service 'weave' do
            fixed_cidr new_resource.subnet
            storage_driver 'overlay'
            bridge 'weave' if new_resource.docker_hook
            insecure_registry node["docker"]["insecure-registry"] if lazy { node["docker"]["insecure-registry"] }
            host node["docker"]["host"] if lazy { node["docker"]["host"] }
            tls node["docker"]["tls"] if lazy { node["docker"]["tls"] }
            tls_verify node["docker"]["tlsverify"] if lazy { node["docker"]["tlsverify"] }
            tls_ca_cert node["docker"]["tlscacert"] if lazy { ::File.exists?(node["docker"]["tlscacert"].to_s) }
            tls_server_cert node["docker"]["tlscert"] if lazy { ::File.exists?(node["docker"]["tlscert"].to_s) }
            tls_server_key node["docker"]["tlskey"] if lazy { ::File.exists?(node["docker"]["tlskey"].to_s) }
            version '1.8.2'
            action [:create, :start]
          end
        end
      end

      action :setup do
        execute "/usr/local/bin/weave setup" do
          not_if {"docker inspect -f {{.State.Running}} weave"}
        end


        parameters = String.new
        parameters += "  --password #{new_resource.password}" if new_resource.password
        parameters += "  --ipalloc-range #{new_resource.ip_alloc_range}" if new_resource.ip_alloc_range
        parameters += "  #{new_resource.master}" unless new_resource.is_master


        template '/etc/systemd/system/weave.service' do
          source 'etc/systemd/system/weave.service.erb'
          owner 'root'
          group 'root'
          variables(
            :parameters => parameters
          )
          notifies :run, 'execute[systemctl daemon-reload]', :immediately
          mode '0644'
          cookbook 'weave'
        end


        execute 'systemctl daemon-reload' do
          command '/bin/systemctl daemon-reload'
          action :nothing
        end
      end
    end
  end
