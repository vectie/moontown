///|
async fn write_wenyu_build_skills(
  root : String,
  entry : @moonbook.BookCatalogEntry,
) -> Unit {
  @support.write_text_file(
    "\{root}/skills/wenyu-build/SKILL.md",
    @book_templates.wenyu_build_skill_text(entry),
  )
  @support.write_text_file(
    "\{root}/skills/wenyu-code-patch/SKILL.md",
    @book_templates.wenyu_code_patch_skill_text(entry),
  )
  @support.write_text_file(
    "\{root}/skills/wenyu-asset-pack/SKILL.md",
    @book_templates.wenyu_asset_pack_skill_text(entry),
  )
}
