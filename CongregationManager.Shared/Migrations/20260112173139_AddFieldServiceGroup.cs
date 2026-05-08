using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CongregationManager.Migrations
{
    /// <inheritdoc />
    public partial class AddFieldServiceGroup : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Persons_FieldServiceGroup_FieldServiceGroupId",
                table: "Persons");

            migrationBuilder.DropPrimaryKey(
                name: "PK_FieldServiceGroup",
                table: "FieldServiceGroup");

            migrationBuilder.RenameTable(
                name: "FieldServiceGroup",
                newName: "FieldServiceGroups");

            migrationBuilder.AddPrimaryKey(
                name: "PK_FieldServiceGroups",
                table: "FieldServiceGroups",
                column: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Persons_FieldServiceGroups_FieldServiceGroupId",
                table: "Persons",
                column: "FieldServiceGroupId",
                principalTable: "FieldServiceGroups",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Persons_FieldServiceGroups_FieldServiceGroupId",
                table: "Persons");

            migrationBuilder.DropPrimaryKey(
                name: "PK_FieldServiceGroups",
                table: "FieldServiceGroups");

            migrationBuilder.RenameTable(
                name: "FieldServiceGroups",
                newName: "FieldServiceGroup");

            migrationBuilder.AddPrimaryKey(
                name: "PK_FieldServiceGroup",
                table: "FieldServiceGroup",
                column: "Id");

            migrationBuilder.AddForeignKey(
                name: "FK_Persons_FieldServiceGroup_FieldServiceGroupId",
                table: "Persons",
                column: "FieldServiceGroupId",
                principalTable: "FieldServiceGroup",
                principalColumn: "Id");
        }
    }
}
