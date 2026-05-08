using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace CongregationManager.Migrations
{
    /// <inheritdoc />
    public partial class AddGroupOverseerAndAssistantToFieldServiceGroup : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Persons_FieldServiceGroups_FieldServiceGroupId",
                table: "Persons");

            migrationBuilder.AddColumn<int>(
                name: "AssistantId",
                table: "FieldServiceGroups",
                type: "INTEGER",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "GroupOverseerId",
                table: "FieldServiceGroups",
                type: "INTEGER",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_FieldServiceGroups_AssistantId",
                table: "FieldServiceGroups",
                column: "AssistantId");

            migrationBuilder.CreateIndex(
                name: "IX_FieldServiceGroups_GroupOverseerId",
                table: "FieldServiceGroups",
                column: "GroupOverseerId");

            migrationBuilder.AddForeignKey(
                name: "FK_FieldServiceGroups_Persons_AssistantId",
                table: "FieldServiceGroups",
                column: "AssistantId",
                principalTable: "Persons",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_FieldServiceGroups_Persons_GroupOverseerId",
                table: "FieldServiceGroups",
                column: "GroupOverseerId",
                principalTable: "Persons",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Persons_FieldServiceGroups_FieldServiceGroupId",
                table: "Persons",
                column: "FieldServiceGroupId",
                principalTable: "FieldServiceGroups",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_FieldServiceGroups_Persons_AssistantId",
                table: "FieldServiceGroups");

            migrationBuilder.DropForeignKey(
                name: "FK_FieldServiceGroups_Persons_GroupOverseerId",
                table: "FieldServiceGroups");

            migrationBuilder.DropForeignKey(
                name: "FK_Persons_FieldServiceGroups_FieldServiceGroupId",
                table: "Persons");

            migrationBuilder.DropIndex(
                name: "IX_FieldServiceGroups_AssistantId",
                table: "FieldServiceGroups");

            migrationBuilder.DropIndex(
                name: "IX_FieldServiceGroups_GroupOverseerId",
                table: "FieldServiceGroups");

            migrationBuilder.DropColumn(
                name: "AssistantId",
                table: "FieldServiceGroups");

            migrationBuilder.DropColumn(
                name: "GroupOverseerId",
                table: "FieldServiceGroups");

            migrationBuilder.AddForeignKey(
                name: "FK_Persons_FieldServiceGroups_FieldServiceGroupId",
                table: "Persons",
                column: "FieldServiceGroupId",
                principalTable: "FieldServiceGroups",
                principalColumn: "Id");
        }
    }
}
