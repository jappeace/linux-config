# Delta Fiber blocks thepiratebay.org twice: its resolvers answer with
# blocked.delta.nl, and it blackholes the real Cloudflare IPs (v4 and v6).
# Cloudflare picks the site by SNI, so an unblocked edge IP serves it fine.
{
  # Decision: pin an unblocked Cloudflare edge IP; public DNS only yields the
  # blackholed ones, and a VPN adds a hop. 104.17.0.1 served the zone on
  # 2026-10-01; if it breaks, try another from https://www.cloudflare.com/ips/.
  networking.hosts."104.17.0.1" = [ "thepiratebay.org" ];
}
