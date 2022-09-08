import logging
import os
import sys
from logging.handlers import RotatingFileHandler
from typing import List, Optional

from pyspark.sql import SparkSession, DataFrame
from pyspark import SparkContext

from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions

AWS_JOB_NAME: str = 'JOB_NAME'
DEFAULT_MODE_AWS: str = 'aws'
LOCAL_MODE: str = 'local'


class ExecutionContextProvider:
    """`ExecutionContextProvider` is a context manager responsible for providing the context of the execution
    environment.

    It lets developer author, debug, run, test, and performance-tune spark/glue jobs while freeing the developer from
    taking care of the environmental detail around local development or aws environment.

    Example::

        with ExecutionContextProvider(mode, glue_args, local_args) as execution_context:
        logger = execution_context.logger
        logger.info("Stating my job")
        my_df = execution_context.get_dataframe(local_path_parquet=data_path_local,
                                                name_space=aws_catalog_database_name,
                                                table_name=aws_catalog_table_name)
        result = my_complex_transformations(my_df)
        execution_context.save_dataframe(df=result, local_path_parquet="my/local/path/to/output",
                                         connection_type="s3", format="parquet",
                                         connection_options={"path": "s3://path",
                                                             "partitionKeys": ["col1", "col2", "col3"]},
                                         transformation_ctx="parquetData")
        See Also: for usage please see: scripts/jobs/levenshtein_address_matching.py

    """

    def __init__(self, mode: str = DEFAULT_MODE_AWS, glue_args: List = None, local_args=None):
        """Constructor for the ExecutionContextProvider

        Args:
            mode: Execution mode, it should be 'aws' or 'local'
            glue_args: Arguments passed to the glue job
            local_args: Arguments passed to the local job
        Raises:
            ValueError: if mode is not one of the following: 'aws' or 'local'
        """

        if mode not in [DEFAULT_MODE_AWS, LOCAL_MODE]:
            raise ValueError("mode should be 'aws' or 'local'")
        self.__mode = mode
        glue_args = glue_args or []
        glue_args.append(AWS_JOB_NAME)
        self.__args = getResolvedOptions(sys.argv, glue_args) if self.mode == DEFAULT_MODE_AWS else vars(local_args)

#         sc = SparkContext()
#         if self.mode == DEFAULT_MODE_AWS:
#             conf = sc.getConf() \
#                 .set("spark.sql.legacy.parquet.int96RebaseModeInRead", "LEGACY") \
#                 .set("spark.sql.legacy.parquet.int96RebaseModeInWrite", "LEGACY") \
#                 .set("spark.sql.legacy.parquet.datetimeRebaseModeInRead", "LEGACY") \
#                 .set("spark.sql.legacy.parquet.datetimeRebaseModeInWrite", "LEGACY") \
#                 .set("spark.sql.execution.arrow.pyspark.enabled", "true") \
#                 .set("spark.sql.execution.arrow.pyspark.fallback.enabled", "true") \
#                 .set("spark.sql.execution.arrow.maxRecordsPerBatch", "10000") \
#                 .set("spark.sql.execution.arrow.pyspark.selfDestruct.enabled", "true")
#             # Restart spark context
#             sc.stop()
#             sc = SparkContext.getOrCreate(conf=conf)
#             sc.setCheckpointDir("s3://dataplatform-stg-glue-temp-storage/planning/checkpoint/")



