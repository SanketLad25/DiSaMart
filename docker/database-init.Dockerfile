FROM mcr.microsoft.com/mssql/server:2022-latest
USER root
COPY database/ /database/
COPY docker/init-db.sh /usr/local/bin/init-db.sh
RUN chmod 0555 /usr/local/bin/init-db.sh
USER mssql
ENTRYPOINT ["/bin/bash", "/usr/local/bin/init-db.sh"]
