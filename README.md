delicious-library-tw
====================

a dirty sinatra app to add taiwan books support in delicious library

Prerequisites
-------------

`gem install sinatra haml nokogiri isbn-tools`

Usage
-----

1. add the following line into /etc/hosts

    `0.0.0.0 webservices.amazon.fr`

2. run dl.rb as root

    `sudo ruby dl.rb -p 80`

3. use your library as usual

4. have fun!

TODO
----

- handle old books
- handle no isbn books

See Also
--------

- [Sinatra](http://www.sinatrarb.com/ "Sinatra")
- [Delicious Library](http://www.delicious-monster.com/ "Delicious Library")

Copyright
---------

Copyright (c) 2010 Alec Chen. See LICENSE for details.
