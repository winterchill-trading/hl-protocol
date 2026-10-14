(lang dune 3.17)
(name hl-protocol)
(generate_opam_files true)
(authors "WinterChill AI")
(maintainers "hello@winterchill.xyz")
(source (github winterchill-trading/hl-protocol))
(license MIT)
(license MIT)
(source (github winterchill-trading/hl-protocol))
(package
 (name hl-protocol)
 (synopsis "Hyperliquid wire types and JSON codecs")
 (depends
  (ocaml (>= 5.2))
  dune
  core
  fixed-decimal
  exchange-core
  ppx_jane
  ppx_yojson_conv
  yojson))
