

-- ================ CUSTOMERS USERS

truncate customer;
INSERT INTO customer (customerUUID,customer_name) VALUES (1,'Chicken Customer');

truncate user_group;
INSERT INTO user_group (groupUUID,group_customerUUID,group_name) VALUES (1,1,'Maintenance Group 1');
INSERT INTO user_group (groupUUID,group_customerUUID,group_name) VALUES (2,1,'Maintenance Group 2');
INSERT INTO user_group (groupUUID,group_customerUUID,group_name) VALUES (3,1,'Maintenance Group 3');

truncate user;
INSERT INTO user (userUUID,user_customerUUID,user_userName) VALUES (1,1,'Tom Gentry');
INSERT INTO user (userUUID,user_customerUUID,user_userName) VALUES (2,1,'Sam Smith');
INSERT INTO user (userUUID,user_customerUUID,user_userName) VALUES (3,1,'Susan Rice');	

truncate user_group_join;
INSERT INTO  user_group_join (ugj_groupUUID,ugj_userUUID) VALUES (1,1);
INSERT INTO  user_group_join (ugj_groupUUID,ugj_userUUID) VALUES (2,2);
INSERT INTO  user_group_join (ugj_groupUUID,ugj_userUUID) VALUES (3,2);
INSERT INTO  user_group_join (ugj_groupUUID,ugj_userUUID) VALUES (3,3);

truncate user_profile;
INSERT INTO user_profile (user_profileId,userUUID,user_preferenceJSON) VALUES (1,1,'{language: "en",units: "celcius"}');
INSERT INTO user_profile (user_profileId,userUUID,user_preferenceJSON) VALUES (2,2,'{language: "fr",units: "celcius"}');
INSERT INTO user_profile (user_profileId,userUUID,user_preferenceJSON) VALUES (3,3,'{language: "es",units: "celcius"}');

-- ================ ASSETS
truncate location;
insert into location (locationUUID,location_customerUUID,location_type,location_name,location_hotSpotJSON,location_imageUrl)
values (1,1,'SITE','Main Hatchery','{hotspots:[ {shape:"rect",coords:"0,0,82,126",alt:"area1",type:"location",forward:"2"},{shape:"circle",coords:"90,58,3",alt:"area2",type:"location",forward:"3"} ]}','http://');
insert into location (locationUUID,location_customerUUID,location_type,location_name,location_hotSpotJSON,location_imageUrl)
values (2,1,'FLOOR','South Hallway','{hotspots:[ {shape:"rect",coords:"0,0,82,126",alt:"area1",type:"location",forward:"4"} ]}','http://');
insert into location (locationUUID,location_customerUUID,location_type,location_name,location_hotSpotJSON,location_imageUrl)
values (3,1,'ROOM','Hatch Room','{hotspots:[ {shape:"rect",coords:"0,0,82,126",alt:"area1",type:"purchase",forward:"CART"} ]}','http://');
insert into location (locationUUID,location_customerUUID,location_type,location_name,location_hotSpotJSON,location_imageUrl)
values (4,1,'ROOM','Incubator Room','{hotspots:[ {shape:"rect",coords:"0,0,82,126",alt:"area1",type:"purchase",forward:"CART"} ]}','http://');

truncate asset;
insert into asset (assetUUID,asset_customerUUID,asset_locationUUID,asset_partUUID,asset_name)
values (1,1,1,3,'Fan Assembly #1');
insert into asset (assetUUID,asset_customerUUID,asset_locationUUID,asset_partUUID,asset_name)
values (2,1,1,3,'Fan Assembly #2');

truncate asset_part;
insert into asset_part (asset_partUUID,asset_part_template_part_sku,asset_part_customerUUID,asset_part_name,asset_part_diagnosticUUID)
values (1,1,1,'Avida Symphone A18',1);
insert into asset_part (asset_partUUID,asset_part_template_part_sku,asset_part_customerUUID,asset_part_name,asset_part_diagnosticUUID)
values (2,2,1,'Electrical Assembly',1);
insert into asset_part (asset_partUUID,asset_part_template_part_sku,asset_part_customerUUID,asset_part_name,asset_part_diagnosticUUID)
values (3,3,1,'Fan Assembly',1);

truncate asset_part_join;
insert into asset_part_join(apj_parent_asset_partUUID,apj_child_asset_partUUID) values (1,2);
insert into asset_part_join(apj_parent_asset_partUUID,apj_child_asset_partUUID) values (1,3);
