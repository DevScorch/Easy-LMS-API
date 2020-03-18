import Foundation
import Vapor
import FluentPostgreSQL

final class BlogPostModel: Codable {
    
    // DEVSCORCH: Blog variables
    
    var id: UUID?
    var blogTitle: String
    var publicationDate: String
    var writer: String
    var tags: String?
    var publication: String
    var introText: String
    
    // DEVSCORCH: Blog intro variables
    
    var categoryID: BlogCategoryModel.ID
    var introImage: String
    
    init(blogTitle: String, publicationDate: String, writer: String, tags: String, publication: String, categoryID: BlogCategoryModel.ID, introImage: String, introText: String) {
        self.blogTitle = blogTitle
        self.publication = publicationDate
        self.writer = writer
        self.tags = tags
        self.categoryID = categoryID
        self.introImage = introImage
        self.publicationDate = publicationDate
        self.introText = introText
    }
    
}

extension BlogPostModel {
    var category: Parent<BlogPostModel, BlogCategoryModel> {
        return parent(\.categoryID)
    }
}

extension BlogPostModel: PostgreSQLUUIDModel {
    
}

extension BlogPostModel: Migration {
    static func prepare(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return Database.create(self, on: connection) { builder in
            try addProperties(to: builder)
            builder.reference(from: \.categoryID, to: \BlogCategoryModel.id)
        }
    }
    
}

extension BlogPostModel: Content {}

extension BlogPostModel: Parameter {}
