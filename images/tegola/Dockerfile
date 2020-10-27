FROM gospatial/tegola:v0.12.1
# Volumen
ENV CACHEDATA /mnt/data
RUN mkdir -p "$CACHEDATA" && chmod 777 "$CACHEDATA" && apk update && apk add bash postgresql-client
VOLUME /mnt/data
COPY ./config/config.toml  /opt/tegola_config/config.toml
COPY ./start.sh ./start.sh
CMD ./start.sh
ENTRYPOINT [ "./start.sh" ]