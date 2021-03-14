Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu/focal64"
  config.vm.provision :shell, :privileged => false, :path => "scripts/install-bcc.sh"
  config.vm.synced_folder ".", "/home/vagrant/src"
end