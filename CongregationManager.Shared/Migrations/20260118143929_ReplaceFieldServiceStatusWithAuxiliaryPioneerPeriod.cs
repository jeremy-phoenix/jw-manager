using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CongregationManager.Migrations
{
    /// <inheritdoc />
    public partial class ReplaceFieldServiceStatusWithAuxiliaryPioneerPeriod : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ServicePeriods");

            migrationBuilder.DropColumn(
                name: "Status",
                table: "ServiceReports");

            migrationBuilder.DropColumn(
                name: "FieldServiceStatus",
                table: "Persons");

            migrationBuilder.CreateTable(
                name: "AuxiliaryPioneerPeriod",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    PersonId = table.Column<int>(type: "INTEGER", nullable: false),
                    StartMonth = table.Column<int>(type: "INTEGER", nullable: false),
                    StartYear = table.Column<int>(type: "INTEGER", nullable: false),
                    EndMonth = table.Column<int>(type: "INTEGER", nullable: true),
                    EndYear = table.Column<int>(type: "INTEGER", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AuxiliaryPioneerPeriod", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AuxiliaryPioneerPeriod_Persons_PersonId",
                        column: x => x.PersonId,
                        principalTable: "Persons",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_AuxiliaryPioneerPeriod_PersonId",
                table: "AuxiliaryPioneerPeriod",
                column: "PersonId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AuxiliaryPioneerPeriod");

            migrationBuilder.AddColumn<int>(
                name: "Status",
                table: "ServiceReports",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "FieldServiceStatus",
                table: "Persons",
                type: "INTEGER",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateTable(
                name: "ServicePeriods",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    IsCurrent = table.Column<bool>(type: "INTEGER", nullable: false),
                    Month = table.Column<int>(type: "INTEGER", nullable: false),
                    Year = table.Column<int>(type: "INTEGER", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ServicePeriods", x => x.Id);
                });
        }
    }
}
