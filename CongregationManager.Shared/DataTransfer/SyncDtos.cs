using System.Text.Json;

namespace CongregationManager.DataTransfer;

public sealed record SyncPushRequest(
    string? DeviceId,
    IReadOnlyList<SyncOperationDto> Operations);

public sealed record SyncOperationDto(
    string OperationId,
    string EntityType,
    string EntitySyncId,
    string OperationType,
    long? BaseServerVersion,
    JsonElement Payload);

public sealed record SyncPushResponse(
    IReadOnlyList<AcceptedSyncOperationDto> AcceptedOperations,
    IReadOnlyList<SyncConflictDto> Conflicts);

public sealed record AcceptedSyncOperationDto(
    string OperationId,
    string EntityType,
    string EntitySyncId,
    long ServerVersion);

public sealed record SyncConflictDto(
    string OperationId,
    string EntityType,
    string EntitySyncId,
    long ServerVersion,
    JsonElement ServerPayload);

public sealed record SyncPullResponse(
    string Cursor,
    IReadOnlyList<SyncChangeDto> Changes);

public sealed record SyncChangeDto(
    string EntityType,
    string EntitySyncId,
    string OperationType,
    long ServerVersion,
    DateTime ModifiedAt,
    object Payload);
