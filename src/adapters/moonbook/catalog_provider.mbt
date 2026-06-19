///|
pub struct MoonbookCatalogProvider {
  catalog : Array[BookCatalogEntry]
} derive(Debug, Eq)

///|
pub fn MoonbookCatalogProvider::new(
  catalog : Array[BookCatalogEntry],
) -> MoonbookCatalogProvider {
  { catalog, }
}

///|
pub fn MoonbookCatalogProvider::book_refs(
  self : MoonbookCatalogProvider,
) -> Array[@core.BookRef] {
  catalog_to_book_refs(self.catalog)
}

///|
pub impl @core.BookProvider for MoonbookCatalogProvider with fn books(
  self : MoonbookCatalogProvider,
) -> Array[@core.BookRef] {
  self.book_refs()
}
