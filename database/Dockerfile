# Postgres 15 com PostGIS 3 (caminho das rotas: delivery_routes.street_path).
# Parte da imagem oficial postgres:15 para manter a mesma glibc (collation) dos volumes já criados;
# as imagens postgis/postgis usam um Debian mais antigo.
FROM postgres:18

RUN apt-get update \
    && apt-get install -y --no-install-recommends postgresql-15-postgis-3 \
    && rm -rf /var/lib/apt/lists/*
