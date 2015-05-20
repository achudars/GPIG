# GPIG

## Setup/installation

### Database installation/restoration

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

### Migrating to a shared data directory (GeoServer)

**This won't work, instead just copy over the `styles` and `workspaces` folders from the repository to your local data directory. Make sure the resulting folders have appropriate permissions so that your webserver can access it.*

In order to share styles and track GeoServer configuration in the repository, we need to migrate the data directory to the one located in the repository. During this process you may lose some of the changes you've made locally, which you need to manually copy over later from your original local data directory.

The shared data directory is located in the `GeoServerData` directory in the root of this repository. In order for GeoServer to start using this, you need to follow the appropriate guide in the user manual to change `GEOSERVER_DATA_DIR` variable to point to this new location:

* [OS X](http://suite.opengeo.org/opengeo-docs/intro/installation/mac/postinstall.html#geoserver-data-directory)
* [Windows](http://suite.opengeo.org/opengeo-docs/intro/installation/windows/postinstall.html#geoserver-data-directory)
* [Ubuntu](http://suite.opengeo.org/opengeo-docs/intro/installation/ubuntu/postinstall.html#geoserver-data-directory)

Note that the guides should also list the original data directory location, from which you can copy over any specific changes you've made (such as new styles, layers etc.) into the shared data directory. Make sure the location in the shared data directory mirrors that of the source, i.e the structure remains the same.

## Applications

All OpenLayers applications are located in `Applications`. In general, with every significant addition to the application we should create a new application. This can be done by simply duplicating the application you want the new version to be based on, and renaming the result.

This will leave us with a nice set of applications that iteratively build upon one another, giving a better overview of progress that has been made. What is considered "significant" in this context is up to interpretation. However, if the changes will alter the data, or it's direct presentation (such as the style of the layer), or the user functionality (like modifying the UI by adding new controls) of the application, then a new application should be created.

### Basic Application

In the `Applications` folder, there is an application that can be used to display simple points for incidents (no interactions, no nothing). You can run this application by issuing the following command (assumes you are in the `Applications` folder and have Boundless SDK installed)

```bash
suite-sdk debug incidentpoints
```

This application assumes you have set up a workspace/store/layer stack in Geoserver (refer to installation above about PostGIS), serving a layer named `incidents` from a workspace called `crime`. You also have to be running Geoserver and a Postgres server locally in order to run the application.

Assuming everything works, opening your browser to `http://localhost:9080` should display an application showing you crime around York.

![Image of basic application](/Images/Basic Incident Points.png)

### Neighbourhoods Application

Iteration on the basic application, draws areas/neighbourhoods based on post codes and colours them based on the number of incidents contained within each. Run similarly to the basic application

```bash
suite-sdk debug neighbourhoodstats
```

This application assumes GeoServer is using the shared data directory and is connected to a properly configured PostGIS server. Assuming everything works, opening your browser to `http://localhost:9080` should display an application showing you crime around York.

![Image of neighbourhood stats application](/Images/Neighbourhood Stats Heatmap.png)

### Things to note

* Due to the large number of incidents in the database, make sure your application is always zoom-limited, that way the application can never be overwhelmed as only a limited subset of incidents will be visible at any point.
