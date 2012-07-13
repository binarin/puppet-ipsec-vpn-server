define ipsec_vpn_server($psk, $serverIp, $ipRange) {
  $packages = [ "ipsec-tools", "racoon", "xl2tpd" ]
  package { $packages: ensure => latest }
  firewall::rule { "l2tp-ike":
    rule => "/sbin/iptables -A INPUT -p udp --dport 500 -j ACCEPT"
  }
  firewall::rule { "l2tp-nat-t":
    rule => "/sbin/iptables -A INPUT -p udp --dport 4500 -j ACCEPT"
  }
  firewall::rule { "l2tp-traffic":
    rule => "/sbin/iptables -A INPUT -p udp --dport 1701 -j ACCEPT"
  }
  file { "/etc/ipsec-tools.conf":
    ensure => present,
    mode => 0644,
    owner => root,
    group => root,
    source => 'puppet:///modules/ipsec_vpn_server/setkey.conf',
    notify => Exec['/etc/init.d/setkey start'],
    require => Package[$packages],
  }
  exec { "/etc/init.d/setkey start":
    refreshonly => true,
    path => [ "/sbin", "/bin", "/usr/sbin", "/usr/bin" ],
    subscribe => File["/etc/ipsec-tools.conf"],
    require => Package[$packages],
  }
  service { "racoon":
    ensure => running,
    require => Package[$packages],
  }
  service { "xl2tpd":
    ensure => running,
    hasstatus => false,
    require => Package[$packages],
    restart => "/etc/init.d/xl2tpd restart"
  }
  file { "/etc/racoon/racoon.conf":
    ensure => present,
    mode => 0600,
    owner => root,
    group => root,
    source => 'puppet:///modules/ipsec_vpn_server/racoon.conf',
    notify => Service['racoon'],
    require => Package[$packages],
  }
  file { "/etc/racoon/psk.txt":
    ensure => present,
    mode => 0600,
    owner => root,
    group => root,
    content => "$title $psk",
    require => Package[$packages],
  }
  file { "/etc/xl2tpd/xl2tpd.conf":
    ensure => present,
    mode => 0644,
    owner => root,
    group => root,
    content => template('ipsec_vpn_server/xl2tpd.conf.erb'),
    require => Package[$packages],
    notify => Service['xl2tpd'],
  }
  file { "/etc/ppp/options.xl2tpd":
    ensure => present,
    mode => 0644,
    owner => root,
    group => root,
    source => 'puppet:///modules/ipsec_vpn_server/options.xl2tpd',
    require => Package[$packages],
    notify => Service['xl2tpd'],
  }
  concat { "/etc/ppp/chap-secrets":
    owner => root,
    group => root,
    mode => 0600,
    require => Package[$packages],
  }
}
