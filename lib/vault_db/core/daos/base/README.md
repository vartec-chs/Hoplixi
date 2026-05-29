# Base DAO

This directory contains the base Data Access Object (DAO) classes for the Vault
Database. These base DAOs provide common functionality and serve as a foundation
for more specific DAOs that interact with the database. They typically include
methods for basic CRUD operations, as well as shared SQL-related logic and
utilities that can be reused across different DAOs.

DAOs in this layer are responsible only for database access and SQL query
execution. They should not contain business logic, application workflows,
validation rules, domain decisions, or orchestration between multiple use cases.
Their purpose is to provide a clear and reusable persistence layer that can be
consumed by higher-level components such as repositories and services. Business
logic should be implemented in repositories or other application/domain layers,
while DAOs remain focused solely on data persistence and retrieval.
