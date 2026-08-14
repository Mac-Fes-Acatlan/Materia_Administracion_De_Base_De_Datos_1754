FROM jupyter/all-spark-notebook:spark-3.5.0

USER root

# ============================================================
# Python
# ============================================================

RUN pip install --no-cache-dir \
    pandas \
    matplotlib \
    sympy

# ============================================================
# Apache Iceberg
# Spark 3.5 + Scala 2.12
# ============================================================

ENV ICEBERG_VERSION=1.10.0

RUN wget -q \
    "https://repo1.maven.org/maven2/org/apache/iceberg/iceberg-spark-runtime-3.5_2.12/${ICEBERG_VERSION}/iceberg-spark-runtime-3.5_2.12-${ICEBERG_VERSION}.jar" \
    -O /usr/local/spark/jars/iceberg-spark-runtime-3.5_2.12.jar

# ============================================================
# PostgreSQL JDBC
# ============================================================

RUN wget -q \
    "https://jdbc.postgresql.org/download/postgresql-42.7.7.jar" \
    -O /usr/local/spark/jars/postgresql-42.7.7.jar

USER ${NB_UID}