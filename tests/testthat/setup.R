
print(Sys.getenv("MOCK_DATASETS_FOLDER"))
print(omock::isMockDatasetDownloaded(datasetName = "synthea-covid19-10k"))
print(omock::isMockDatasetDownloaded(datasetName = "GiBleed"))

dbToTest <- Sys.getenv("DB_TO_TEST", "duckdb")
copyCdm <- function(cdm) {
  if (dbToTest == "duckdb") {
    to <- CDMConnector::dbSource(
      con = duckdb::dbConnect(drv = duckdb::duckdb(dbdir = ":memory:")),
      writeSchema = c(schema = "main", prefix = "pp_test_")
    )
  } else if (dbToTest == "sql server") {
    to <- CDMConnector::dbSource(
      con = DBI::dbConnect(
        odbc::odbc(),
        Driver = "ODBC Driver 18 for SQL Server",
        Server = Sys.getenv("CDM5_SQL_SERVER_SERVER"),
        Database = Sys.getenv("CDM5_SQL_SERVER_CDM_DATABASE"),
        UID = Sys.getenv("CDM5_SQL_SERVER_USER"),
        PWD = Sys.getenv("CDM5_SQL_SERVER_PASSWORD"),
        TrustServerCertificate = "yes",
        Port = 1433
      ),
      writeSchema = c(
        schema = Sys.getenv("CDM5_SQL_SERVER_OHDSI_SCHEMA"),
        prefix = "pp_test_"
      )
    )
  } else if (dbToTest == "redshift") {
    to <- CDMConnector::dbSource(
      con = DBI::dbConnect(
        RPostgres::Redshift(),
        dbname = Sys.getenv("CDM5_REDSHIFT_DBNAME"),
        port = Sys.getenv("CDM5_REDSHIFT_PORT"),
        host = Sys.getenv("CDM5_REDSHIFT_HOST"),
        user = Sys.getenv("CDM5_REDSHIFT_USER"),
        password = Sys.getenv("CDM5_REDSHIFT_PASSWORD")
      ),
      writeSchema = c(
        schema = Sys.getenv("CDM5_REDSHIFT_SCRATCH_SCHEMA"),
        prefix = "pp_test_"
      )
    )
  } else if (dbToTest == "postgres") {
    # TODO
  } else if (dbToTest != "local") {
    cli::cli_abort(c(x = "Not supported dbToTest: {.pkg {dbToTest}}"))
  }

  if (dbToTest != "local") {
    cdm <- omopgenerics::insertCdmTo(cdm = cdm, to = to)
  }

  return(cdm)
}
dropCreatedTables <- function(cdm) {
  omopgenerics::dropSourceTable(cdm = cdm, name = dplyr::everything())
}