#         self.__glue_context = GlueContext(sc) if self.mode == DEFAULT_MODE_AWS else None
        self.__glue_context = GlueContext(SparkContext()) if self.mode == DEFAULT_MODE_AWS else None
        
        self.__spark_session = self.__glue_context.spark_session if self.mode == DEFAULT_MODE_AWS else SparkSession \
            .builder \
            .config("spark.sql.debug.maxToStringFields", "10000") \
            .config("spark.sql.parquet.int96RebaseModeInRead", "LEGACY") \
            .config("spark.sql.parquet.int96RebaseModeInWrite", "LEGACY") \
            .config("spark.sql.parquet.datetimeRebaseModeInRead", "LEGACY") \
            .config("spark.sql.parquet.datetimeRebaseModeInWrite", "LEGACY") \
            .config("spark.sql.execution.arrow.pyspark.enabled", "true") \
            .config("spark.sql.execution.arrow.pyspark.fallback.enabled", "true") \
            .config("spark.sql.execution.arrow.maxRecordsPerBatch", "10000") \
            .config("spark.sql.execution.arrow.pyspark.selfDestruct.enabled", "true") \
            .config("spark.sql.shuffle.partitions", "7") \
            .config("spark.driver.memory", "12g") \
            .master("local[*]") \
            .appName("SparkLocal") \
            .getOrCreate()
        if self.mode == LOCAL_MODE:
            self.__spark_session.sparkContext.setCheckpointDir("/tmp/dataplatform-tmp")
        self.__job = Job(self.__glue_context) if self.mode == DEFAULT_MODE_AWS else None
        self.__logger = self.__glue_context.get_logger() if self.mode == DEFAULT_MODE_AWS else self.__get_local_logger()

    def __enter__(self):
        if self.mode == DEFAULT_MODE_AWS:
            self.__job.init(self.__args[AWS_JOB_NAME], self.__args)

        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.mode == DEFAULT_MODE_AWS:
            self.__job.commit()
        else:
            self.spark_session.stop()

    @property
    def mode(self) -> str:
        return self.__mode

    @property
    def spark_session(self) -> SparkSession:
        return self.__spark_session

    @property
    def logger(self):
        return self.__logger

    def get_input_args(self, input_key: str) -> Optional[str]:
        """Gets the value of the input argument passed to the job (glue or local) based on it's key or None for
        nonexistent key. The argument to the job are given in the form --my_key=my_value therefore input_key is my_key
        and my_value will be returned by this method.

        Args:
            input_key: key part of the argument

        Returns:
            value: value of the argument or None for the nonexistent key.
        """
        return self.__args[input_key] if input_key in self.__args else None

    def get_dataframe(self, local_path_parquet: Optional[str] = None, **dynamic_frame_args) -> DataFrame:
        """Loads the DataFrame (Spark)

        Args:
            local_path_parquet: path on the local file system of the directory containing parquet
                                (to be used in local mode)
            **dynamic_frame_args: kwargs for dynamic frame (to be used in aws mode)

        Raises:
            ValueError if dynamic_frame_args or local_path_parquet is empty depending on execution i.e. aws or local

        Returns:
            DataFrame

        """
        if self.mode == DEFAULT_MODE_AWS:
            if not dynamic_frame_args:
                raise ValueError("dynamic_frame_args cannot be empty")
            return self.__glue_context.create_data_frame_from_catalog(**dynamic_frame_args)
        else:
            if not local_path_parquet:
                raise ValueError("local_path_parquet cannot be empty")
            return self.spark_session.read.parquet(local_path_parquet)

    @staticmethod
    def save_dataframe(df: DataFrame, save_path: str, *partition_columns: str,
                       save_mode: Optional[str] = "append") -> None:
        """Save the DataFrame either to the S3 (in `aws` mode) or to the local storage (in `local` mode)

        Args:
            df: DataFrame to be saved
            save_path: path where data will be saved
            partition_columns: partition columns
            save_mode: Can be one of the following: append or overwrite or error or ignore

        Raises:
            ValueError if save_path is empty

        Notes: save_mode although optional but can take one of the following values
        * `append`: Append contents of this :class:`DataFrame` to existing data.
        * `overwrite`: Overwrite existing data.
        * `error` or `errorifexists`: Throw an exception if data already exists.
        * `ignore`: Silently ignore this operation if data already exists.
        """
        if not save_path:
            raise ValueError("save_path cannot be empty")

        save_mode = save_mode if save_mode in ["append", "overwrite", "error", "errorifexists", "ignore"] else "append"

        if partition_columns:
            df.write.mode(save_mode).partitionBy(*partition_columns).parquet(save_path)
        else:
            df.write.mode(save_mode).parquet(save_path)

    @staticmethod
    def __get_local_logger():
        """Creates a logger for the local execution mode. It writes log to both an output console and to a file called
        spark_local.log

        Returns: logger
        """
        # """
        current_path = os.path.dirname(__file__)
        root_path = current_path[:current_path.find("scripts")]
        log_dir_path = os.path.join(root_path, "scripts", "logs")
        os.makedirs(log_dir_path, exist_ok=True)

        log_file_path = os.path.join(log_dir_path, "spark_local.log")
        five_mb = 5 * 1024 * 1024
        logging.basicConfig(
            format="%(asctime)s %(levelname)7s %(module)20s.%(lineno)3d: %(message)s",
            datefmt="%y/%m/%d %H:%M:%S",
            level=logging.ERROR,
            handlers=[
                # logging.handlers.RotatingFileHandler(filename=log_file_path, maxBytes=five_mb, backupCount=3),
                RotatingFileHandler(filename=log_file_path, maxBytes=five_mb, backupCount=3),
                logging.StreamHandler()
            ])

        logger = logging.getLogger(__name__)
        logger.setLevel(logging.DEBUG)
        return logger
