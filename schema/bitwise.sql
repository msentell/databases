TRUNCATE jcmi_hms.privilege_bitwise;
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('ACCT_CREATEBRAND', 'ACCT', 2199023255552, 'ACCT-Can create brands');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('ACCT_CREATECUSTOMER', 'ACCT', 4398046511104, 'ACCT-Can create customers');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('ACCT_CREATEUSERS', 'ACCT', 549755813888, 'ACCT-Can create users');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('ACCT_UPDATEUSERS', 'ACCT', 1099511627776, 'ACCT-Can update users');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('ACCT_UPDATESECURITY', 'ACCT', 8796093022208, 'ACCT-Can update secuirty');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('APP_LOGIN', 'APP', 1, 'ADMIN-Can login');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('APP_SUPERUSER', 'APP', 2, 'ADMIN-Has JCMI Super User Rights');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('CL_CREATE', 'CL', 4096, 'CHECKLIST-Can create checklists');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('CL_DELETE', 'CL', 16384, 'CHECKLIST-Can delete checklists');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('CL_READ', 'CL', 2048, 'CHECKLIST-Can read checklists');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('CL_UPDATE', 'CL', 8192, 'CHECKLIST-Can edit checklists');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('CLT_CREATE', 'CLT', 1048576, 'CHECKLIST TEMPLATE-Can create checklist templates');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('CLT_DELETE', 'CLT', 4194304, 'CHECKLIST TEMPLATE-Can delete checklist templates');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('CLT_READ', 'CLT', 524288, 'CHECKLIST TEMPLATE-Can read checklist templates');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('CLT_UPDATE', 'CLT', 2097152, 'CHECKLIST TEMPLATE-Can update checklist templates');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('DIAG_CREATE', 'DIAG', 36028797018964000, 'DIAGNOSTICS-Can create diagnostics');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('DIAG_DELETE', 'DIAG', 144115188075856000, 'DIAGNOSTICS-Can create diagnostics');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('DIAG_READ', 'DIAG', 18014398509482000, 'DIAGNOSTICS-Can create diagnostics');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('DIAG_UPDATE', 'DIAG', 72057594037927900, 'DIAGNOSTICS-Can create diagnostics');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('GRP_CREATE', 'GRP', 35184372088832, 'GROUP-Can create groups');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('GRP_DELETE', 'GRP', 70368744177664, 'GROUP-Can delete groups');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('GRP_UPDATE', 'GRP', 140737488355328, 'GROUP-Can update groups');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('KB_CREATE', 'KB', 8589934592, 'KB-Can create articles');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('KB_DELETE', 'KB', 34359738368, 'KB-Can delete articles');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('KB_READ', 'KB', 4294967296, 'KB-Can read articles');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('KB_UPDATE', 'KB', 17179869184, 'KB-Can update articles');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('MAESTRO_CONTROL', 'MAESTRO', 134217728, 'MAESTRO-Can control Maestro');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('MAESTRO_READ', 'MAESTRO', 67108864, 'MAESTRO-Can view Maestro');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('SEARCH_SEARCH', 'SEARCH', 8, 'SEARCH-Can Search');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('WO_ASSIGN', 'WO', 256, 'WORKORDER-Can assign workorders');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('WO_CREATE', 'WO', 32, 'WORKORDER-Can create workorders');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('WO_DELETE', 'WO', 128, 'WORKORDER-Can delete workorders');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('WO_READ', 'WO', 16, 'WORKORDER-Can read workorders');
INSERT INTO jcmi_hms.privilege_bitwise (privilege_key, privilege_category, privilege_bitWise, privilege_description) VALUES ('WO_UPDATE', 'WO', 64, 'WORKORDER-Can update workorders');
