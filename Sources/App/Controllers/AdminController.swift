import Vapor
import Crypto
import Authentication



struct AdminController: RouteCollection {
    func boot(router: Router) throws {
        
        // DEVSCORCH: Admin Route
        
        
        // DEVSCORCH: AuthMiddleWare
        
        let basicAuthMiddleWare = Admin.basicAuthMiddleware(using: BCryptDigest())
        let guardAuthMiddleWare = Admin.guardAuthMiddleware()
        let tokenAuthMiddleware = Admin.tokenAuthMiddleware()

        let basicAuthGroup = adminRoute.grouped(basicAuthMiddleWare)
        let tokenAuthGroup = adminRoute.grouped(tokenAuthMiddleware, guardAuthMiddleWare)
        
        basicAuthGroup.post(Admin.self, use: createAdminHandler)
        basicAuthGroup.post("login", use: loginHandler)

        
    }
    
     // DEVSCORCH: Create AdminHandler
    
    func createAdminHandler(_ req: Request, admin: Admin) throws -> Future<Admin.Public> {
        admin.password = try BCrypt.hash(admin.password)
        return admin.save(on: req).convertToPublic()
    }
    
    // DEVSCORCH: Get AdminHandler

    func getAdminHandler(_ req: Request) throws -> Future<Admin.Public> {
        return try req.parameters.next(Admin.self).convertToPublic()
    }

    // DEVSCORCH: Login AdminHandler
    
    func loginHandler(_ req: Request) throws -> Future<AdminToken> {
        let admin = try req.requireAuthenticated(Admin.self)
        let token = try AdminToken.generate(for: admin)
        try req.authenticateSession(admin)
        return token.save(on: req)
    }
    
    
}
