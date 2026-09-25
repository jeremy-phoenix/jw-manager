using System.Buffers.Text;
using System.Security.Cryptography;
using System.Text;

namespace CongregationManager.Server.Security;

/// <summary>
/// Random bearer secrets. Only their SHA-256 digests are persisted, so a
/// database leak does not reveal usable tokens or invite codes.
/// </summary>
internal static class SecretTokens
{
    public const int TokenBytes = 32;

    public static string Generate(int byteCount = TokenBytes) =>
        Base64Url.EncodeToString(RandomNumberGenerator.GetBytes(byteCount));

    public static byte[] Hash(string secret) => SHA256.HashData(Encoding.UTF8.GetBytes(secret));

    public static byte[] Hash(byte[] secret) => SHA256.HashData(secret);

    /// <summary>Base64url token characters only, within sane length bounds.</summary>
    public static bool LooksLikeToken(string value) =>
        value.Length is >= 16 and <= 128
        && value.All(character => char.IsAsciiLetterOrDigit(character) || character is '-' or '_');
}
