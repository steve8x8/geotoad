template = {

  # caveat: use this format as last one
  'wptpoi-nuvi' => {
    'ext'         => 'wpt.gpi',
    'desc'        => 'POI for Nuvi Waypoints, pure ASCII',
    'required'    => 'gpsbabel:iconv',
    'filter_src'  => 'gpx-wpts',
    'filter_exec' => 'cat INFILE | tr \'«‹›»\' \'*\' | iconv -f UTF8 -t ASCII//TRANSLIT -c | ' +
                      'gpsbabel -i gpx -o garmin_gpi,category="Waypoints",bitmap=STYLEFILE,alerts=1,unique=0,proximity=250m,sleep=2 -f - -F OUTFILE',
    # "dot" (reference point) symbol, created in xpaint
    'filter_style64' => "Qk1SAQAAAAAAAFIAAAAoAAAAEAAAABAAAAABAAgAAAAAAAABAABtCwAAbQsAAAcAAAAHAAAA/wD/\n" +
                        "AJmZmQBmZmYAzMzMAP///wAzMzMAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAECAgICAQAAAAAA\n" +
                        "AAAAAAIBAwMDAwECAAAAAAAAAAIDBAQEBAQEAwIAAAAAAAIDBAQEBAQEBAQDAgAAAAEBBAQEAwEB\n" +
                        "AwQEBAEBAAACAwQEAwIFBQIDBAQDAgAAAgMEBAEFBgYFAQQEAwIAAAIDBAQBBQYGBQEEBAMCAAAC\n" +
                        "AwQEAwIFBQIDBAQDAgAAAQEEBAQDAQEDBAQEAQEAAAACAwQEBAQEBAQEAwIAAAAAAAIDBAQEBAQE\n" +
                        "AwIAAAAAAAAAAgEDAwMDAQIAAAAAAAAAAAABAgICAgEAAAAAAAAAAAAAAAAAAAAAAAAAAAA=\n"
  },

}
