# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "generic/ubuntu2204"
  config.vm.box_version = "4.2.10"

  config.vm.provider "libvirt" do |vb|
    vb.cpus = 999
    vb.memory = "102400"
    vb.machine_virtual_size = 256
  end

end
