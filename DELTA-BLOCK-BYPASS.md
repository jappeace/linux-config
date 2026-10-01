# Delta Fiber's Pirate Bay block

Why `thepiratebay.org` does not load on a Delta Fiber connection, how the
block is built, why it exists, and how `nix/delta-block-bypass.nix` gets
around it. All measurements were taken from a Delta Fiber line on
2026-10-01. Legal history comes from the sources at the bottom.

## Summary

Delta blocks The Pirate Bay (TPB) at two layers. Its DNS resolvers answer
with a block page, and its routers drop all traffic to TPB's real IP
addresses. Switching to a public DNS server only gets you past the first
layer. TPB sits behind Cloudflare, which picks the website by the name in
the request, not by the IP address the request arrives on. Pointing
`thepiratebay.org` at a different Cloudflare IP in `/etc/hosts` skips both
layers.

## How the block works

### Layer 1: DNS rewrite

Delta's resolvers (`62.45.46.46` is `ns3.kabelfoon.nl`, `62.45.71.116`,
both AS15435 DELTA Fiber Nederland) do not return TPB's address:

| Resolver                           | Answer for `thepiratebay.org`                |
|------------------------------------|----------------------------------------------|
| Delta `62.45.46.46`/`62.45.71.116` | `CNAME blocked.delta.nl`, `217.102.255.19`   |
| Cloudflare `1.1.1.1`               | `162.159.136.6`, `162.159.137.6`             |
| Quad9 `9.9.9.9`, Google `8.8.8.8`  | the same two Cloudflare addresses            |

`217.102.255.19` answers every request with a 302 to
`https://www.delta.nl/geblokkeerd/`. Delta does not intercept DNS traffic to
other resolvers: queries to `1.1.1.1` come back unmodified. The domain has
no DNSSEC (no DS record), so a client has no way to detect the forged answer.

### Layer 2: IP blackhole

With the correct address the connection still fails:

- TCP to `162.159.136.6` and `162.159.137.6` times out on ports 80 and 443,
  with or without the right SNI. The IPv6 addresses
  `2606:4700:7::a29f:8906` and `2606:4700:7::a29f:8806` time out too.
- A traceroute dies right after Delta's edge router `81.172.185.129`. A
  control trace to another Cloudflare address (`104.16.123.96`) continues
  through `62.45.63.215` into Cloudflare and arrives in about 5 ms.
- check-host.net reaches `162.159.136.6:443` within milliseconds from
  Germany, France, Israel, Iran, Slovenia and a Dutch hosting network. The
  address is up everywhere except on Delta.
- The blackhole covers more than TPB's two addresses. The neighbouring
  `162.159.137.1` also times out from Delta, but answers from Italy,
  Kazakhstan and Serbia. Whether BREIN's list includes it or Delta drops a
  wider prefix cannot be seen from outside. Either way, any other site that
  Cloudflare serves from those addresses is unreachable on Delta as well.

No packets come back at all, so this is routing (a null route or an ACL),
not content inspection. Delta never looks at the SNI.

## Why Delta blocks it

Delta is following a court order. Stichting BREIN, the Dutch anti-piracy
foundation funded by the film, music and games industries, has been
litigating against Dutch ISPs over TPB since 2010.

