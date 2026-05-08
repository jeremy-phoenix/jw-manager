using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CongregationManager.Migrations
{
    /// <inheritdoc />
    public partial class AddAppUsers : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Persons_Congregations_CongregationId",
                table: "Persons");

            migrationBuilder.AddColumn<int>(
                name: "CongregationId",
                table: "FieldServiceGroups",
                type: "INTEGER",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "AppUsers",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    Username = table.Column<string>(type: "TEXT", maxLength: 100, nullable: false),
                    DisplayName = table.Column<string>(type: "TEXT", maxLength: 200, nullable: false),
                    PasswordHash = table.Column<string>(type: "TEXT", nullable: false),
                    Role = table.Column<int>(type: "INTEGER", nullable: false),
                    IsActive = table.Column<bool>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AppUsers", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_FieldServiceGroups_CongregationId",
                table: "FieldServiceGroups",
                column: "CongregationId");

            migrationBuilder.CreateIndex(
                name: "IX_AppUsers_Username",
                table: "AppUsers",
                column: "Username",
                unique: true);

            migrationBuilder.AddForeignKey(
                name: "FK_FieldServiceGroups_Congregations_CongregationId",
                table: "FieldServiceGroups",
                column: "CongregationId",
                principalTable: "Congregations",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);

            migrationBuilder.AddForeignKey(
                name: "FK_Persons_Congregations_CongregationId",
                table: "Persons",
                column: "CongregationId",
                principalTable: "Congregations",
                principalColumn: "Id",
                onDelete: ReferentialAction.Restrict);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_FieldServiceGroups_Congregations_CongregationId",
                table: "FieldServiceGroups");

            migrationBuilder.DropForeignKey(
                name: "FK_Persons_Congregations_CongregationId",
                table: "Persons");

            migrationBuilder.DropTable(
                name: "AppUsers");

            migrationBuilder.DropIndex(
                name: "IX_FieldServiceGroups_CongregationId",
                table: "FieldServiceGroups");

            migrationBuilder.DropColumn(
                name: "CongregationId",
                table: "FieldServiceGroups");

            migrationBuilder.AddForeignKey(
                name: "FK_Persons_Congregations_CongregationId",
                table: "Persons",
                column: "CongregationId",
                principalTable: "Congregations",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }
    }
}
