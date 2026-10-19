# BuilderMetrix MI — Parameter Reference

Machine-readable companion to `BMX-MI-Deployment-Spec.md`. Values marked `TBD` must be
supplied before deployment; do not substitute defaults.

---

## Managed Instance

```yaml
managed_instance:
  name:                    sqlmi-bmx-prod  # forms the FQDN - permanent
  resource_group:          rg-bmx-sqlmi-wus3
  subscription_id:         ef9cbd96-c21e-4800-a898-fee8914dd532  # Production-Fabric
  region:                  westus3         # FortiGate NVA hub region (no Azure VPN Gateway)

  # PERMANENT - cannot be changed after creation
  collation:               SQL_Latin1_General_CP1_CI_AS
  timezone_id:             Central Standard Time
  dns_zone:                auto           # derived from instance name

  # adjustable online after creation
  service_tier:            GeneralPurpose        # next-gen General Purpose
  hardware_family:         PremiumSeries         # Intel Ice Lake
  vcores:                  10
  storage_size_gb:         1024
  iops_additional:         3000                  # -> ~6000 total incl. 3072 built-in
  memory_gb:               70                    # native at 7 GB/vCore, no slider needed
  backup_storage_redundancy: GeoRedundant
  license_type:            LicenseIncluded       # -> BasePrice if Azure Hybrid Benefit confirmed
  zone_redundant:          false                 # flexible memory is preview on zone-redundant

  # networking
  public_data_endpoint_enabled: false
  proxy_override:          Proxy                 # not Redirect - avoids 11000-11999 on clients
  minimal_tls_version:     "1.2"

  # identity
  administrator_login:     gbsqladmin            # vault password in gb-fabric-keyvault
  azure_ad_admin:
    login:                 GB_Azure_SQL_DBAs
    object_id:             09b353f7-3d55-4b51-9509-0b9dfdff9546
```

## Network

```yaml
network:
  vnet_resource_group:     rg-wus3-network
  vnet_name:               gbpartner-vnet-wus3-prod   # existing; peered to hub
  vnet_address_space:      10.3.0.0/20                # existing
  subnet_name:             snet-sqlmi-bmx
  subnet_prefix:           10.3.8.0/24                # /26 min; /24 recommended
  subnet_delegation:       Microsoft.Sql/managedInstances
  onprem_address_spaces:   [172.16.0.0/12, 10.10.0.0/16]  # from hub UDR evidence

route_table:
  name:                    rt-sqlmi-bmx-to-onprem
  routes:
    - name:                to-onprem-0
      address_prefix:      172.16.0.0/12
      next_hop_type:       VirtualAppliance
      next_hop_ip:         10.1.2.4          # GBPI-GBP-fgt01-nic2
    - name:                to-onprem-1
      address_prefix:      10.10.0.0/16
      next_hop_type:       VirtualAppliance
      next_hop_ip:         10.1.2.4

nsg_inbound:
  - name: allow-mi-link-mirroring
    port: 5022
    protocol: TCP
    source: onprem_address_spaces         # never Any
  - name: allow-sql
    port: 1433
    protocol: TCP
    source: onprem_address_spaces
  - name: allow-redirect-range
    port_range: 11000-11999
    protocol: TCP
    source: onprem_address_spaces

fortigate:
  azure_nva:               GBPI-GBP-fgt01
  hub_vnet:                gbpartner-vnethub-wus3
  internal_ip:             10.1.2.4
  inbound_from_mi_subnet:  [5022]
  outbound_to_mi_subnet:   [5022, 1433, 11000-11999]
  ipsec_phase2_rekey:      ALIGN_BOTH_FORTIGATES     # required - no Azure VPN Gateway
```
## Source server

```yaml
source:
  server:                  GBP-SQL03
  version:                 15.0.4460.4                  # SQL Server 2019
  edition:                 Enterprise Core-based
  collation:               SQL_Latin1_General_CP1_CI_AS

  databases:
    - name:                HBLive
      size_gb:             299.9
      recovery_model:      FULL
      compat_level:        140
      role:                published
      log_gb_per_day:      22.7
      avg_iops:            312
      in_scope:            true
    - name:                SPLive
      size_gb:             20.2
      recovery_model:      FULL
      compat_level:        140
      role:                published
      log_gb_per_day:      1.6
      avg_iops:            11
      in_scope:            true
    # BUILDPRO is NOT in scope. Constellation sources it from the vendor and replicates it
    # into the MI themselves. Listed for capacity awareness only - do not plan steps for it.
    - name:                BUILDPRO
      size_gb:             34.4
      in_scope:            false
      note:                >
        Vendor-sourced, replicated into the MI by Constellation. Its 34 GB is already
        included in storage_size_gb. Adds write volume to the instance once it lands.

  prerequisites:
    - database_master_key_in_master
    - always_on_availability_groups_enabled        # SERVICE RESTART REQUIRED
    - trace_flag_1800_startup_parameter            # same restart
    - backup_checksum_enabled
    - full_backup_taken_per_database
  powershell_modules:
    Az.Sql:                ">=3.9.0"
    Az.Accounts:           ">=2.8.0"
    SqlServer:             ">=21.1.18256"
  link_account_role:       SQL Managed Instance Contributor
```

## Index maintenance change

```yaml
index_maintenance:
  job:                     "GBP - Index Maintenance"
  server:                  GBP-SQL03
  change:                  split tier-1 step so synced databases use reorganize-only
  synced_databases:        [HBLive, SPLive]
  fragmentation_high_current: "INDEX_REBUILD_ONLINE,INDEX_REORGANIZE"
  fragmentation_high_target:  "INDEX_REORGANIZE"
  all_other_databases:     unchanged
  rationale:               >
    Index REBUILD is fully-logged and single-transaction. In a distributed AG the source log
    cannot truncate until the secondary catches up, so a large rebuild becomes one large log
    spike. Largest HBLive index is interfacelogl at 43 GB.
  measured_cost_of_change:
    hblive_rebuilds_30d:   8
    hblive_rebuild_minutes_30d: 0.2
    hblive_reorganizes_30d: 836
    splive_reorganizes_30d: 228
```

## Monitoring

```yaml
monitoring:
  source_side:
    - metric: log_space_used_percent
      databases: [HBLive, SPLive]
      alert: true
      rationale: distributed AG prevents log truncation when secondary lags
    - metric: log_reuse_wait_desc
      expect_when_lagging: AVAILABILITY_REPLICA
  mi_side:
    - redo_queue_length
    - cpu_percent
    - storage_space_used_mb
    - io_requests
    destination: Log Analytics
  maintenance_window:
    avoid: month_end_close
```

## Open items — block on these, do not default

```yaml
unresolved:
  - id: warehouse_size
    question: BMX warehouse 30-40% of source, or 2.3x?
    range_gb: [100, 600]
    affects: storage_size_gb
    blocking: false            # storage is adjustable online
    owner: Constellation
  - id: logging_tables_in_scope
    question: are interfacelogl (~65 GB) and eventlog (~8 GB) replicated?
    affects: [storage_size_gb, tunnel_volume]
    blocking: false
    owner: Constellation
  - id: azure_hybrid_benefit
    question: does GBP's SQL 2019 Enterprise core licensing entitle AHB?
    affects: license_type
    annual_impact_usd: ~10000
    blocking: false
    owner: GBP licensing
  - id: azure_region
    question: which region terminates corporate VPN?
    resolution: westus3 via FortiGate NVA GBPI-GBP-fgt01 (confirmed 2026-09-29)
    affects: everything
    blocking: false            # resolved by live discovery; pending human approval to apply
    owner: GBP
```