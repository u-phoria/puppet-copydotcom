class copydotcom (
	$uid = undef,
	$gid = undef,
	$username = undef,
	$password = undef,
	$copy_dir = '/root/copy',
	$installer = 'Copy.tgz',
	$download_url = 'https://copy.com/install/linux/Copy.tgz',
	$install_dir = '/opt') {

	Exec {
		path   => '/bin:/sbin:/usr/bin:/usr/sbin',
	}

  $target_arch = $::architecture ? {
	  'i386'   => 'x86',
	  'x86_64' => 'x86_64',
	  'amd64'  => 'x86_64',
  }	

  #notify{"The value is: ${install_dir}": }

	exec { 'download-client':
		command => "wget -O /tmp/${installer} ${download_url}",
		unless => "test -f /tmp/${installer}",
	}

	exec { 'install-copydotcom':
		command => "tar -C ${install_dir} -zxvf /tmp/${installer}",
		unless => "test -d ${install_dir}/copy",
		subscribe => Exec['download-client'],
	}

	file { "${install_dir}/copy":
		owner => "${uid}",
		group => "${gid}",
		alias => 'change-tarball-owner',
		subscribe => Exec['install-copydotcom'],
		ensure => 'directory',
		recurse => true,
	}
	
	exec { 'copydotcom-login':
    command => "echo | ${install_dir}/copy/$target_arch/CopyConsole -u='$username' -r='$copy_dir' -p='$password'",
    require => File['change-tarball-owner'],
    subscribe => Exec['install-copydotcom'],
  }

	file { '/etc/init.d/copyconsole':
		require=> File['change-tarball-owner'],
		content=> template('copydotcom/copyconsole.erb'),
		owner  => root,
		group  => root,
		mode   => 755,
	}
	
	service { 'copyconsole':
    enable => true,
    ensure => running,
    subscribe => Exec['copydotcom-login'],
  }
}