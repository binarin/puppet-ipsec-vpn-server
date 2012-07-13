define ipsec_vpn_server::user($password) {
  concat::fragment { "ipsec_vpn_server_$title":
    target => "/etc/ppp/chap-secrets",
    content => "$title * $password *"
  }
}
