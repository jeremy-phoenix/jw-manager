using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CongregationManager.Migrations
{
    /// <inheritdoc />
    public partial class AddPasswordResetAndEmailConfirmationTokens : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "EmailConfirmationToken",
                table: "AppUsers",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "EmailConfirmationTokenExpiry",
                table: "AppUsers",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "PasswordChangedAt",
                table: "AppUsers",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PasswordResetToken",
                table: "AppUsers",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "PasswordResetTokenExpiry",
                table: "AppUsers",
                type: "TEXT",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "EmailConfirmationToken",
                table: "AppUsers");

            migrationBuilder.DropColumn(
                name: "EmailConfirmationTokenExpiry",
                table: "AppUsers");

            migrationBuilder.DropColumn(
                name: "PasswordChangedAt",
                table: "AppUsers");

            migrationBuilder.DropColumn(
                name: "PasswordResetToken",
                table: "AppUsers");

            migrationBuilder.DropColumn(
                name: "PasswordResetTokenExpiry",
                table: "AppUsers");
        }
    }
}
