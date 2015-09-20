# Generated by Otto, do not edit!
#
# This is the Vagrantfile generated by Otto for the development of
# this application/service. It should not be hand-edited. To modify the
# Vagrantfile, use the Appfile.

Vagrant.configure("2") do |config|
  config.vm.box = "hashicorp/precise64"

  # Host only network
  config.vm.network "private_network", ip: "{{ dev_ip_address }}"

  # Setup a synced folder from our working directory to /vagrant
  config.vm.synced_folder "{{ path.working }}", "/vagrant",
    owner: "vagrant", group: "vagrant"

  # Enable SSH agent forwarding so getting private dependencies works
  config.ssh.forward_agent = true

  # Foundation configuration (if any)
  {% for dir in foundation_dirs.dev %}
  dir = "/otto/foundation-{{ forloop.Counter }}"
  config.vm.synced_folder "{{ dir }}", dir
  config.vm.provision "shell", inline: "cd #{dir} && bash #{dir}/main.sh"
  {% endfor %}

  # Load all our fragments here for any dependencies.
  {% for fragment in dev_fragments %}
  {{ fragment|read }}
  {% endfor %}

  # Install build environment
  config.vm.provision "shell", inline: $script_app
end

$script_app = <<SCRIPT
set -e

# otto-exec: execute command with output logged but not displayed
oe() { $@ 2>&1 | logger -t otto > /dev/null; }

# otto-log: output a prefixed message
ol() { echo "[otto] $@"; }

# Make it so that `vagrant ssh` goes directly to the correct dir
echo "cd /vagrant" >> /home/vagrant/.bashrc

# Configuring SSH for faster login
if ! grep "UseDNS no" /etc/ssh/sshd_config >/dev/null; then
  echo "UseDNS no" | sudo tee -a /etc/ssh/sshd_config >/dev/null
  oe sudo service ssh restart
fi

export DEBIAN_FRONTEND=noninteractive
oe sudo apt-get update -y

ol "Downloading Node {{ dev_node_version }}..."
oe wget -q -O /home/vagrant/node.tar.gz https://nodejs.org/dist/v{{ dev_node_version }}/node-v{{ dev_node_version }}-linux-x64.tar.gz

ol "Untarring Node..."
oe sudo tar -C /opt -xzf /home/vagrant/node.tar.gz

ol "Setting up PATH..."
oe sudo ln -s /opt/node-v{{ dev_node_version }}-linux-x64/bin/node /usr/local/bin/node
oe sudo ln -s /opt/node-v{{ dev_node_version }}-linux-x64/bin/npm /usr/local/bin/npm

ol "Installing build-essential for native packages..."
oe sudo apt-get install -y build-essential

ol "Installing GCC/G++ 0.8 (required for newer Node versions)..."
oe sudo apt-get install -y python-software-properties software-properties-common
oe sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
oe sudo apt-get update -y
oe sudo update-alternatives --remove-all gcc
oe sudo update-alternatives --remove-all g++
oe sudo apt-get install -y gcc-4.8
oe sudo apt-get install -y g++-4.8
oe sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.8 20
oe sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.8 20
oe sudo update-alternatives --config gcc
oe sudo update-alternatives --config g++

SCRIPT
