namespace CongregationManager.Server.Infrastructure.Database;

// Timestamps are Unix epoch milliseconds: they order and compare the same way
// in SQLite and PostgreSQL without provider-specific date handling.

/// <summary>
/// One end-to-end encrypted data space. The server never sees the vault key;
/// it only stores an envelope that is encrypted with a key derived from the
/// user's recovery code.
/// </summary>
public sealed class Vault
{
    public Guid Id { get; set; }

    public long CreatedAtMs { get; set; }

    /// <summary>Last sequence number handed out to a record change.</summary>
    public long Seq { get; set; }

    public int CurrentKeyId { get; set; }

    /// <summary>SHA-256 of the key the client derives from the recovery code.</summary>
    public byte[] RecoveryAuthHash { get; set; } = [];

    /// <summary>Opaque: the current vault key wrapped by the recovery code.</summary>
    public byte[] RecoveryEnvelope { get; set; } = [];

    public long? KeyRotatedAtMs { get; set; }
}

public sealed class Device
{
    public Guid Id { get; set; }

    public Guid VaultId { get; set; }

    /// <summary>SHA-256 of the bearer token; the token itself is never stored.</summary>
    public byte[] TokenHash { get; set; } = [];

    /// <summary>Opaque: the device name encrypted with the vault key.</summary>
    public byte[]? Label { get; set; }

    public int? LabelKeyId { get; set; }

    public string EnrolledVia { get; set; } = "";

    public long CreatedAtMs { get; set; }

    public long LastSeenAtMs { get; set; }

    public long? RevokedAtMs { get; set; }
}

public static class EnrollmentMethods
{
    public const string VaultCreation = "create";
    public const string Invite = "invite";
    public const string Recovery = "recovery";
}

public sealed class Invite
{
    public Guid Id { get; set; }

    public Guid VaultId { get; set; }

    /// <summary>SHA-256 of the one-time enrollment code.</summary>
    public byte[] CodeHash { get; set; } = [];

    public Guid CreatedByDeviceId { get; set; }

    public long CreatedAtMs { get; set; }

    public long ExpiresAtMs { get; set; }

    public long? UsedAtMs { get; set; }

    public Guid? UsedByDeviceId { get; set; }
}

/// <summary>
/// The latest ciphertext of one client record. The payload, including which
/// kind of entity it is, only exists inside <see cref="Ciphertext"/>.
/// </summary>
public sealed class SyncRecord
{
    public Guid VaultId { get; set; }

    public Guid RecordId { get; set; }

    public long Version { get; set; }

    /// <summary>Position in the vault's change feed; unique per vault.</summary>
    public long Seq { get; set; }

    public int KeyId { get; set; }

    public bool Deleted { get; set; }

    public byte[] Ciphertext { get; set; } = [];

    public long UpdatedAtMs { get; set; }

    public Guid UpdatedByDeviceId { get; set; }
}

/// <summary>Remembers applied push operations so client retries are idempotent.</summary>
public sealed class AppliedOperation
{
    public Guid VaultId { get; set; }

    public Guid OperationId { get; set; }

    public Guid RecordId { get; set; }

    public long ResultVersion { get; set; }

    public long ResultSeq { get; set; }

    public long AppliedAtMs { get; set; }
}

public sealed class SchemaInfo
{
    public int Id { get; set; }

    public int Version { get; set; }
}
