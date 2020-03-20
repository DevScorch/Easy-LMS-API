import Vapor
import Crypto

struct UserController: RouteCollection {
    func boot(router: Router) throws {
        
        let userRoute = router.grouped("spectre", "users")
        
        // DEVSCORCH: Authentication MiddleWare
        
        let basicAuthMiddleware = User.basicAuthMiddleware(using: BCryptDigest())
        let tokenAuthMiddleware = User.tokenAuthMiddleware()

        let guardAuthMiddleWare = User.guardAuthMiddleware()
        let basicAuthGroup = userRoute.grouped(basicAuthMiddleware)
        let tokenAuthGroup = userRoute.grouped(tokenAuthMiddleware, guardAuthMiddleWare)
        let authSessionRoutes = router.grouped(User.authSessionsMiddleware())


        let protected = userRoute.grouped(basicAuthMiddleware, guardAuthMiddleWare)
        
        // DEVSCORCH: User routes
        
        basicAuthGroup.post(User.self, use: createHandler)
        basicAuthGroup.post("login", use: loginHandler)
        tokenAuthGroup.get(User.parameter, use: getHandler)
        tokenAuthGroup.get(use: getAllHandler)
        basicAuthGroup.put(User.parameter, use: updateHandler)
        tokenAuthGroup.put(User.parameter, use: updateHandler)
        
    }
    
    
    // DEVSCORCH: User Create Handler
    
    func createHandler(_ req: Request, user: User) throws -> Future<User.Public> {
        user.password = try BCrypt.hash(user.password)
        return user.save(on: req).converttoPublic()
    }
    
    // DEVSCORCH: Get all Users handler
    
    func getAllHandler(_ req: Request) throws -> Future<[User.Public]> {
        return User.query(on: req).decode(data: User.Public.self).all()
    }
    
    // DEVSCORCH: Get user handler
    
    func getHandler(_ req: Request) throws -> Future<User.Public> {
        return try req.parameters.next(User.self).converttoPublic()
    }
    
    // DEVSCORCH: LoginHandler for Users
    
    func loginHandler(_ req: Request) throws -> Future<Token> {
        let user = try req.requireAuthenticated(User.self)
        let token = try Token.generate(for: user)
        try req.authenticateSession(user)
        return token.save(on: req)
    }
    
    // DEVSCORCH: Logout handler for Users
    
    func logoutHandler(_ req: Request) throws -> Response {
        try req.unauthenticateSession(User.self)
        return req.redirect(to: "https://devscorch.com")
    }
    
    // DEVSCORCH: Update handler for Users
    
    func updateHandler(_ req: Request) throws -> Future<User> {
        return try flatMap(to: User.self, req.parameters.next(User.self), req.content.decode(User.self)) {
                user, updatedUser in
            user.name = updatedUser.name
            user.lastName = updatedUser.lastName
            user.stripe_session_id = updatedUser.stripe_session_id
            
            return user.save(on: req)
        }
    }
}






