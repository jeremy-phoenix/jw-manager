using System.ComponentModel.DataAnnotations;

namespace CongregationManager.Data.Models;

public class User
{
    [Key]
    public int Id { get; set; }

    [Required, MaxLength(254)]
    public string Email { get; set; } = string.Empty;

    [Required, MaxLength(200)]
    public string DisplayName { get; set; } = string.Empty;

    [Required]
    public string PasswordHash { get; set; } = string.Empty;

    public Components.UserRole Role { get; set; } = Components.UserRole.Viewer;

    public bool IsActive { get; set; } = true;

    public bool EmailConfirmed { get; set; }

    // MFA / TOTP
    public bool IsMfaEnabled { get; set; }

    public string? TotpSecretKey { get; set; }

    public string? MfaRecoveryCodes { get; set; }

    // Security
    public string? SecurityStamp { get; set; }

    public int AccessFailedCount { get; set; }

    public DateTimeOffset? LockoutEnd { get; set; }

    public DateTime? LastLoginAt { get; set; }

    public DateTime? PasswordChangedAt { get; set; }

    // Email confirmation
    public string? EmailConfirmationToken { get; set; }

    public DateTime? EmailConfirmationTokenExpiry { get; set; }

    // Password reset
    public string? PasswordResetToken { get; set; }

    public DateTime? PasswordResetTokenExpiry { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
