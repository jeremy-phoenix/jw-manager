namespace CongregationManager.Server.Features;

// byte[] members travel as standard base64 strings. Every byte[] the server
// receives is opaque ciphertext or a digest produced by the client.

public sealed record CreateVaultRequest(
    Guid VaultId,
    Guid DeviceId,
    int KeyId,
    byte[] RecoveryAuthHash,
    byte[] RecoveryEnvelope);

public sealed record EnrollWithInviteRequest(string InviteCode, Guid DeviceId);

public sealed record EnrollWithRecoveryRequest(byte[] RecoveryAuthKey, Guid DeviceId);

public sealed record EnrollmentResponse(
    Guid VaultId,
    Guid DeviceId,
    string DeviceToken,
    int CurrentKeyId,
    byte[]? RecoveryEnvelope);

public sealed record VaultResponse(
    Guid VaultId,
    int CurrentKeyId,
    long Seq,
    byte[] RecoveryEnvelope,
    DateTimeOffset CreatedAt,
    DateTimeOffset? KeyRotatedAt);

public sealed record RecoveryProofRequest(byte[] RecoveryAuthKey);

public sealed record DeviceResponse(
    Guid DeviceId,
    byte[]? Label,
    int? LabelKeyId,
    string EnrolledVia,
    DateTimeOffset CreatedAt,
    DateTimeOffset LastSeenAt,
    bool Current);

public sealed record DeviceListResponse(IReadOnlyList<DeviceResponse> Devices);

public sealed record SetDeviceLabelRequest(byte[] Label, int KeyId);

public sealed record CreateInviteRequest(int? ExpiresInMinutes = null);

public sealed record CreateInviteResponse(string InviteCode, DateTimeOffset ExpiresAt);

public sealed record PushOperation(
    Guid OperationId,
    Guid RecordId,
    long BaseVersion,
    bool Deleted,
    int KeyId,
    byte[] Ciphertext);

public sealed record PushRequest(IReadOnlyList<PushOperation> Operations);

public sealed record AcceptedOperation(Guid OperationId, Guid RecordId, long Version, long Seq);

/// <summary>
/// The server's current state of a record the client tried to change from a
/// stale version. Version 0 with no ciphertext means the server has no record.
/// </summary>
public sealed record ConflictedOperation(
    Guid OperationId,
    Guid RecordId,
    long Version,
    bool Deleted,
    int? KeyId,
    byte[]? Ciphertext);

public sealed record PushResponse(
    IReadOnlyList<AcceptedOperation> Accepted,
    IReadOnlyList<ConflictedOperation> Conflicts);

public sealed record RecordChange(
    Guid RecordId,
    long Version,
    long Seq,
    bool Deleted,
    int KeyId,
    byte[] Ciphertext);

public sealed record PullResponse(
    IReadOnlyList<RecordChange> Changes,
    long NextSince,
    bool HasMore,
    int CurrentKeyId);

public sealed record RotateKeyRequest(
    byte[] RecoveryAuthKey,
    int NewKeyId,
    byte[] RecoveryEnvelope,
    byte[]? NewRecoveryAuthHash = null);

public sealed record RotateKeyResponse(int CurrentKeyId);

public sealed record StaleRecord(Guid RecordId, long Version, int KeyId, byte[] Ciphertext);

public sealed record StaleRecordsResponse(IReadOnlyList<StaleRecord> Records, int CurrentKeyId);

public sealed record RekeyRecord(Guid RecordId, long Version, int KeyId, byte[] Ciphertext);

public sealed record RekeyRequest(IReadOnlyList<RekeyRecord> Records);

public sealed record RekeyResponse(int Updated, IReadOnlyList<Guid> Skipped);

public sealed record HealthResponse(string Status);
