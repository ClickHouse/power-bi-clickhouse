<p align="center" style="font-size:300%">
<img src=".static/clickhouse.png" width="200px" align="center">
<img src=".static/powerbi.svg" width="200px" align="center">
<h1 align="center">ClickHouse Connector for Power BI</h1>
</p>
<br/>

## Introduction

This MS certified connector allows you to retrieve data from ClickHouse directly into Power BI for analysis and visualization.

## Features

- **Direct Query**: The connector supports Direct Query mode, allowing you to work with large datasets in real-time.
- **ODBC Driver Configuration**: Customize the ODBC driver settings to meet your specific requirements.
- **Microsoft Certification**: This connector was certified by the Connectors team at Microsoft. It is available by default in all latest PowerBI distributions.

## Installation

The connector is available in Microsoft recent distributions. If you can't update to one of those, please refer the next section: [Manual Installation](#manual-installation).


1. Download and install the [ClickHouse ODBC driver](https://github.com/ClickHouse/clickhouse-odbc).
1. Click on "Get Data" and search for "ClickHouseODBCConnector."
1. Enter the required connection details, such as server name, port, database name, and optional connection options.
1. Enter your username and password.
1. Choose the desired data retrieval mode: Import or Direct Query.
1. Click "OK" to establish the connection and start working with ClickHouse data in Power BI.


## Manual Installation

1. Download and install the [ClickHouse ODBC driver](https://github.com/ClickHouse/clickhouse-odbc).
1. Create the following directory for the custom connector "Documents\Power BI Desktop\Custom Connectors" directory.
1. Download the latest release of the Power BI Connector for ClickHouse from the [Releases](https://github.com/ClickHouse/power-bi-clickhouse/releases) section and place it in the directory you just created.
1. Enable unsigned connectors loading in File &rarr; Options and settings &rarr; Options &rarr; Security &rarr; Data Extensions &rarr; Allow any extension to load without warning or validation.
1. Continue to step 2 in the previous section.


## Power BI Service

For cloud usage, please refer to [Microsoft documentation](https://learn.microsoft.com/en-us/power-bi/connect-data/service-gateway-custom-connectors#enable-and-use-custom-connectors) for information on enabling custom data connectors in the cloud using on-premises data gateway.

## Documentation

For more information about the ClickHouseODBCConnector functions, configuration options, and usage examples, refer to the [official documentation](https://clickhouse.com/docs/en/integrations/powerbi).

## Support and Feedback

If you encounter any issues or have feedback regarding the Power BI Connector for ClickHouse, please [submit an issue on GitHub](https://github.com/ClickHouse/power-bi-clickhouse/issues).
