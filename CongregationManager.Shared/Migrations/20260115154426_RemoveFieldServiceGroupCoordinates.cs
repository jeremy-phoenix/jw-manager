using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CongregationManager.Migrations
{
    /// <inheritdoc />
    public partial class RemoveFieldServiceGroupCoordinates : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Latitude",
                table: "FieldServiceGroups");

            migrationBuilder.DropColumn(
                name: "Longitude",
                table: "FieldServiceGroups");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<double>(
                name: "Latitude",
                table: "FieldServiceGroups",
                type: "REAL",
                nullable: true);

            migrationBuilder.AddColumn<double>(
                name: "Longitude",
                table: "FieldServiceGroups",
                type: "REAL",
                nullable: true);
        }
    }
}
