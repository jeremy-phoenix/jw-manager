CREATE EXTENSION IF NOT EXISTS pgcrypto;

ALTER TABLE "Congregations" ADD COLUMN IF NOT EXISTS "SyncId" uuid NOT NULL DEFAULT gen_random_uuid();
ALTER TABLE "Congregations" ADD COLUMN IF NOT EXISTS "ServerVersion" bigint NOT NULL DEFAULT 0;
ALTER TABLE "Congregations" ADD COLUMN IF NOT EXISTS "DeletedAt" timestamp with time zone NULL;
CREATE UNIQUE INDEX IF NOT EXISTS "IX_Congregations_SyncId" ON "Congregations" ("SyncId");

ALTER TABLE "FieldServiceGroups" ADD COLUMN IF NOT EXISTS "SyncId" uuid NOT NULL DEFAULT gen_random_uuid();
ALTER TABLE "FieldServiceGroups" ADD COLUMN IF NOT EXISTS "ServerVersion" bigint NOT NULL DEFAULT 0;
ALTER TABLE "FieldServiceGroups" ADD COLUMN IF NOT EXISTS "DeletedAt" timestamp with time zone NULL;
CREATE UNIQUE INDEX IF NOT EXISTS "IX_FieldServiceGroups_SyncId" ON "FieldServiceGroups" ("SyncId");

ALTER TABLE "Persons" ADD COLUMN IF NOT EXISTS "SyncId" uuid NOT NULL DEFAULT gen_random_uuid();
ALTER TABLE "Persons" ADD COLUMN IF NOT EXISTS "ServerVersion" bigint NOT NULL DEFAULT 0;
ALTER TABLE "Persons" ADD COLUMN IF NOT EXISTS "DeletedAt" timestamp with time zone NULL;
ALTER TABLE "Persons" ADD COLUMN IF NOT EXISTS "InactiveDate" timestamp with time zone NULL;
CREATE UNIQUE INDEX IF NOT EXISTS "IX_Persons_SyncId" ON "Persons" ("SyncId");

ALTER TABLE "PhoneNumbers" ADD COLUMN IF NOT EXISTS "SyncId" uuid NOT NULL DEFAULT gen_random_uuid();
ALTER TABLE "PhoneNumbers" ADD COLUMN IF NOT EXISTS "ServerVersion" bigint NOT NULL DEFAULT 0;
ALTER TABLE "PhoneNumbers" ADD COLUMN IF NOT EXISTS "DeletedAt" timestamp with time zone NULL;
CREATE UNIQUE INDEX IF NOT EXISTS "IX_PhoneNumbers_SyncId" ON "PhoneNumbers" ("SyncId");

ALTER TABLE "EmergencyContacts" ADD COLUMN IF NOT EXISTS "SyncId" uuid NOT NULL DEFAULT gen_random_uuid();
ALTER TABLE "EmergencyContacts" ADD COLUMN IF NOT EXISTS "ServerVersion" bigint NOT NULL DEFAULT 0;
ALTER TABLE "EmergencyContacts" ADD COLUMN IF NOT EXISTS "DeletedAt" timestamp with time zone NULL;
CREATE UNIQUE INDEX IF NOT EXISTS "IX_EmergencyContacts_SyncId" ON "EmergencyContacts" ("SyncId");

ALTER TABLE "ServiceReports" ADD COLUMN IF NOT EXISTS "SyncId" uuid NOT NULL DEFAULT gen_random_uuid();
ALTER TABLE "ServiceReports" ADD COLUMN IF NOT EXISTS "ServerVersion" bigint NOT NULL DEFAULT 0;
ALTER TABLE "ServiceReports" ADD COLUMN IF NOT EXISTS "DeletedAt" timestamp with time zone NULL;
ALTER TABLE "ServiceReports" ADD COLUMN IF NOT EXISTS "CreatedAt" timestamp with time zone NOT NULL DEFAULT now();
ALTER TABLE "ServiceReports" ADD COLUMN IF NOT EXISTS "ModifiedAt" timestamp with time zone NULL;
CREATE UNIQUE INDEX IF NOT EXISTS "IX_ServiceReports_SyncId" ON "ServiceReports" ("SyncId");

ALTER TABLE "AuxiliaryPioneerPeriod" ADD COLUMN IF NOT EXISTS "SyncId" uuid NOT NULL DEFAULT gen_random_uuid();
ALTER TABLE "AuxiliaryPioneerPeriod" ADD COLUMN IF NOT EXISTS "ServerVersion" bigint NOT NULL DEFAULT 0;
ALTER TABLE "AuxiliaryPioneerPeriod" ADD COLUMN IF NOT EXISTS "DeletedAt" timestamp with time zone NULL;
ALTER TABLE "AuxiliaryPioneerPeriod" ADD COLUMN IF NOT EXISTS "CreatedAt" timestamp with time zone NOT NULL DEFAULT now();
ALTER TABLE "AuxiliaryPioneerPeriod" ADD COLUMN IF NOT EXISTS "ModifiedAt" timestamp with time zone NULL;
CREATE UNIQUE INDEX IF NOT EXISTS "IX_AuxiliaryPioneerPeriod_SyncId" ON "AuxiliaryPioneerPeriod" ("SyncId");
