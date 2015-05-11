# GPIG

## Database installation/restoration

Database should be running on PostgreSQL, which on OS X is quite easy to set up (pending Windows guide), simply download [Postgres.app](https://github.com/PostgresApp/PostgresApp/releases) and run it. This will come with all the tools you need for the database server (including command-line tools).

Assuming you have PostgreSQL server running, and PostGIS installed, you can restore a database of roughly 6.5 million incidents from 2014-01 to 2015-03 (not verified) as follows. Run these commands from the `Database` directory

```bash
createdb crimedata
gunzip -c data.gz | psql crimedata
```

Assuming the database restores without problems, you should be able to setup the PostGIS resource under GeoServer referencing [this guide](http://docs.geoserver.org/stable/en/user/data/database/postgis.html) (not verified).
