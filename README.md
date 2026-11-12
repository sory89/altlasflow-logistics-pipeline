# 🚚 AtlasFlow – Real-Time Logistics Data Platform

<p align="left">
  <img src="https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white" />
  <img src="https://img.shields.io/badge/Apache_Kafka-231F20?style=for-the-badge&logo=apachekafka&logoColor=white" />
  <img src="https://img.shields.io/badge/Debezium-FF5A4E?style=for-the-badge&logo=debezium&logoColor=white" />
  <img src="https://img.shields.io/badge/Apache_Flink-E6526F?style=for-the-badge&logo=apacheflink&logoColor=white" />
  <img src="https://img.shields.io/badge/Apache_Iceberg-4B83B8?style=for-the-badge&logo=apacheiceberg&logoColor=white" />
  <img src="https://img.shields.io/badge/Trino-7952B3?style=for-the-badge&logo=trino&logoColor=white" />
  <img src="https://img.shields.io/badge/Apache_Superset-20A7A7?style=for-the-badge&logo=apachesuperset&logoColor=white" />
  <img src="https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white" />
  <br/>
  <img src="https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white" />
  <img src="https://img.shields.io/badge/Prometheus-E6522C?style=for-the-badge&logo=prometheus&logoColor=white" />
  <img src="https://img.shields.io/badge/Grafana-F46800?style=for-the-badge&logo=grafana&logoColor=white" />
  <img src="https://img.shields.io/badge/GitHub_Actions-2088FF?style=for-the-badge&logo=githubactions&logoColor=white" />
</p>

**Build an End-to-End Real-Time Logistics Data Platform using Kafka, Debezium, Apache Flink, Apache Iceberg, Trino, and Apache Superset.**

---

## 📌 Overview

AtlasFlow is an end-to-end real-time logistics data platform designed to demonstrate modern Data Engineering, streaming architecture, and Lakehouse technologies.

The platform simulates the operational environment of a global logistics company and provides real-time visibility into:

- Shipment tracking and delivery performance.
- Delayed and high-risk shipments.
- Inventory shortages.
- Carrier performance.
- Logistics disruptions.

The solution implements Change Data Capture (CDC) using Debezium, event streaming with Apache Kafka, stream processing with Apache Flink SQL, and analytical storage using Apache Iceberg.

## 🏗️ Architecture

![AtlasFlow Architecture](docs/architecture/atlasflow-architecture.png)

### Data Pipeline

```text
Python Logistics Generator
          |
          v
      PostgreSQL
          |
          v
       Debezium
          |
          v
     Apache Kafka
          |
          v
      Apache Flink
          |
          v
    BRONZE - Iceberg
          |
          v
    SILVER - Iceberg
          |
          v
     GOLD - Iceberg
          |
          v
         Trino
          |
          v
    Apache Superset
          |
          v
  Logistics Control Tower
```

## 🥉 Medallion Architecture

| Layer | Description | Technology |
|---|---|---|
| Bronze | Raw CDC events | Flink + Iceberg |
| Silver | Cleaned and normalized data | Flink + Iceberg |
| Gold | Business-ready analytical datasets | Flink + Iceberg |

### Gold Dataset

`gold.shipment_control_tower`

Consolidates:

- Customers
- Orders
- Shipments
- Carriers
- Inventory balances
- Tracking events
- Logistics disruptions

## 🗄️ Operational Data Model

PostgreSQL database: `atlasflow_ops`

| Table | Description |
|---|---|
| customers | Customer information |
| orders | Operational orders |
| inventory_balances | Warehouse inventory |
| carriers | Carrier information |
| shipments | Shipment lifecycle |
| tracking_events | Shipment tracking history |
| disruptions | Logistics disruptions |

![Data Model](docs/architecture/data-model.png)

## ⚙️ Technology Stack

| Component | Responsibility |
|---|---|
| Python | Logistics data generation |
| PostgreSQL | Operational database |
| Debezium | Change Data Capture |
| Apache Kafka | Event streaming |
| Apache Flink SQL | Real-time processing |
| Apache Iceberg | Open Lakehouse table format |
| RustFS | S3-compatible object storage |
| Iceberg REST Catalog | Table metadata management |
| Trino | Distributed SQL analytics |
| Apache Superset | Business Intelligence |
| Prometheus | Metrics collection |
| Grafana | Monitoring and dashboards |
| Docker Compose | Local infrastructure |
| GitHub Actions | CI/CD and static validation |

## 📊 Business Use Case – Logistics Control Tower

The platform enables operations teams to monitor key logistics KPIs:

| KPI | Description |
|---|---|
| Total Shipments | Total shipment volume |
| On-Time Delivery Rate | Percentage of on-time deliveries |
| Average Delivery Delay | Average delivery delay in minutes |
| High-Risk Shipments | Shipments requiring attention |
| Active Disruptions | Ongoing logistics disruptions |
| Inventory Shortages | Products with insufficient stock |
| Carrier Performance | Delivery performance by carrier |

## 📈 Observability

Prometheus and Grafana provide infrastructure and pipeline monitoring.

Monitored components:

- PostgreSQL
- Kafka
- Debezium
- Apache Flink
- Iceberg services
- RustFS

## 🚀 Getting Started

### Prerequisites

- Docker Desktop
- Docker Compose
- Python 3.12+
- Git

### Clone the repository

```bash
git clone https://github.com/YOUR_USERNAME/AtlasFlow.git
cd AtlasFlow
```

### Configure environment

```bash
cp .env.example .env
```

### Create Python environment

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### Start the platform

```bash
docker compose up -d
```

### Check services

```bash
docker compose ps
```

### Generate logistics data

```bash
python src/generator/logistics_generator.py
```

## 📂 Repository Structure

```text
AtlasFlow/
├── .github/
│   └── workflows/
├── config/
│   ├── postgres/
│   ├── kafka/
│   ├── debezium/
│   ├── flink/
│   ├── iceberg/
│   ├── trino/
│   ├── superset/
│   └── prometheus/
├── docs/
│   └── architecture/
├── scripts/
├── src/
│   ├── generator/
│   └── flink/
│       ├── bronze/
│       ├── silver/
│       └── gold/
├── sql/
├── dashboards/
├── tests/
├── docker-compose.yml
├── requirements.txt
├── .env.example
├── .gitignore
└── README.md
```

## 🔐 CI/CD

GitHub Actions automates repository validation:

- Python syntax validation.
- SQL asset validation.
- Configuration validation.
- Data contract checks.
- Static repository validation.

## 🛣️ Future Enhancements

- Apache Airflow for workflow orchestration.
- dbt for SQL transformations.
- Great Expectations for data quality.
- OpenLineage for data lineage.
- HashiCorp Vault for secrets management.
- Loki and OpenTelemetry for observability.
- Kubernetes and Helm for production deployment.
- Terraform for infrastructure provisioning.

## 🎯 Project Objectives

AtlasFlow demonstrates practical implementation of:

- Real-Time Data Engineering.
- Change Data Capture (CDC).
- Distributed Event Streaming.
- Open Lakehouse Architecture.
- Streaming Data Processing.
- DataOps and Observability.
- Business Intelligence.

---

**AtlasFlow – Turning Operational Logistics Data into Real-Time Business Intelligence.**