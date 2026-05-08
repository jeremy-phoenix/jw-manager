using System.Security.Cryptography;

namespace CongregationManager.Utils;

/// <summary>
/// AES-256-GCM application-level encryption for sensitive database fields.
/// Encrypted values are prefixed with "ENC:" to distinguish from plaintext.
/// </summary>
public static class EncryptionProvider
{
    private const string EncryptedPrefix = "ENC:";
    private const int NonceSize = 12;  // AES-GCM standard
    private const int TagSize = 16;    // AES-GCM standard

    private static byte[]? _key;

    /// <summary>
    /// Initialize with a base64-encoded 256-bit key.
    /// Call once at application startup.
    /// </summary>
    public static void Initialize(string base64Key)
    {
        _key = Convert.FromBase64String(base64Key);
        if (_key.Length != 32)
            throw new ArgumentException("Encryption key must be 256 bits (32 bytes).");
    }

    /// <summary>
    /// Returns true if encryption has been configured.
    /// When false, values pass through unencrypted.
    /// </summary>
    public static bool IsEnabled => _key != null;

    /// <summary>
    /// Generates a new random 256-bit key as a base64 string.
    /// </summary>
    public static string GenerateKey()
    {
        var key = new byte[32];
        RandomNumberGenerator.Fill(key);
        return Convert.ToBase64String(key);
    }

    /// <summary>
    /// Encrypts a plaintext string. Returns prefixed base64 string.
    /// If encryption is not enabled, returns the plaintext as-is.
    /// </summary>
    public static string? Encrypt(string? plaintext)
    {
        if (string.IsNullOrEmpty(plaintext) || _key == null)
            return plaintext;

        var nonce = new byte[NonceSize];
        RandomNumberGenerator.Fill(nonce);

        var plaintextBytes = System.Text.Encoding.UTF8.GetBytes(plaintext);
        var ciphertext = new byte[plaintextBytes.Length];
        var tag = new byte[TagSize];

        using var aes = new AesGcm(_key, TagSize);
        aes.Encrypt(nonce, plaintextBytes, ciphertext, tag);

        // Format: nonce + ciphertext + tag
        var result = new byte[NonceSize + ciphertext.Length + TagSize];
        nonce.CopyTo(result, 0);
        ciphertext.CopyTo(result, NonceSize);
        tag.CopyTo(result, NonceSize + ciphertext.Length);

        return EncryptedPrefix + Convert.ToBase64String(result);
    }

    /// <summary>
    /// Decrypts an encrypted string. If the value is not prefixed (plaintext),
    /// returns it as-is for backwards compatibility with existing data.
    /// </summary>
    public static string? Decrypt(string? ciphertext)
    {
        if (string.IsNullOrEmpty(ciphertext) || _key == null)
            return ciphertext;

        // Not encrypted — return plaintext as-is (backwards compat)
        if (!ciphertext.StartsWith(EncryptedPrefix))
            return ciphertext;

        var payload = Convert.FromBase64String(ciphertext[EncryptedPrefix.Length..]);

        var nonce = payload[..NonceSize];
        var tag = payload[^TagSize..];
        var encrypted = payload[NonceSize..^TagSize];

        var plaintextBytes = new byte[encrypted.Length];

        using var aes = new AesGcm(_key, TagSize);
        aes.Decrypt(nonce, encrypted, tag, plaintextBytes);

        return System.Text.Encoding.UTF8.GetString(plaintextBytes);
    }
}
