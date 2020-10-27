# tiles-db

PostGIS database container to store the data for rendering tiles.
It is used by both vector tiles and rasterized tiles.
Data is inserted using the `imposm` container.
This database is part of an independent pipeline separated from the main microcosm tiler pipeline. The data is stored in a scheme adjusted for Tegola needs and thus the tiles needs to be stored in their own PostGIS.

### Configuration

Required environment variables:

- `POSTGRES_HOST` e.g `tiles-db`
- `POSTGRES_DB` e.g `tiler-osm`
- `POSTGRES_PORT` e.g `5432`
- `POSTGRES_USER` e.g `postgres`
- `POSTGRES_PASSWORD` e.g `1234`
