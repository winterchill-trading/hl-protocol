(lang dune 3.17)
(name hl-protocol)
(generate_opam_files true)
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
  ppx_jane
  ppx_yojson_conv
  yojson))
