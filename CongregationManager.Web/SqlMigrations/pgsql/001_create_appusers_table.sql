CREATE TABLE IF NOT EXISTS "Users" (
    "Id" SERIAL PRIMARY KEY,
    "Email" VARCHAR(254) NOT NULL,
    "DisplayName" VARCHAR(200) NOT NULL,
    "PasswordHash" TEXT NOT NULL,
    "Role" INTEGER NOT NULL DEFAULT 0,
    "IsActive" BOOLEAN NOT NULL DEFAULT true,
    "EmailConfirmed" BOOLEAN NOT NULL DEFAULT false,
    "IsMfaEnabled" BOOLEAN NOT NULL DEFAULT false,
    "TotpSecretKey" TEXT,
    "MfaRecoveryCodes" TEXT,
    "SecurityStamp" TEXT,
    "AccessFailedCount" INTEGER NOT NULL DEFAULT 0,
    "LockoutEnd" TIMESTAMPTZ,
    "LastLoginAt" TIMESTAMP,
    "PasswordChangedAt" TIMESTAMP,
    "EmailConfirmationToken" TEXT,
    "EmailConfirmationTokenExpiry" TIMESTAMP,
    "PasswordResetToken" TEXT,
    "PasswordResetTokenExpiry" TIMESTAMP,
    "CreatedAt" TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS "IX_Users_Email" ON "Users" ("Email");
