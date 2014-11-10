$username = 'vagrant'
$ruby = '2.0.0-p594'
$redmine = '2.5.3'
$rubypath = "/home/${username}/.rbenv/versions/${ruby}/bin/"
$gemrubypath = "/home/${username}/.gem/ruby/2.0.0/bin/"
$appendpath = "/home/${username}/.rbenv/shmis:$gemrubypath:$rubypath"

exec {'accept http':
	command => 'iptables-save | sed "/dport\s22\s/a -A INPUT -p tcp -m state --state NEW -m tcp --dport 80 -j ACCEPT" > /etc/sysconfig/iptables',
	logoutput => true,
	path => ['/sbin/','/bin/'],
	unless => "iptables --list INPUT -n | egrep '80'",
} ->

exec {'reload ipconfigs':
	command => 'service iptables reload',
	logoutput => true,
	path => "/sbin/",
	timeout => 0,
} ->

package {"epel-release":
	provider=>rpm,
	ensure=>installed,
	source=>"http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm"
} ->

exec {'install development tools':
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

package {'httpd': ensure => installed} ->
package {'httpd-devel': ensure => installed} ->

package {'ImageMagick': ensure => installed} ->
package {'ImageMagick-devel': ensure => installed} ->
package {'ipa-pgothic-fonts': ensure => installed} ->

package {'expect': ensure => installed} ->

rbenv::install {"${username}":} ->
rbenv::compile {"${username}":
	user => "${username}",
	ruby => "${ruby}",
	global => true,
} ->

exec {'insert char-set-server for mysql':
	command => "sed -i '/\[mysqld\]/a\character-set-server=utf8' /etc/my.cnf",
	logoutput => true,
	path => '/bin/',
	unless => "grep character-set-server /etc/my.cnf",
} ->

exec {'insert default-char-set for mysql':
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

exec { "exec mysql-autosecure":
	command => 'bash -c "/vagrant/files/mysql-autosecure.sh changeme"',
	path => "/usr/bin:/bin/",
	creates => "/usr/bin/mysql_sequre_installation.ran",
	logoutput => true,
	provider => 'shell',
} ->

exec { "create redmine database":
	command => 'bash -c "/vagrant/files/mysql-redmine.sh changeme"',
	path => "/usr/bin:/bin/",
	logoutput => true,
	provider => 'shell',
} ->

archive { "redmine-${redmine}":
	ensure => present,
	url => "http://www.redmine.org/releases/redmine-${redmine}.tar.gz",
	target => "/opt",
} ->

exec {'move redmine-dir':
	command => "mv redmine-${redmine} /var/lib/redmine",
	cwd => '/opt/',
	path => ['/usr/bin','/bin/'],
	unless => 'test -d /var/lib/redmine/',
} ->

file {'/var/lib/redmine/config/database.yml':
	source => '/vagrant/files/database.yml',
} ->

file {'/var/lib/redmine/config/configuration.yml':
	source => '/vagrant/files/configuration.yml',
} ->

exec {'install gem-packages':
	command => "bundle install --without development test",
	logoutput => true,
	cwd => '/var/lib/redmine/',
	path => "${appendpath}:/usr/bin:/bin/",
	timeout => 0,
} ->

exec {'init redmine':
	command => 'bundle exec rake generate_secret_token',
	logoutput => true,
	cwd => '/var/lib/redmine/',
	path => "${appendpath}:/usr/bin:/bin/",
	timeout => 0,
} ->

exec {'exec migration':
	command => 'bundle exec rake db:migrate',
	logoutput => true,
	cwd => '/var/lib/redmine/',
	environment => 'RAILS_ENV=production',
	path => "${appendpath}:/usr/bin:/bin/",
	timeout => 0,
} ->

exec {'install passenger':
	command => 'gem install passenger --no-rdoc --no-ri',
	logoutput => true,
	path => "${appendpath}:/usr/bin:/bin/",
	timeout => 0,
} ->

exec {'install apach2':
	command => 'passenger-install-apache2-module',
	logoutput => true,
	path => "${appendpath}:/usr/bin:/bin/",
	timeout => 0,
} ->

exec {'/etc/httpd/conf.d/passenger.conf':
	command => "passenger-install-apache2-module --snippet > /etc/httpd/conf.d/passenger.conf",
	logoutput => true,
	path => "${appendpath}:/usr/bin:/bin/",
	timeout => 0,
} ->

exec {'append-passenger.conf':
	command => "cat /vagrant/files/passenger.conf >> /etc/httpd/conf.d/passenger.conf",
	logoutput => true,
	path => "${appendpath}:/usr/bin:/bin/",
	timeout => 0,
} ->

service {'httpd':
	ensure => running,
	enable => true,
	hasrestart => true,
	hasstatus => true,
} ->

exec {'change-own-/var/lib/redmine':
	command => 'chown -R apache:apache /var/lib/redmine',
	logoutput => true,
	path => "${appendpath}:/usr/bin:/bin/",
	timeout => 0,
} ->

file {'/var/www/html/redmine':
	ensure => link,
	target => '/var/lib/redmine/public',
} ->

exec {'append redmineUri':
	command => "echo '\nRackBaseURI /redmine' >> /etc/httpd/conf.d/passenger.conf",
	logoutput => true,
	path => "${appendpath}:/usr/bin:/bin/",
	timeout => 0,
} ->

exec {'grant execute to vagrant home':
	command => "chmod +x /home/vagrant",
	logoutput => true,
	path => '/bin',
} ->

exec {'restart httpd':
	command => 'service httpd restart',
	logoutput => true,
	path => "${appendpath}:/usr/bin:/bin/:/sbin/",
	timeout => 0,
}
