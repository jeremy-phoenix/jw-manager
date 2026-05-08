using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CongregationManager.Migrations
{
    /// <inheritdoc />
    public partial class RefactorEntityModels : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Create new tables first
            migrationBuilder.CreateTable(
                name: "PhoneNumbers",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    Number = table.Column<string>(type: "TEXT", nullable: false),
                    PhoneType = table.Column<int>(type: "INTEGER", nullable: false),
                    IsPrimary = table.Column<bool>(type: "INTEGER", nullable: false),
                    PersonId = table.Column<int>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    ModifiedAt = table.Column<DateTime>(type: "TEXT", nullable: true),
                    CreatedBy = table.Column<string>(type: "TEXT", nullable: true),
                    ModifiedBy = table.Column<string>(type: "TEXT", nullable: true),
                    Status = table.Column<int>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_PhoneNumbers", x => x.Id);
                    table.ForeignKey(
                        name: "FK_PhoneNumbers_Persons_PersonId",
                        column: x => x.PersonId,
                        principalTable: "Persons",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "EmergencyContacts",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    Name = table.Column<string>(type: "TEXT", nullable: false),
                    PhoneNumber = table.Column<string>(type: "TEXT", nullable: true),
                    Relationship = table.Column<int>(type: "INTEGER", nullable: false),
                    IsPrimary = table.Column<bool>(type: "INTEGER", nullable: false),
                    PersonId = table.Column<int>(type: "INTEGER", nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    ModifiedAt = table.Column<DateTime>(type: "TEXT", nullable: true),
                    CreatedBy = table.Column<string>(type: "TEXT", nullable: true),
                    ModifiedBy = table.Column<string>(type: "TEXT", nullable: true),
                    Status = table.Column<int>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_EmergencyContacts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_EmergencyContacts_Persons_PersonId",
                        column: x => x.PersonId,
                        principalTable: "Persons",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "FieldServiceGroup",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    Name = table.Column<string>(type: "TEXT", nullable: false),
                    Description = table.Column<string>(type: "TEXT", nullable: true),
                    Latitude = table.Column<double>(type: "REAL", nullable: true),
                    Longitude = table.Column<double>(type: "REAL", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    ModifiedAt = table.Column<DateTime>(type: "TEXT", nullable: true),
                    CreatedBy = table.Column<string>(type: "TEXT", nullable: true),
                    ModifiedBy = table.Column<string>(type: "TEXT", nullable: true),
                    Status = table.Column<int>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_FieldServiceGroup", x => x.Id);
                });

            // Migrate existing data to new tables
            migrationBuilder.Sql(@"
                INSERT INTO PhoneNumbers (Number, PhoneType, IsPrimary, PersonId, Status, CreatedAt)
                SELECT PhoneNumber, 0, 1, Id, 0, datetime('now')
                FROM Persons
                WHERE PhoneNumber IS NOT NULL AND PhoneNumber != '';
            ");

            migrationBuilder.Sql(@"
                INSERT INTO EmergencyContacts (Name, Relationship, IsPrimary, PersonId, Status, CreatedAt)
                SELECT EmergencyContact, 7, 1, Id, 0, datetime('now')
                FROM Persons
                WHERE EmergencyContact IS NOT NULL AND EmergencyContact != '';
            ");

            // Drop old columns from Persons
            migrationBuilder.DropColumn(name: "PhoneNumber", table: "Persons");
            migrationBuilder.DropColumn(name: "EmergencyContact", table: "Persons");
            migrationBuilder.DropColumn(name: "IsDeleted", table: "Persons");

            // Add new BaseEntity columns to Persons
            migrationBuilder.AddColumn<DateTime>(
                name: "CreatedAt",
                table: "Persons",
                type: "TEXT",
                nullable: false,
                defaultValue: new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc));

            migrationBuilder.AddColumn<string>(
                name: "CreatedBy",
                table: "Persons",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "ModifiedAt",
                table: "Persons",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ModifiedBy",
                table: "Persons",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "Status",
                table: "Persons",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "FieldServiceGroupId",
                table: "Persons",
                type: "INTEGER",
                nullable: true);

            // Create indexes
            migrationBuilder.CreateIndex(
                name: "IX_Persons_FieldServiceGroupId",
                table: "Persons",
                column: "FieldServiceGroupId");

            migrationBuilder.CreateIndex(
                name: "IX_EmergencyContacts_PersonId",
                table: "EmergencyContacts",
                column: "PersonId");

            migrationBuilder.CreateIndex(
                name: "IX_PhoneNumbers_PersonId",
                table: "PhoneNumbers",
                column: "PersonId");

            migrationBuilder.AddForeignKey(
                name: "FK_Persons_FieldServiceGroup_FieldServiceGroupId",
                table: "Persons",
                column: "FieldServiceGroupId",
                principalTable: "FieldServiceGroup",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Persons_FieldServiceGroup_FieldServiceGroupId",
                table: "Persons");

            migrationBuilder.DropTable(name: "EmergencyContacts");
            migrationBuilder.DropTable(name: "FieldServiceGroup");
            migrationBuilder.DropTable(name: "PhoneNumbers");

            migrationBuilder.DropIndex(
                name: "IX_Persons_FieldServiceGroupId",
                table: "Persons");

            migrationBuilder.DropColumn(name: "CreatedAt", table: "Persons");
            migrationBuilder.DropColumn(name: "CreatedBy", table: "Persons");
            migrationBuilder.DropColumn(name: "ModifiedAt", table: "Persons");
            migrationBuilder.DropColumn(name: "ModifiedBy", table: "Persons");
            migrationBuilder.DropColumn(name: "Status", table: "Persons");
            migrationBuilder.DropColumn(name: "FieldServiceGroupId", table: "Persons");

            migrationBuilder.AddColumn<string>(
                name: "PhoneNumber",
                table: "Persons",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "EmergencyContact",
                table: "Persons",
                type: "TEXT",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "IsDeleted",
                table: "Persons",
                type: "INTEGER",
                nullable: false,
                defaultValue: false);
        }
    }
}