| When      | What happened                                                                                                                                                                                                                            |
|-----------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Jan 2012  | The Hague district court orders Ziggo and XS4ALL to block TPB.                                                                                                                                                                           |
| May 2012  | The same court gives UPC, KPN, Tele2, T-Mobile and Telfort 10 days to block 20 TPB domains and 2 IP addresses, with fines of up to 250,000 euros. BREIN's request to add new domains and IPs later is denied.                            |
| 2014      | The court of appeal reverses the Ziggo/XS4ALL order, mainly because it finds blocking ineffective.                                                                                                                                      |
| Jun 2017  | The EU Court of Justice (C-610/15) rules that TPB itself infringes copyright: running it is a "communication to the public".                                                                                                             |
| Sep 2017  | Interim order: Ziggo and XS4ALL must block within 10 business days, or pay 2,000 euros a day up to one million. The list from BREIN holds 155 URLs and IP addresses, mirrors and proxies included.                                      |
| Jun 2018  | The Hoge Raad (ECLI:NL:HR:2018:1046) overturns the 2014 ruling and sends the case to the Amsterdam court of appeal.                                                                                                                       |
| Jun 2020  | Amsterdam orders Ziggo and XS4ALL to block TPB's domain names and IP addresses. It dismisses the efficacy and overblocking arguments (90 to 95% of TPB's links infringe), but refuses dynamic blocking. Legal costs: over 250,000 euros for Ziggo, about 60,000 for XS4ALL. |
| Nov 2021  | BREIN, the Federatie Auteursrechtelijke Belangen and the ISPs (Ziggo, KPN, DFN (Delta Fiber Nederland), T-Mobile, Canal+, and 16 smaller ISPs through NLconnect) sign the "Convenant Blokkeren Websites". Freedom Internet refuses to sign, citing net neutrality. |
| Apr 2022  | Under the covenant BREIN sues Delta itself. Delta must block 1337x, LimeTorrents, YTS, RARBG, KickassTorrents and EZTV: domain names, alternative names, IP addresses, proxies and mirrors.                                             |

The covenant works like this: when a court orders one signatory to block a
site, the others block it too. BREIN takes turns suing a different ISP,
each side pays its own legal costs, and BREIN keeps the blocklist up to
date. No source found here says "Delta blocks TPB under the covenant" in
those words, but that is what the covenant does, and the block page on a
Delta line matches it.

## Why two layers

The court orders name domain names *and* IP addresses, and since 2012
non-compliance has carried fines. Delta implements the wording of the
order. There is some irony in this. The ISPs won in 2014 partly by arguing
that customers would just change DNS servers. Blocking by IP is exactly
what defeats "just change DNS", and in 2020 the court said circumvention
was no reason to drop the block.

