using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CongregationManager.Migrations
{
    /// <inheritdoc />
    public partial class RenameAppUserToUser_AddEmailAndMfa : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_AppUsers_Username",
                table: "AppUsers");

            migrationBuilder.RenameColumn(
                name: "Username",
                table: "AppUsers",
                newName: "Email");

            migrationBuilder.AlterColumn<string>(
                name: "Email",
                table: "AppUsers",
                type: "TEXT",
                maxLength: 254,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "TEXT",
                oldMaxLength: 100);

            migrationBuilder.AddColumn<int>(
                name: "AccessFailedCount",
                table: "AppUsers",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<bool>(
                name: "EmailConfirmed",
                table: "AppUsers",
                type: "INTEGER",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<bool>(
                name: "IsMfaEnabled",
                table: "AppUsers",
                type: "INTEGER",
                nullable: false,
                defaultValue: false);

            migrationBuilder.AddColumn<DateTime>(
                name: "LastLoginAt",
                table: "AppUsers",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "LockoutEnd",
                table: "AppUsers",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "MfaRecoveryCodes",
                table: "AppUsers",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "SecurityStamp",
                table: "AppUsers",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "TotpSecretKey",
                table: "AppUsers",
                type: "TEXT",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_AppUsers_Email",
                table: "AppUsers",
                column: "Email",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_AppUsers_Email",
                table: "AppUsers");

            migrationBuilder.DropColumn(
                name: "AccessFailedCount",
                table: "AppUsers");

            migrationBuilder.DropColumn(
                name: "EmailConfirmed",
                table: "AppUsers");

            migrationBuilder.DropColumn(
                name: "IsMfaEnabled",
                table: "AppUsers");

            migrationBuilder.DropColumn(
                name: "LastLoginAt",
                table: "AppUsers");

            migrationBuilder.DropColumn(
                name: "LockoutEnd",
                table: "AppUsers");

            migrationBuilder.DropColumn(
                name: "MfaRecoveryCodes",
                table: "AppUsers");

            migrationBuilder.DropColumn(
                name: "SecurityStamp",
                table: "AppUsers");

            migrationBuilder.DropColumn(
                name: "TotpSecretKey",
                table: "AppUsers");

            migrationBuilder.RenameColumn(
                name: "Email",
                table: "AppUsers",
                newName: "Username");

            migrationBuilder.AlterColumn<string>(
                name: "Username",
                table: "AppUsers",
                type: "TEXT",
                maxLength: 100,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "TEXT",
                oldMaxLength: 254);

            migrationBuilder.CreateIndex(
                name: "IX_AppUsers_Username",
                table: "AppUsers",
                column: "Username",
                unique: true);
        }
    }
}
