-- Use in CB
create database link link.backup connect to
CBB identified by dummy using 'xe'; -- Change xe to final database handle added in TNSNAME.ORA

-- Use in CBB
create database link link.backup connect to
CB identified by dummy using 'xe'; -- Change xe to final database handle added in TNSNAME.ORA

# tnsnames.ora Network Configuration File:

CB =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = localhost.localdomain)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = XE)
    )
  )

CBB =
  (DESCRIPTION =
    (ADDRESS = (PROTOCOL = TCP)(HOST = localhost.localdomain)(PORT = 1521))
    (CONNECT_DATA =
      (SERVER = DEDICATED)
      (SERVICE_NAME = XE)
    )
  )
