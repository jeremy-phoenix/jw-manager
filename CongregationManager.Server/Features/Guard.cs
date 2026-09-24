using System.Security.Cryptography;
using CongregationManager.Server.Infrastructure.Database;
using CongregationManager.Server.Security;
using CongregationManager.Server.Web;

namespace CongregationManager.Server.Features;

internal static class Guard
{
    public const int DigestBytes = 32;
    public const int RecoveryAuthKeyBytes = 32;
    public const int MaxEnvelopeBytes = 1024;
    public const int MaxLabelBytes = 1024;

    public static void RequireId(Guid value, string name)
    {
        if (value == Guid.Empty)
        {
            throw ApiException.BadRequest($"{name} is required.");
        }
    }

    public static void RequireKeyId(int keyId, string name = "keyId")
    {
        if (keyId < 1)
        {
            throw ApiException.BadRequest($"{name} must be a positive integer.");
        }
    }

    public static byte[] RequireBytes(byte[]? value, string name, int maxLength)
    {
        if (value is null || value.Length == 0)
        {
            throw ApiException.BadRequest($"{name} is required.");
        }

        if (value.Length > maxLength)
        {
            throw ApiException.BadRequest($"{name} must be at most {maxLength} bytes.");
        }

        return value;
    }

    public static byte[] RequireExactLength(byte[]? value, string name, int length)
    {
        if (value is null || value.Length != length)
        {
            throw ApiException.BadRequest($"{name} must be exactly {length} bytes.");
        }

        return value;
    }

    /// <summary>
    /// Checks proof that the caller knows the vault's recovery code. The
    /// comparison is constant-time.
    /// </summary>
    public static void RequireRecoveryProof(Vault vault, byte[]? recoveryAuthKey)
    {
        var key = RequireExactLength(recoveryAuthKey, "recoveryAuthKey", RecoveryAuthKeyBytes);
        if (!CryptographicOperations.FixedTimeEquals(SecretTokens.Hash(key), vault.RecoveryAuthHash))
        {
            throw ApiException.Forbidden("INVALID_RECOVERY_KEY", "The recovery code is incorrect.");
        }
    }
}
