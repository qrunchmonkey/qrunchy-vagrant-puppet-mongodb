
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
    }->
    class {'::mongodb::client': } ->
    class {'::mongodb::server':
        port    => 27017,
        bind_ip => ['0.0.0.0'],
        service_enable => true
    }

    mongodb::db { 'testdb':
        user     => 'user1',
        password => 'pass1'
    }

}

