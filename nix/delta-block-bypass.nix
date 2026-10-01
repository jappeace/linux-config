# Delta Fiber blocks thepiratebay.org twice: its resolvers answer with
# blocked.delta.nl, and it blackholes the real Cloudflare IPs (v4 and v6).
# Cloudflare picks the site by SNI, so an unblocked edge IP serves it fine.
{
  # Decision: pin an unblocked Cloudflare edge IP in /etc/hosts. Public DNS
  # only returns the blackholed IPs; a VPN or SOCKS hop works too but routes
  # through an extra server. Measured 2026-10-01: 104.17.0.1 serves the zone,
  # 104.16.123.96 refuses it (Cloudflare error 1034). If this breaks, try
  # another address from https://www.cloudflare.com/ips/.
  networking.hosts."104.17.0.1" = [ "thepiratebay.org" ];
}
