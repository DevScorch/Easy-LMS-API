import FluentPostgreSQL
import Vapor
import Authentication
import Leaf
import Stripe
import Foundation
import SendGrid


/// Called before your application initializes.
public func configure(_ config: inout Config, _ env: inout Environment, _ services: inout Services) throws {
 
    // DEVSCORCH: Providers
    
    try services.register(FluentPostgreSQLProvider())
    try services.register(AuthenticationProvider())
    try services.register(LeafProvider())
    try services.register(StripeProvider())
    try services.register(SendGridProvider())
    
    // DEVSCORCH: Stripe payment Setup
    
    let stripeConfig = StripeConfig(apiKey: "pk_test_idQdSbPCsJVm6hnWsRNrEYej")
    services.register(stripeConfig)
    
    // DEVSCORCH: RouterSetup
    
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)
    
    // DEVSCORCH Middleware
    
    var middlewares = MiddlewareConfig()
    
    // DEVSCORCH: CORS MiddleWare
    
     let corsConfiguration = CORSMiddleware.Configuration(allowedOrigin: .all, allowedMethods: [.POST, .GET, .PUT, .OPTIONS, .DELETE, .PATCH], allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin])
    let corsMiddleWare = CORSMiddleware(configuration: corsConfiguration)
    
    middlewares.use(corsMiddleWare)
    middlewares.use(ErrorMiddleware.self)
    middlewares.use(SessionsMiddleware.self)
    middlewares.use(FileMiddleware.self)
    services.register(middlewares)
    
    // DEVSCORCH: Database Configuration
    
    var databases = DatabasesConfig()
    let databaseConfig = PostgreSQLDatabaseConfig(
    
        hostname: "127.0.0.1",
        username: "vapor",
        database: "postgres",
        password: "password"
    )
    
    let database = PostgreSQLDatabase(config: databaseConfig)
    databases.add(database: database, as: .psql)
    
    services.register(databases)
    
    // DEVSCORCH: Migration Configuration
    
    var migrations = MigrationConfig()
    migrations.add(model: User.self, database: .psql)
    migrations.add(model: Token.self, database: .psql)
    migrations.add(model: Admin.self, database: .psql)
    migrations.add(model: AdminToken.self, database: .psql)
    migrations.add(model: Courses.self, database: .psql)
    migrations.add(model: CourseCategory.self, database: .psql)
    migrations.add(model: CourseCategoryPivot.self, database: .psql)
    migrations.add(model: Subscription.self, database: .psql)
    migrations.add(model: CourseSection.self, database: .psql)
    migrations.add(model: Download.self, database: .psql)
    migrations.add(model: VideoModel.self, database: .psql)
    migrations.add(model: ResetPasswordToken.self, database: .psql)
    migrations.add(model: BlogCategoryModel.self, database: .psql)
    migrations.add(model: BlogPostModel.self, database: .psql)
    migrations.add(model: BlogCategoryPivot.self, database: .psql)
    
    services.register(migrations)
    
    // Caching Configuration
    
    config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)
    
    // DEVSCORCH: LEAF Render
    
    config.prefer(LeafRenderer.self, for: ViewRenderer.self)
    
    // DEVSCORCH: SendGrid
   // let SENDGRID_API_KEY = "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"
    
    guard let sendGridAPIKey = Environment.get("sendGridAPIKey") else {
         fatalError("No API KEY Specified")
    }
    let sendGridConfig = SendGridConfig(apiKey: sendGridAPIKey)
    services.register(sendGridConfig)
    
    
}
