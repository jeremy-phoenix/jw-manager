using Microsoft.EntityFrameworkCore.Storage.ValueConversion;

namespace CongregationManager.Utils;

/// <summary>
/// EF Core value converter that transparently encrypts/decrypts string properties.
/// </summary>
public class EncryptedStringConverter : ValueConverter<string, string>
{
    public EncryptedStringConverter()
        : base(
            v => EncryptionProvider.Encrypt(v)!,
            v => EncryptionProvider.Decrypt(v)!)
    {
    }
}

/// <summary>
/// EF Core value converter for nullable string properties.
/// </summary>
public class NullableEncryptedStringConverter : ValueConverter<string?, string?>
{
    public NullableEncryptedStringConverter()
        : base(
            v => EncryptionProvider.Encrypt(v),
            v => EncryptionProvider.Decrypt(v))
    {
    }
}
