Kanboard Docker Container
=========================

This is a docker container for running [Kanboard](http://kanboard.net).

The default user and password are both: `admin`

Configuration
-------------

The `config.php` is generated from environment variables beginning with
`KANBOARD_`.

Example:

    docker run ... --env=KANBOARD_DEBUG=true ...

Would generate the `config.php` line:

    define('DEBUG', true);

Linking to mysql or postgres
----------------------------

I haven't tested the MySQL/Maria and Postgres databases yet, but I added the
host/port linking for the default MySQL and Postgres ports.

Link the database as `db` to have this work. Example:

    docker run ... --link=my-db-container:db ...
