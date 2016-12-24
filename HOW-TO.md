##I Have No Idea What I'm Doing.


####Step 1: Start.

Make a directory: `mkdir ubuntu1604-mongodb` and `cd ubuntu1604-mongodb`
(Optional) We're going to want to use git. `git init`

####Step 2: Vagrant init
type `vagrant init`

Now we have a default `Vagrantfile` with all kinds of stuff we don't need! 

####Step 3: Configre Vagrantfile
We want the current ubuntu LTS with puppet installed.
    
    config.vm.box = "puppetlabs/ubuntu-16.04-64-puppet"

Forward the mongodb server's port
    
    config.vm.network "forwarded_port", guest: 27017, host: 27017

This sets the VM's IP address or something? IDK.
    
    config.vm.network "private_network", ip: "10.11.12.13"

Set some reasonable defaults for the virtualbox vm
    
    config.vm.provider "virtualbox" do |vb|
        # Display the VirtualBox GUI when booting the machine
        #vb.gui = true
    
        vb.memory = "1024"
        vb.cpus = 1

        vb.name = "ububtu1604-mongodb"

        # Intercept DNS requests and use the host's resolvers.
        vb.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
    end

We can now `vagrant up` and get a box that does...nothing!

####Step 4: Provisioning
We're going to use puppet - for two reasons, because I have no idea what I'm doing w/r/t configuring anything, and the broken examples I'm basing this on used it.

Apparently Puppet 4 broke all the existing vagrant examples, and now you have to use environments?! I don't know quite what that means, but it seems to require the following:

Make the following directories:
    environments/test/manifests
    environments/test/modules

and create an empty file in `environments/test/environment.conf`...because reasons.

Next, we have to create the 'manifest', which tells puppet what we want it to do. I think it's some sort of ruby DSL, but that doesn't really matter right now.

The convention seems to be to name these after the hostname of the machine, with a `.pp` extension. So, we'll create the following file at `environments/test/manifests/ubuntumongo.pp` which will instruct puppet to do exactly nothing with our vagrant box.

    node 'ubuntumongo' {

    }

...and it still all works (you can `vagrant reload --provision` or `vagrant destroy` and then `vagrant up` again) and still does nothing. Progress!

I didn't document the next bit well, but after a lot of trying random things until I got less errors, I determined the following:

We need to check out specific versions of the following modules:

*  puppetlabs-mongodb tags/0.16.0
*  puppetlabs-apt tags/2.3.0
*  puppetlabs-stdlib tags/4.12.0
 
Also, ubuntu 16.04 LTS fails to configure mongodb for systemd related reasons, and instead of trying to understand that, I determined that 14.04 works just fine, so in `Vagrantfile` we change the box like so:

    config.vm.box = "puppetlabs/ubuntu-14.04-64-puppet"

Also change the hostname in the virtualbox setup block

    config.vm.provider "virtualbox" do |vb|
        ...
        vb.name = "ububtu1404-mongodb"
        ...
    end

and I ended up with a `environments/test/manifests/ubuntumongo.pp` file that looks like this:
    
    node 'ubuntumongo' {
        #Puppet changed their gpg signing key and now you have to do this?
        # see: https://puppet.com/blog/updated-puppet-gpg-signing-key
        apt::key { 'puppet gpg key':
            id     => '6F6B15509CF8E59E6E469F327F438280EF8D349F',
            server => 'pgp.mit.edu',
        }

        #ensure apt-get update runs frequently
        class { 'apt':
            update => {
                frequency => 'daily',
            },
        }

        #Install the latest mongodb from the 10gen repo
        class {'::mongodb::globals':
            manage_package_repo => true,
            server_package_name => 'mongodb-org'
        }->
        class {'::mongodb::client': } ->
        class {'::mongodb::server': }
    }

####Step 5: Does it work?
I mean, it provisions without errors, and I can ssh in and `mongo --version` tells me that I'm running 2.6.12, but now what?

Connecting to mogodb:
