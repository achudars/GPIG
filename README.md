# GPIG

## Database installation/restoration

Database should be running on PostgreSQL, which on OS X is quite easy to set up (pending Windows guide), simply download [Postgres.app](https://github.com/PostgresApp/PostgresApp/releases) and run it. This will come with all the tools you need for the database server (including command-line tools).

Assuming you have PostgreSQL server running and PostGIS installed, you can follow these steps to create a full database, consisting of two tables (`incidents` and `neighbourhoods` respectively).

First, create the database and enable PostGIS on it

```
createdb crimedata
psql -d crimedata -c "CREATE EXTENSION postgis;"
```

Then, from the `Database` directory, create and populate the two tables (note that both of these commands can take a long-LONG time to complete)

```
gunzip < incidents.sql.gz | psql -d crimedata
gunzip < neighbourhoods.sql.gz | psql -d crimedata
```

Assuming the database restores without problems, you should be able to setup the PostGIS resource under GeoServer referencing [this guide](http://docs.geoserver.org/stable/en/user/data/database/postgis.html), note, both `neighbourhoods` and `incidents` should be separate layers.


## Basic Application

In the `Applications` folder, there is an application that can be used to display simple points for incidents (no interactions, no nothing). You can run this application by issuing the following command (assumes you are in the `Applications` folder and have Boundless SDK installed)

```bash
suite-sdk debug incidentpoints
```

This application assumes you have set up a workspace/store/layer stack in Geoserver (refer to installation above about PostGIS), serving a layer named `incidents` from a workspace called `crime`. You also have to be running Geoserver and a Postgres server locally in order to run the application.

Assuming everything works, opening your browser to `http://localhost:9080` should display an application showing you crime around York.

![Image of basic application](/Images/Basic Incident Points.png)

### Things to note

* There is no way to interact with the incidents, for example you can't get more information about them.
* Due to the number of incidents, the map zoom scale is limited, as zooming out too far would most likely freeze the application.
