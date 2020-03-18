import Vapor
import FluentPostgreSQL

final class BlogCategoryModel: Codable {
    
    // DEVSCORCH: Blog variable
    
    var id: UUID?
    var name: String
    
    init(name: String) {
        self.name = name
    }
}

extension BlogCategoryModel: PostgreSQLUUIDModel {}
extension BlogCategoryModel: Content {}
extension BlogCategoryModel: Migration {}
extension BlogCategoryModel: Parameter {}

extension BlogCategoryModel {
    var blogPostModel: Children<BlogCategoryModel, BlogPostModel> {
        return children(\.categoryID)
    }
}

