ALTER TABLE "Congregations" ADD COLUMN "SyncId" TEXT NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000';
ALTER TABLE "Congregations" ADD COLUMN "ServerVersion" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "Congregations" ADD COLUMN "DeletedAt" TEXT NULL;
UPDATE "Congregations" SET "SyncId" = lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(6))) WHERE "SyncId" = '00000000-0000-0000-0000-000000000000';
CREATE UNIQUE INDEX IF NOT EXISTS "IX_Congregations_SyncId" ON "Congregations" ("SyncId");

ALTER TABLE "FieldServiceGroups" ADD COLUMN "SyncId" TEXT NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000';
ALTER TABLE "FieldServiceGroups" ADD COLUMN "ServerVersion" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "FieldServiceGroups" ADD COLUMN "DeletedAt" TEXT NULL;
UPDATE "FieldServiceGroups" SET "SyncId" = lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(6))) WHERE "SyncId" = '00000000-0000-0000-0000-000000000000';
CREATE UNIQUE INDEX IF NOT EXISTS "IX_FieldServiceGroups_SyncId" ON "FieldServiceGroups" ("SyncId");

ALTER TABLE "Persons" ADD COLUMN "SyncId" TEXT NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000';
ALTER TABLE "Persons" ADD COLUMN "ServerVersion" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "Persons" ADD COLUMN "DeletedAt" TEXT NULL;
ALTER TABLE "Persons" ADD COLUMN "InactiveDate" TEXT NULL;
UPDATE "Persons" SET "SyncId" = lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(6))) WHERE "SyncId" = '00000000-0000-0000-0000-000000000000';
CREATE UNIQUE INDEX IF NOT EXISTS "IX_Persons_SyncId" ON "Persons" ("SyncId");

ALTER TABLE "PhoneNumbers" ADD COLUMN "SyncId" TEXT NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000';
ALTER TABLE "PhoneNumbers" ADD COLUMN "ServerVersion" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "PhoneNumbers" ADD COLUMN "DeletedAt" TEXT NULL;
UPDATE "PhoneNumbers" SET "SyncId" = lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(6))) WHERE "SyncId" = '00000000-0000-0000-0000-000000000000';
CREATE UNIQUE INDEX IF NOT EXISTS "IX_PhoneNumbers_SyncId" ON "PhoneNumbers" ("SyncId");

ALTER TABLE "EmergencyContacts" ADD COLUMN "SyncId" TEXT NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000';
ALTER TABLE "EmergencyContacts" ADD COLUMN "ServerVersion" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "EmergencyContacts" ADD COLUMN "DeletedAt" TEXT NULL;
UPDATE "EmergencyContacts" SET "SyncId" = lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(6))) WHERE "SyncId" = '00000000-0000-0000-0000-000000000000';
CREATE UNIQUE INDEX IF NOT EXISTS "IX_EmergencyContacts_SyncId" ON "EmergencyContacts" ("SyncId");

ALTER TABLE "ServiceReports" ADD COLUMN "SyncId" TEXT NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000';
ALTER TABLE "ServiceReports" ADD COLUMN "ServerVersion" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "ServiceReports" ADD COLUMN "DeletedAt" TEXT NULL;
ALTER TABLE "ServiceReports" ADD COLUMN "CreatedAt" TEXT NOT NULL DEFAULT '1970-01-01T00:00:00Z';
ALTER TABLE "ServiceReports" ADD COLUMN "ModifiedAt" TEXT NULL;
UPDATE "ServiceReports" SET "SyncId" = lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(6))) WHERE "SyncId" = '00000000-0000-0000-0000-000000000000';
CREATE UNIQUE INDEX IF NOT EXISTS "IX_ServiceReports_SyncId" ON "ServiceReports" ("SyncId");

ALTER TABLE "AuxiliaryPioneerPeriod" ADD COLUMN "SyncId" TEXT NOT NULL DEFAULT '00000000-0000-0000-0000-000000000000';
ALTER TABLE "AuxiliaryPioneerPeriod" ADD COLUMN "ServerVersion" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "AuxiliaryPioneerPeriod" ADD COLUMN "DeletedAt" TEXT NULL;
ALTER TABLE "AuxiliaryPioneerPeriod" ADD COLUMN "CreatedAt" TEXT NOT NULL DEFAULT '1970-01-01T00:00:00Z';
ALTER TABLE "AuxiliaryPioneerPeriod" ADD COLUMN "ModifiedAt" TEXT NULL;
UPDATE "AuxiliaryPioneerPeriod" SET "SyncId" = lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(2))) || '-' || lower(hex(randomblob(6))) WHERE "SyncId" = '00000000-0000-0000-0000-000000000000';
CREATE UNIQUE INDEX IF NOT EXISTS "IX_AuxiliaryPioneerPeriod_SyncId" ON "AuxiliaryPioneerPeriod" ("SyncId");
