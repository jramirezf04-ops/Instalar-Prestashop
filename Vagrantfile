Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-22.04"
  config.vm.box_check_update = false
  config.vm.hostname = "JavierRamirezPrestashop"
  config.vm.boot_timeout = 600

  config.vm.network "forwarded_port", guest: 80, host: 8080, auto_correct: true
  config.vm.network "forwarded_port", guest: 443, host: 8443, auto_correct: true

  config.vm.provider "virtualbox" do |vb|
    vb.name = "JavierRamirezPrestashop"
    vb.memory = "2048"
    vb.cpus = 2
    vb.customize ["modifyvm", :id, "--cableconnected1", "on"]
  end
end