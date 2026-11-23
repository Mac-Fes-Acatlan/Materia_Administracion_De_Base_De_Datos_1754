"""
---------------------------------------------------------
Description
-----------
ETL de ejemplo. Lee orders y order_items desde Postgres,
filtra por estatus y escribe un resumen en Iceberg.

El notebook launcher.ipynb crea Spark y llama a run().
Las rutas, credenciales y nombres de tabla viven en
parameter.json, no en esta clase.

=========================================================
About File
----------
    Created By  : Castañeda Landa Josué
    Created Date: 19 November 2026
    version = '1.0'
=========================================================
---------------------------------------------------------
"""

from functools import reduce

from pyspark.sql import DataFrame, SparkSession
from pyspark.sql import functions as F


class OrderItemsETL:
    """Arma el resumen de partidas de pedido y lo deja en Iceberg."""

    def __init__(self, spark: SparkSession, params: dict):
        self.spark = spark
        self.params = params

    def extract(self) -> dict[str, DataFrame]:
        """Lee cada tabla declarada en params['sources']."""
        postgres = self.params["postgres"]
        tables = {}
        for name, dbtable in self.params["sources"].items():
            tables[name] = (
                self.spark.read.format("jdbc")
                .option("url", postgres["url"])
                .option("dbtable", dbtable)
                .option("user", postgres["user"])
                .option("password", postgres["password"])
                .option("driver", postgres["driver"])
                .load()
            )
            print(f"extract: {dbtable}")
        return tables

    def transform(self, extracted: dict[str, DataFrame]) -> DataFrame:
        """Corre los pasos de transformación en orden."""
        functions_transform = [
            _transform_orders,
            _transform_items,
            _transform_filter_status,
            _transform_staging,
        ]
        data = reduce(
            lambda dict_extraction_data, function_transform: function_transform(
                dict_extraction_data
            ),
            functions_transform,
            {
                **extracted,
                "_order_status": self.params["transform"]["order_status"],
            },
        )
        return data["order_items_staging"]

    def load(self, dataframe: DataFrame) -> str:
        """Crea el namespace si no existe y reemplaza la tabla de salida."""
        iceberg = self.params["iceberg"]
        namespace = f"{iceberg['catalog']}.{iceberg['namespace']}"
        target = f"{namespace}.{iceberg['table']}"

        self.spark.sql(f"CREATE NAMESPACE IF NOT EXISTS {namespace}")
        dataframe.writeTo(target).createOrReplace()
        print(f"load: {target}")
        return target

    def run(self) -> str:
        """extract -> transform -> load."""
        print(f"etl: {self.params['etl_name']} env={self.params['env']}")
        extracted = self.extract()
        transformed = self.transform(extracted)
        return self.load(transformed)


def _transform_orders(inputs: dict[str, DataFrame]) -> dict[str, DataFrame]:
    """Deja en orders solo las columnas que usa el resumen."""
    inputs["orders"] = inputs["orders"].select(
        "order_id", "order_status", "order_purchase_timestamp"
    )
    return inputs


def _transform_items(inputs: dict[str, DataFrame]) -> dict[str, DataFrame]:
    """Deja en order_items solo las columnas que usa el resumen."""
    inputs["order_items"] = inputs["order_items"].select(
        "order_id", "order_item_id", "price", "freight_value"
    )
    return inputs


def _transform_filter_status(inputs: dict[str, DataFrame]) -> dict[str, DataFrame]:
    """Conserva los pedidos cuyo estatus viene en parameter.json."""
    statuses = inputs.pop("_order_status")
    inputs["orders"] = inputs["orders"].filter(F.col("order_status").isin(statuses))
    return inputs


def _transform_staging(inputs: dict[str, DataFrame]) -> dict[str, DataFrame]:
    """Une pedidos con partidas y calcula el total de cada línea."""
    inputs["order_items_staging"] = (
        inputs["orders"]
        .join(inputs["order_items"], "order_id", "inner")
        .withColumn("total", F.col("price") + F.col("freight_value"))
        .select(
            "order_id",
            "order_item_id",
            "order_status",
            "order_purchase_timestamp",
            "price",
            "freight_value",
            "total",
        )
    )
    return inputs
