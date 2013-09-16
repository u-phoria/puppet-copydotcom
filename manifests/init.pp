class copydotcom (
	$uid = undef,
	$gid = undef,
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

	exec { 'download-client':
		command => "wget -O /tmp/${installer} ${download_url}",
		unless => "test -f /tmp/${installer}",
	}

	exec { 'install-copydotcom':
		command => "tar -C ${install_dir} -zxvf /tmp/${installer}",
		unless => "test -d ${install_dir}/copy",
		require => Exec['download-client'],
	}

	file { "${install_dir}/copy":
		owner => "${uid}",
		group => "${gid}",
		alias => 'change-tarball-owner',
		subscribe => Exec['install-copydotcom'],
		ensure => 'directory',
		recurse => true,
	}

	file { '/etc/init.d/copyconsole':
		require=> File['change-tarball-owner'],
		content=> template('copydotcom/copyconsole.erb'),
		owner  => root,
		group  => root,
		mode   => 755,
	}
}