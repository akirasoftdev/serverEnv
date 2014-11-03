exec {'disabled-selinux':
	command => "sed -i 's/enforcing/disabled/' /etc/sysconfig/selinux",
	logoutput => true,
	path => '/bin/'
}

exec {'accept-http-port':
	command => 'iptables -A INPUT -m state --state NEW -m tcp -p tcp --dport 80 -j ACCEPT',
	logoutput => true,
	path => ['/sbin/','/bin/'],
	unless => "iptables --list INPUT -n | egrep '80'",
} ->

exec {'save-iptables':
	command => 'iptables-save',
	logoutput => true,
	path => '/sbin/',
} ->

package {"epel-release":
	provider=>rpm,
	ensure=>installed,
	source=>"http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm"
} ->

exec {'install-development-tools':
	command => 'yum -y groupinstall "Development Tools"',
	logoutput => true,
	timeout => 0,
	path => '/usr/bin/',
} ->

package {'openssl-devel': ensure => installed} ->
package {'readline-devel': ensure => installed} ->
package {'zlib-devel': ensure => installed} ->
package {'libcurl-devel': ensure => installed} ->
package {'libyaml-devel': ensure => installed} ->

package {'mysql-server': ensure => installed} ->
package {'mysql-devel': ensure => installed} ->

package {'ImageMagick': ensure => installed} ->
package {'ImageMagick-devel': ensure => installed} ->
package {'ipa-pgothic-fonts': ensure => installed} ->

exec {'download-ruby':
	command => 'curl -O http://cache.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p594.tar.bz2',
	cwd => '/opt/',
	timeout => 0,
	path => '/usr/bin/',
	unless => 'test -e /opt/ruby-2.0.0-p594.tar.bz2',
} ->

exec {'extract-ruby-tar-gz':
	command => 'tar zxvf ruby-2.0.0-p594.tar.bz2',
	cwd => '/opt/',
	path => ['/usr/bin','/bin/'],
	unless => 'test -d /opt/ruby-2.0.0-p594/',
} ->

exec {'configure-ruby-tar-gz':
	command => '/bin/sh -c ./configure --disable-install-doc',
	cwd => '/opt/ruby-2.0.0-p594/',
} ->

exec {'make-ruby':
	command => 'make',
	cwd => '/opt/ruby-2.0.0-p594/',
	timeout => 0,
	path => ['/bin/','/usr/bin/'],
	unless => 'which ruby',
} ->

exec {'install-ruby':
	command => 'make install',
	cwd => '/opt/ruby-2.0.0-p594/',
	path => ['/bin/', '/usr/bin/'],
	unless => 'which ruby',
} ->

#exec {'install-gem-source':
#	command => 'gem source --add https://rubygems.org',
#	path => '/usr/bin',
#	timeout => 0,
#} ->

exec {'install-bundler':
	command => 'gem install bundler --no-rdoc --no-ri',
	path => '/usr/bin/',
	timeout => 0,
} ->

exec {'insert-char-set-server-for-mysql':
	command => "sed -i '/\[mysqld\]/a\character-set-server=utf8' /etc/my.cnf",
	logoutput => true,
	path => '/bin/',
	unless => "grep character-set-server /etc/my.cnf",
} ->

exec {'insert-default-char-set':
	command => "echo '\n[mysql]\ndefault-character-set=utf8' >> /etc/my.cnf",
	logoutput => true,
	path => '/bin/',
	unless => "grep default-character-set /etc/my.cnf",
} ->

service {'mysqld':
	ensure => running,
	enable => true,
	hasrestart => true,
	hasstatus => true,
} ->

exec { "mysql-autosecure":
	command => "sh /vagrant/files/mysql-autosecure.sh changeme",
	path => "/usr/bin:/bin/",
	creates => "/usr/bin/mysql_sequre_installation.ran",
	logoutput => true,
}
