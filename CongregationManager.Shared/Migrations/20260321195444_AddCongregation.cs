using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CongregationManager.Migrations
{
    /// <inheritdoc />
    public partial class AddCongregation : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "CongregationId",
                table: "Persons",
                type: "INTEGER",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "Congregations",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    Name = table.Column<string>(type: "TEXT", nullable: false),
                    Number = table.Column<string>(type: "TEXT", nullable: true),
                    City = table.Column<string>(type: "TEXT", nullable: true),
                    CircuitNumber = table.Column<string>(type: "TEXT", nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    ModifiedAt = table.Column<DateTime>(type: "TEXT", nullable: true),
                    CreatedBy = table.Column<string>(type: "TEXT", nullable: true),
                    ModifiedBy = table.Column<string>(type: "TEXT", nullable: true),
                    Status = table.Column<int>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Congregations", x => x.Id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_Persons_CongregationId",
                table: "Persons",
                column: "CongregationId");

            migrationBuilder.AddForeignKey(
                name: "FK_Persons_Congregations_CongregationId",
                table: "Persons",
                column: "CongregationId",
                principalTable: "Congregations",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Persons_Congregations_CongregationId",
                table: "Persons");

            migrationBuilder.DropTable(
                name: "Congregations");

            migrationBuilder.DropIndex(
                name: "IX_Persons_CongregationId",
                table: "Persons");

            migrationBuilder.DropColumn(
                name: "CongregationId",
                table: "Persons");
        }
    }
}
