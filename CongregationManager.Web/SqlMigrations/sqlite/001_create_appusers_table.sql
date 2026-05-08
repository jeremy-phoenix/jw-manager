-- Create the AppUsers table with the full current schema.
-- Uses IF NOT EXISTS so it's safe to run on any database state.

CREATE TABLE IF NOT EXISTS "Users" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_AppUsers" PRIMARY KEY AUTOINCREMENT,
    "Email" TEXT NOT NULL,
    "DisplayName" TEXT NOT NULL,
    "PasswordHash" TEXT NOT NULL,
    "Role" INTEGER NOT NULL DEFAULT 0,
    "IsActive" INTEGER NOT NULL DEFAULT 1,
    "EmailConfirmed" INTEGER NOT NULL DEFAULT 0,
    "IsMfaEnabled" INTEGER NOT NULL DEFAULT 0,
    "TotpSecretKey" TEXT,
    "MfaRecoveryCodes" TEXT,
    "SecurityStamp" TEXT,
    "AccessFailedCount" INTEGER NOT NULL DEFAULT 0,
    "LockoutEnd" TEXT,
    "LastLoginAt" TEXT,
    "PasswordChangedAt" TEXT,
    "EmailConfirmationToken" TEXT,
    "EmailConfirmationTokenExpiry" TEXT,
    "PasswordResetToken" TEXT,
    "PasswordResetTokenExpiry" TEXT,
    "CreatedAt" TEXT NOT NULL DEFAULT '0001-01-01 00:00:00'
);

CREATE UNIQUE INDEX IF NOT EXISTS "IX_Users_Email" ON "Users" ("Email");