The block is thorough only within its list. Nothing inspects traffic, so the
SNI passes through unread. Cloudflare's shared addresses leak around a list
of IPs, and the search backend `apibay.org` is not blocked at all (it
resolves and answers normally through Delta's own DNS).

## The bypass

`nix/delta-block-bypass.nix` adds one line to `/etc/hosts`:

```
104.17.0.1 thepiratebay.org
```

### Why it works

```
browser asks for thepiratebay.org
  |
  +- 1. /etc/hosts answers 104.17.0.1       (Delta's resolver is never asked)
  |
  +- 2. packet to 104.17.0.1 crosses Delta   (not on the list, routes normally)
  |
  +- 3. arrives at a Cloudflare edge in Amsterdam (cf-ray ...-AMS)
  |       TLS ClientHello carries SNI=thepiratebay.org
  |       the edge looks up that name: TPB's zone and certificate
  |
  +- 4. the edge proxies to TPB's origin server (nginx/1.22.1)
```

1. The resolver library consults `/etc/hosts` before it asks any DNS
   server, so the `blocked.delta.nl` answer never appears.
2. Delta's IP block is a list of specific destinations, and `104.17.0.1` is
   not on it.
3. Cloudflare serves millions of sites from shared anycast addresses, so its
   edge cannot tell sites apart by IP. It selects the site by the TLS SNI
   and the HTTP `Host` header. Ask for `thepiratebay.org` by name and you
   get TPB, through whichever address you came in on.
4. The certificate is issued for the name `thepiratebay.org`, not for an IP,
   so the browser sees a valid certificate and shows no warning.
5. Delta does not filter on SNI. The name crosses its network in plaintext;
   Delta just never checks it.

Search still works because the page is a static frontend that queries
`apibay.org`, which is not blocked, and the torrent links are magnet links.

### Not every Cloudflare address works

Cloudflare checks whether a zone may be served on a given edge address.
When it may not, the edge answers HTTP 403 with
[error 1034, "Edge IP Restricted"](https://developers.cloudflare.com/support/troubleshooting/http-status-codes/cloudflare-1xxx-errors/error-1034/).
The refusal is per address, not per range. Scan from Delta on 2026-10-01:

| Address          | Result                    |
|------------------|---------------------------|
| `104.16.123.96`  | error 1034 (this is the address `www.cloudflare.com` resolved to) |
| `104.16.0.1`     | TPB index page            |
| `104.17.0.1`     | TPB index page (pinned)   |
| `104.18.0.1` to `104.21.0.1` | TPB index page |
| `104.24.0.1`, `104.25.0.1`   | TPB index page |
| `172.66.0.1`     | TPB index page            |
| `188.114.96.1`   | TPB index page            |
| `172.64.0.1`, `172.67.0.1`   | no answer within 5 s |

How Cloudflare decides which address may serve which zone is not public, so
there is no telling how long `104.17.0.1` keeps working.

### Applying and checking it

All three machines import `nix/delta-block-bypass.nix`. After
`nixos-rebuild switch`:

```sh
getent hosts thepiratebay.org       # expect 104.17.0.1
curl -sI https://thepiratebay.org/  # expect a 302 to /index.html
```

If curl works but the browser times out, the browser is probably resolving
through its own DNS-over-HTTPS and skipping `/etc/hosts`. Turn that off, or
exclude the domain from it.

### When it stops working

| Symptom in the bypass check below | Likely cause                      | Fix                                            |
|-----------------------------------|-----------------------------------|------------------------------------------------|
| `error code: 1034`                | Cloudflare restricted the address | rerun the scan, pin a working address          |
| timeout on the pinned address only | BREIN listed it, Delta dropped it | rerun the scan, pin a working address          |
| timeout on every Cloudflare address | Delta started filtering by SNI   | ECH (encrypted SNI) or a tunnel, see below     |

## Reproducing the measurements

Tools: `nix-shell -p dig curl traceroute jq`. Expected output from
2026-10-01 is in the comments.

```sh
# Layer 1: Delta's resolver vs public resolvers.
for ns in 62.45.46.46 1.1.1.1 9.9.9.9; do
  echo "== $ns"; dig +short thepiratebay.org @$ns
done
# == 62.45.46.46   blocked.delta.nl. / 217.102.255.19
# == 1.1.1.1       162.159.137.6 / 162.159.136.6
# == 9.9.9.9       162.159.136.6 / 162.159.137.6

# The block page.
curl -sI http://217.102.255.19/ -H 'Host: thepiratebay.org' | grep -i '^location'
# Location: https://www.delta.nl/geblokkeerd/

# Layer 2: the real addresses time out (000 = no connection).
for ip in 162.159.136.6 162.159.137.6; do
  printf '%-15s ' "$ip"
  curl -s -m 10 -o /dev/null -w '%{http_code}\n' \
    --resolve "thepiratebay.org:443:$ip" https://thepiratebay.org/
done
# 162.159.136.6   000
# 162.159.137.6   000

# Where the packets stop, with a control trace into Cloudflare.
traceroute -n -q 1 -w 1 -m 8 162.159.136.6   # hop 2 81.172.185.129, then only *
traceroute -n -q 1 -w 1 -m 8 104.16.123.96   # continues via 62.45.63.215 to Cloudflare

# The same address seen from outside the Netherlands' ISPs.
id=$(curl -s -H 'Accept: application/json' \
  'https://check-host.net/check-tcp?host=162.159.136.6:443&max_nodes=3' | jq -r .request_id)
sleep 6
curl -s -H 'Accept: application/json' "https://check-host.net/check-result/$id" | jq -c .
# every node connects, in 1 to 90 ms

# The bypass, and the scan for spare addresses: same name, other Cloudflare IPs.
for ip in 104.16.123.96 104.16.0.1 104.17.0.1 104.18.0.1 104.19.0.1 104.20.0.1 \
          104.21.0.1 104.24.0.1 104.25.0.1 172.66.0.1 188.114.96.1; do
  printf '%-15s ' "$ip"
  curl -s -m 5 --resolve "thepiratebay.org:443:$ip" https://thepiratebay.org/index.html \
    | grep -o -m1 -e '<title>[^<]*' -e 'error code: [0-9]*' || echo 'no answer'
done
# 104.16.123.96   error code: 1034
# 104.17.0.1      <title>Download music, movies, games, software! The Pirate Bay ...

# The search backend is not blocked at all.
curl -s 'https://apibay.org/q.php?q=ubuntu&cat=0' | head -c 120
```

Cloudflare's current ranges are listed at <https://www.cloudflare.com/ips/>
if every address above stops working.

## Alternatives

- A tunnel to a server outside Delta: a commercial VPN, WireGuard on a VPS,
  or `ssh -D 1080 user@vps` with the browser on SOCKS5 and remote DNS. Slower
  than the hosts entry, but immune to any list Delta keeps.
- Tor. The exit node does the DNS lookup and the connection, so Delta's
  resolver and routes are never involved.
- Public "TPB proxy" mirrors are best avoided: they are run by unknown third
  parties who see, and can modify, everything the page loads.

## Sources

- [TorrentFreak: Dutch ISPs Ordered To Block The Pirate Bay (Jan 2012)](https://torrentfreak.com/dutch-isps-ordered-to-block-the-pirate-bay-120111/)
- [TorrentFreak: Five More Dutch ISPs Given 10 Days To Censor The Pirate Bay (May 2012)](https://torrentfreak.com/five-more-dutch-isps-given-10-days-to-censor-the-pirate-bay-120510/)
- [TorrentFreak: Dutch ISPs Block The Pirate Bay (Oct 2017)](https://torrentfreak.com/yarrrr-dutch-isps-block-the-pirate-bay-but-its-bad-timing-for-trolls-171005/)
- [Boek9: interim block, Rb. Den Haag 22 Sep 2017](https://www.boek9.nl/items/iept20170922-rb-den-haag-brein-v-ziggo-xs4all)
- [Emerce: XS4ALL en Ziggo moeten Pirate Bay blokkeren](https://www.emerce.nl/nieuws/xs4all-ziggo-moeten-pirate-bay-blokkeren)
- [Cassatieblog: Hoge Raad 29 June 2018, ECLI:NL:HR:2018:1046](https://cassatieblog.nl/proces-en-beslagrecht/eindarrest-vordering-tot-blokkade-pirate-bay/)
- [Rechtennieuws: Ziggo en XS4ALL moeten IP-adressen en domeinnamen Pirate Bay blokkeren](https://rechtennieuws.nl/63380/ziggo-en-xs4all-moeten-ip-adressen-en-domeinnamen-pirate-bay-voor-gebruikers-blokkeren/)
- [TorrentFreak: Dutch ISPs Must Block The Pirate Bay Despite Fierce Protest (Jun 2020)](https://torrentfreak.com/dutch-isps-must-block-the-pirate-bay-despite-fierce-protest-court-rules-200602/)
- [TorrentFreak: BREIN Signs Landmark Blocking Agreement with Dutch ISPs (Nov 2021)](https://torrentfreak.com/brein-signs-landmark-pirate-site-blocking-agreement-with-dutch-isps-211105/)
- [Ius Mentis: blokkade van piraterijwebsite geldt voortaan voor alle providers (Nov 2021)](https://blog.iusmentis.com/2021/11/10/blokkade-van-piraterijwebsite-geldt-voortaan-meteen-voor-alle-providers/)
- [Villamedia: providers blokkeren gezamenlijk sites die auteursrechten schenden](https://www.villamedia.nl/artikel/aanpak-online-piraterij-providers-blokkeren-gezamenlijk-sites-die-auteursrechten-schenden)
- [TorrentFreak: Dutch Pirate Site Blocklist Expands with RARBG, YTS, EZTV (Mar 2022)](https://torrentfreak.com/dutch-pirate-site-blocklist-expand-with-rarbg-yts-eztv-220331/)
- [Ius Mentis: Nederlandse internetaanbieders gaan Kickasstorrents, EZTV en Rarbg blokkeren (Apr 2022)](https://blog.iusmentis.com/2022/04/06/nederlandse-internetaanbieders-gaan-kickasstorrents-eztv-en-rarbg-blokkeren/)
- [Cloudflare docs: Error 1034, Edge IP Restricted](https://developers.cloudflare.com/support/troubleshooting/http-status-codes/cloudflare-1xxx-errors/error-1034/)
