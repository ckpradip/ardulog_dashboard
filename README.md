# ardulog_dashboard
The idea behind ardulog dashboard is that the server maintains all the logs in an effective manner.
It should be platform/software agnostic.

```mermaid
%%{init: {'theme':'forest'}}%%
sequenceDiagram
    box Brown GCS
        participant DashboardManager
    end
    box DarkGreen DBServer
        participant Facade
        participant TempStorage
        participant ParquetProcessor
        participant SQLIndex
    end

    DashboardManager->>Facade: Initiate log file copying
    Facade->>TempStorage: Copy logs to temporary storage
    TempStorage->>Facade: Copy operation completed
    Facade->>DashboardManager: Log copying completed
    Facade->>ParquetProcessor: Generate Parquet files for each log type (<logname>_<type>)
    ParquetProcessor->>Facade: Parquet file generation completed
    Facade->>DashboardManager: Parquet file distribution completed
    Facade->>SQLIndex: Provide indexing data
    SQLIndex->>Facade: Indexing operation completed
    Facade->>DashboardManager: Indexing process completed
```
