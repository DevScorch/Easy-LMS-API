import Vapor
import Leaf
import Authentication
import Crypto
import Stripe
import Fluent
import SendGrid
import Imperial

struct WebsiteController: RouteCollection {
    
    let imageFolder = "ProfilePictures/"
    
    func boot(router: Router) throws {
        
        // DEVSCORCH: Authentication MiddleWare
        let authSessionRoutes = router.grouped(User.authSessionsMiddleware())
        let protectedRoute = authSessionRoutes.grouped(RedirectMiddleware<User>(path: "/login"))
        
        authSessionRoutes.get(use: indexHandler)
        authSessionRoutes.get("courses", use: getAllCategoriesHandler)
        authSessionRoutes.get("subscriptions", use: getSubscriptionHandler)
        authSessionRoutes.get("downloads", use: getDownloadHandler)
        authSessionRoutes.get("courses", Courses.parameter, use: courseInformationHandler)
        authSessionRoutes.get("category", BlogCategoryModel.parameter, use: blogCategoryHandler)
        authSessionRoutes.get("category", "blog", BlogPostModel.parameter,  use: blogPostHandler)
        
        authSessionRoutes.get("freelance", use: serviceHandler)
        authSessionRoutes.get("company", use: CompanyHandler)
        
        authSessionRoutes.get("login", use: loginHandler)
        authSessionRoutes.post(LoginPostData.self, at: "login", use: loginPostHandler)
        authSessionRoutes.get("register", use: registerHandler)
        authSessionRoutes.post(RegisterPostData.self, at: "register", use: registerPostHandler)
        authSessionRoutes.post("logout", use: logoutHandler)
        authSessionRoutes.get("forgotPassword", use: forgotPasswordHandler)
        authSessionRoutes.post("forgotPassword", use: forgotPasswordPostHandler)
        authSessionRoutes.get("resetPassword", use: resetPasswordHandler)
        authSessionRoutes.post(ResetPasswordData.self, at: "resetPassword", use: resetPasswordPostHandler)
        
        
        protectedRoute.get("sections", CourseSection.parameter, use: courseSectionVideoPlayer)

        
        protectedRoute.get("profile", User.parameter, use: profilehandler)
        protectedRoute.post("profile", User.parameter, use: updateUserHandler)
        protectedRoute.post("profile", User.parameter, "userimage", use: updateUserProfileImage)
        protectedRoute.get("profile", User.parameter, "userimage", use: updateUserProfilePictureHandler)
        protectedRoute.get("profile", User.parameter, "mysubscription", use: mySubscriptionHandler)

        protectedRoute.get("subscribe", User.parameter, use: checkOutHandler)
        protectedRoute.post("sections", CourseSection.parameter, use: courseSectionFinishedPostHandler)
        
        
        authSessionRoutes.get("users", User.parameter, "userImage", use: getUsersProfilePictureHandler)
        
        
    }
    
    // DEVSCORCH: IndexHandler
    
    func indexHandler(_ req: Request) throws -> Future<View> {
        let userLoggedIn = try req.isAuthenticated(User.self)
        let loggedInUser = try req.authenticated(User.self)
        let blogCategory = BlogCategoryModel.query(on: req).all()
        let showCookieMessage = req.http.cookies["cookies-accepted"] == nil
        let context = IndexContext(blogcategories: blogCategory, title: "Homepage", loggedInUser: loggedInUser, userLoggedIn: userLoggedIn, cookieMessage: showCookieMessage)
        print("\(context)")
        print(blogCategory)
            return try req.view().render("index", context)
        }
    
    
    // DEVSCORCH: Course CategoryHandler
    
    func getAllCategoriesHandler(_ req: Request) throws -> Future<View> {
        let blogCategory = BlogCategoryModel.query(on: req).all()
        let userLoggedIn = try req.isAuthenticated(User.self)
        let loggedInUser = try req.authenticated(User.self)
        let courses = Courses.query(on: req).all()
        let context = CourseContext(blogcategories: blogCategory, userLoggedIn: userLoggedIn, loggedInUser: loggedInUser, courses: courses)
        return try req.view().render("courses", context)
    }
    
    // DEVSCORCH: Course informationHandler
    
    func courseInformationHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(Courses.self).flatMap(to: View.self) { course in
            let userLoggedIn = try req.isAuthenticated(User.self)
            let loggedInUser = try req.authenticated(User.self)
            let sections = try course.section.query(on: req).all()
            let blogCategory = BlogCategoryModel.query(on: req).all()
            
            let context = CourseInformationContext(blogcategories: blogCategory, userLoggedIn: userLoggedIn, loggedInUser: loggedInUser, title: course.courseName,courseName: course.courseName, courseDescription: course.courseDescription, instructor: course.instructor, sections: course.sections, lectures: course.lectures, publishDate: course.publishDate, difficulty: course.difficulty, courseDuration: course.courseDuration, beginURL: course.beginURL, courses: course, section: sections, forWhoName: course.forWhoName, forWhoText: course.forWhoText, introVideo: course.introVideo, lastupdatedDate: course.lastUpdatedDate)
            return try req.view().render("courseinformation", context)
        }
    }
    
    func courseSectionVideoPlayer(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(CourseSection.self).flatMap(to: View.self) { section in
            let userLoggedIn = try req.isAuthenticated(User.self)
            let loggedInUser = try req.authenticated(User.self)
            let videos = try section.videos.query(on: req).all()
            let blogCategory = BlogCategoryModel.query(on: req).all()
        
            let context = courseSectionVideoPlayerContext(blogcategories: blogCategory, userLoggedIn: userLoggedIn, loggedInUser: loggedInUser, sections: section, sectionName: section.sectionName, videos: videos, title: "Devscorch | Player enviroment")
            
            if loggedInUser?.subscriptionIsActive == true {
                return try req.view().render("videoplayer", context)

            } else {
                return try req.view().render("error")
            }
        }
    
    }
    
    func courseSectionFinishedPostHandler(_ req: Request) throws -> Future<User> {
         return try flatMap(to: User.self, req.parameters.next(User.self), req.content.decode(CourseSectionFinishedContext.self)) {
                       user, updatedUser in
            
            user.sectionFinished = updatedUser.finishedSection
            return user.save(on: req)
            
        }
    }

    // DEVSCORCH: Subscription Handler
    
    func getSubscriptionHandler(_ req: Request) throws -> Future<View> {
        let userLoggedIn = try req.isAuthenticated(User.self)
        let loggedInUser = try req.authenticated(User.self)
        let subscriptions = Subscription.query(on: req).all()
        let blogCategory = BlogCategoryModel.query(on: req).all()
        
        
        let context = SubscriptionContext(blogcategories: blogCategory, loggedInUser: loggedInUser, userLoggedIn: userLoggedIn, subscription: subscriptions)
        return try req.view().render("subscription", context)
    }
    
    // DEVSCORCH: Downloads Handler
    
    func getDownloadHandler(_ req: Request) throws -> Future<View> {
        let userLoggedIn = try req.isAuthenticated(User.self)
        let loggedInUser = try req.authenticated(User.self)
        let downloads = Download.query(on: req).all()
        let blogCategory = BlogCategoryModel.query(on: req).all()
        let context = DownloadContext( blogcategories: blogCategory, loggedInUser: loggedInUser, userLoggedIn: userLoggedIn, downloads: downloads)
        return try req.view().render("downloads", context)
    }
    
    // DEVSCORCH: Blog Category Controller
    
    func blogCategoryHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(BlogCategoryModel.self).flatMap(to: View.self) { category in
            let userLoggedIn = try req.isAuthenticated(User.self)
            let loggedInUser = try req.authenticated(User.self)
            let blogCategory = BlogCategoryModel.query(on: req).all()
            let blogPosts = try category.blogPostModel.query(on: req).all()
            let context = BlogCategoryContext(blogcategories: blogCategory, categoryID: category.id!, blog: blogPosts, categories: category, loggedInUser: loggedInUser, userLoggedIn: userLoggedIn, categoryName: category.name)
            print("\(context.blog)")
            
            return try req.view().render("category", context)
            
        }
    }
    
    func blogPostHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(BlogPostModel.self).flatMap(to: View.self) { blogpost in
            let userLoggedIn = try req.isAuthenticated(User.self)
            let loggedInUser = try req.authenticated(User.self)
            let blogCategory = BlogCategoryModel.query(on: req).all()

            
            let context = BlogPostContext(blogcategories: blogCategory, userLoggedIn: userLoggedIn, loggedInUser: loggedInUser, blogTitle: blogpost.blogTitle, publicationDate: blogpost.publicationDate, writer: blogpost.writer, tags: blogpost.tags!, publication: blogpost.publication, introImage: blogpost.introImage)
            
            return try req.view().render("publication", context)
        }
    }
    
    
    
    // DEVSCORCH: LoginHandler
    
    func loginHandler(_ req: Request) throws -> Future<View> {
        let context: LoginContext
        if req.query[Bool.self, at: "error"] != nil {
            context = LoginContext(loginError: true)
        } else {
            context = LoginContext()
        }
        return try req.view().render("login", context)
    }
    
    // DEVSCORCH: Login handler function
    
    func loginPostHandler(_ req: Request, userData: LoginPostData) throws -> Future<Response> {
        return User.authenticate(username: userData.username, password: userData.password, using: BCryptDigest(), on: req).map(to: Response.self) { user  in
            guard let user = user else {
                return req.redirect(to: "/login?error")
            }
            print("\(user) is logged in")
            try req.authenticateSession(user)
            return req.redirect(to: "/")
        }
    }
    
    // DEVSCORCH: Register Handler
    
    func registerHandler(_ req: Request) throws -> Future<View> {
        let context: RegisterContext
        if let message = req.query[String.self, at: "message"] {
            context = RegisterContext(message: message)
        } else {
            context = RegisterContext()
        }
        return try req.view().render("register", context)
    }
    
    func registerPostHandler(_ req: Request, data: RegisterPostData) throws -> Future<Response> {
        do {
            try data.validate()
        } catch (let error) {
            let redirect: String
            if let error = error as? ValidationError,
                let message = error.reason.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                redirect = "/register?message=\(message)"
            } else {
                redirect = "/register?message=Unknown+error"
            }
            return req.future(req.redirect(to: redirect))
        }
        let username = data.username
        let password = try BCrypt.hash(data.password)
        let email = data.email
        let user = User(
            name: nil,
            lastName: nil,
            dateOfBirth: nil,
            userImage: nil,
            email: email,
            userDescription: nil,
            specialty: nil,
            username: username,
            password: password,
            videoWatched: nil,
            coursesFollowed: nil,
            stripeID: nil,
            subscription: nil,
            subscriptionIsActive: false,
            dateJoined: Date(),
            stripe_session_id: "",
            sectionFinished: [""]
            
        )
        return user.save(on: req).map(to: Response.self) { user in
            try req.authenticateSession(user)
            print("user is saved")
            return req.redirect(to: "/")
        }
        
    }
    
    // DEVSCORCH: Logout Handler
    
    func logoutHandler(_ req: Request) throws -> Response {
        try req.unauthenticateSession(User.self)
        print("user is logged out")
        return req.redirect(to: "/")
    }
    
    // DEVSCORCH: UserSubscriptionHandler
    
    func subscribeHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(User.self).flatMap(to: View.self) { user in
            let userLoggedIn = try req.isAuthenticated(User.self)
            let loggedInUser = try req.authenticated(User.self)
            let isSubscribed = loggedInUser?.subscriptionIsActive
            let blogCategory = BlogCategoryModel.query(on: req).all()
            let context = UserSubscriptionContext(blogcategories: blogCategory, title: user.username, loggedInUser: loggedInUser, userLoggedIn: userLoggedIn, user: user, isSubscribed: isSubscribed)
            return try req.view().render("subscribe", context)
        }
    }
    
    // DEVSCORCH: User ProfileHandler
    
    func profilehandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(User.self).flatMap(to: View.self) { user in
            let userLoggedIn = try req.isAuthenticated(User.self)
            let loggedInUser = try req.authenticated(User.self)
            let blogCategory = BlogCategoryModel.query(on: req).all()
            let context = ProfileContext(blogcategories: blogCategory, loggedInUser: loggedInUser, userLoggedIn: userLoggedIn, id: user.id, title: user.username, username: user.username, name: user.name, lastName: user.lastName, dateOfBirth: user.dateOfBirth, userImage: user.userImage, email: user.email, userDescription: user.userDescription, specialty: user.specialty, user: user, subscription: user.subscriptionIsActive)
            return try req.view().render("profile", context)
        }
    }
    
    // DEVSCORCH: User updateHandler
    
    func updateUserHandler(_ req: Request) throws -> Future<Response> {
        return try flatMap(to: Response.self, req.parameters.next(User.self), req.content.decode(UpdateProfileContext.self)) { user, data in
            user.name = data.name
            user.lastName = data.lastName
            user.email = data.email
            user.dateOfBirth = data.dateOfBirth
            user.userDescription = data.userDescription
            user.sectionFinished = data.sectionFinished
            
            return user.save(on: req).map(to: Response.self) { savedUser in
                guard let id = savedUser.id else {
                    throw Abort(.internalServerError)
                }
                print("update successfull 2")
                return req.redirect(to: "/profile/\(id)")
            }
        }
    }
    
    // DEVSCORCH: User image Updater
    
    func updateUserProfilePictureHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(User.self).flatMap(to: View.self) { user in
        let userLoggedIn = try req.isAuthenticated(User.self)
        let loggedInUser = try req.authenticated(User.self)
            let blogCategory = BlogCategoryModel.query(on: req).all()
            let context = ProfileContext(blogcategories: blogCategory, loggedInUser: loggedInUser, userLoggedIn: userLoggedIn, id: user.id, title: user.username, username: user.username, name: user.name, lastName: user.lastName, dateOfBirth: user.dateOfBirth, userImage: user.userImage, email: user.email, userDescription: user.userDescription, specialty: user.specialty, user: user, subscription: user.subscriptionIsActive)
        return try req.view().render("userimage", context)
        }
    }
    
    func updateUserProfileImage(_ req: Request) throws -> Future<Response> {
        return try flatMap(to: Response.self, req.parameters.next(User.self), req.content.decode(ImageUploadData.self)) { user, imageData in
            let workPath = try req.make(DirectoryConfig.self).workDir
            let name = try "\(user.requireID())-\(UUID().uuidString).jpg"
            let path = workPath + self.imageFolder + name
            FileManager().createFile(atPath: path, contents: imageData.picture, attributes: nil)
            user.userImage = name
            let redirect =  try req.redirect(to: "/profile/\(user.requireID())")
            return user.save(on: req).transform(to: redirect)
        }
    }
    
    func getUsersProfilePictureHandler(_ req: Request) throws -> Future<Response> {
        return try req.parameters.next(User.self).flatMap(to: Response.self) { user in
            guard let filename = user.userImage else {
                throw Abort(.notFound)
            }
            let path = try req.make(DirectoryConfig.self).workDir + self.imageFolder + filename
            return try req.streamFile(at: path)
        }
    }
    
    // DEVSCORCH: My SubscriptionHandler
    
    func mySubscriptionHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(User.self).flatMap(to: View.self) { user in
        let userLoggedIn = try req.isAuthenticated(User.self)
        let loggedInUser = try req.authenticated(User.self)
            let blogCategory = BlogCategoryModel.query(on: req).all()
            let context = ProfileContext(blogcategories: blogCategory, loggedInUser: loggedInUser, userLoggedIn: userLoggedIn, id: user.id, title: user.username, username: user.username, name: user.name, lastName: user.lastName, dateOfBirth: user.dateOfBirth, userImage: user.userImage, email: user.email, userDescription: user.userDescription, specialty: user.specialty, user: user, subscription: user.subscriptionIsActive)
        return try req.view().render("mysubscription", context)
        }
    }
    
    // DEVSCHORCH: Forgot password Handler
    
    func forgotPasswordHandler(_ req: Request) throws -> Future<View> {
        return try req.view().render("forgotPassword", ["title": "Reset your Password"])
    }
    
   func forgotPasswordPostHandler(_ req: Request) throws -> Future<View> {
      let email = try req.content.syncGet(String.self, at: "email")
      return User.query(on: req).filter(\.email == email).first().flatMap(to: View.self) { user in
        guard let user = user else {
          return try req.view().render("forgotPasswordConfirmed", ["title": "Password Reset Email Sent"])
        }

        let resetTokenString = try CryptoRandom().generateData(count: 32).base32EncodedString()
        let resetToken = try ResetPasswordToken(token: resetTokenString, userID: user.requireID())
        return resetToken.save(on: req).flatMap(to: View.self) { _ in
          let emailContent = """
          <p>You've requested to reset your password. <a href=\"http://localhost:8080/resetPassword?token=\(resetTokenString)\">Click here</a> to reset your password.</p>
          """
          let emailAddress = EmailAddress(email: user.email, name: user.name)
          let fromEmail = EmailAddress(email: "noreply@devscorch.com", name: "Devscorch")
          let emailConfig = Personalization(to: [emailAddress], subject: "Change Your Password")
          let email = SendGridEmail(personalizations: [emailConfig], from: fromEmail, content: [["type": "text/html",
                                                                                                 "value": emailContent]])
          let sendGridClient = try req.make(SendGridClient.self)
          return try sendGridClient.send([email], on: req.eventLoop).flatMap(to: View.self) { _ in
            return try req.view().render("forgotPasswordConfirmed", ["title": "Password Reset Email Sent"])
          }
        }
      }
    }
    
    func resetPasswordHandler(_ req: Request) throws -> Future<View> {
         guard let token = req.query[String.self, at: "token"] else {
           return try req.view().render("resetPassword", ResetPasswordContext(error: true))
         }
         return ResetPasswordToken.query(on: req).filter(\.token == token).first().map(to: ResetPasswordToken.self) { token in
           guard let token = token else {
             throw Abort.redirect(to: "/")
           }
           return token
         }.flatMap { token in
           return token.user.get(on: req).flatMap { user in
             try req.session().set("ResetPasswordUser", to: user)
             return token.delete(on: req)
           }
         }.flatMap {
           try req.view().render("resetPassword", ResetPasswordContext())
         }
    }
    
    func resetPasswordPostHandler(_ req: Request, data: ResetPasswordData) throws -> Future<Response> {
            guard data.password == data.confirmPassword else {
              return try req.view().render(
                "resetPassword",
                ResetPasswordContext(error: true))
                .encode(for: req)
            }
            let resetPasswordUser = try req.session()
              .get("ResetPasswordUser", as: User.self)
            try req.session()["ResetPasswordUser"] = nil
            let newPassword = try BCrypt.hash(data.password)
            resetPasswordUser.password = newPassword
            return resetPasswordUser
              .save(on: req)
              .transform(to: req.redirect(to: "/login"))

    }
    
    // DEVSCORCH: Checkout Page
    
    func checkOutHandler(_ req: Request) throws -> Future<View> {
        return try req.parameters.next(User.self).flatMap(to: View.self) { user in
            let userLoggedIn = try req.isAuthenticated(User.self)
            let loggedInUser = try req.authenticated(User.self)
            let isSubscribed = loggedInUser?.subscriptionIsActive
            let blogCategory = BlogCategoryModel.query(on: req).all()
            let context = UserSubscriptionContext(blogcategories: blogCategory, title: user.username, loggedInUser: loggedInUser, userLoggedIn: userLoggedIn, user: user, isSubscribed: isSubscribed)
            return try req.view().render("subscribe", context)
        }
        
    }
    
    // DEVSCORCH: Freelance Page handlers
    
    func serviceHandler(_ req: Request) throws -> Future<View> {
        let userLoggedIn = try req.isAuthenticated(User.self)
        let loggedInUser = try req.authenticated(User.self)
        let blogCategory = BlogCategoryModel.query(on: req).all()
        let context = FreelanceContext(blogcategories: blogCategory, loggedInUser: loggedInUser, userLoggedIn: userLoggedIn, title: "Freelance ")
        return try req.view().render("freelance", context)
    }
    
    func CompanyHandler(_ req: Request) throws -> Future<View> {
        let userLoggedIn = try req.isAuthenticated(User.self)
        let loggedInUser = try req.authenticated(User.self)
        let blogCategory = BlogCategoryModel.query(on: req).all()
        let context = CompanyContext(blogcategories: blogCategory, title: "Company information", loggedInUser: loggedInUser, userLoggedIn: userLoggedIn)
        
        return try req.view().render("company", context)
        
    }
    
    
    
   
}

struct LoginPostData: Content {
    let username: String
    let password: String
}

struct RegisterPostData: Content {
    let username: String
    let password: String
    let confirmPassword: String
    let email: String
}


struct IndexContext: Encodable {
    let blogcategories: Future<[BlogCategoryModel]>
    let title: String
    let loggedInUser: User?
    let userLoggedIn: Bool
    let cookieMessage: Bool
}

struct CourseContext: Encodable {
    let blogcategories: Future<[BlogCategoryModel]>
    let title = "Courses"
    let userLoggedIn: Bool
    let loggedInUser: User?
    let courses: Future<[Courses]>
}

struct CourseInformationContext: Encodable {
    let blogcategories: Future<[BlogCategoryModel]>
    let userLoggedIn: Bool
    let loggedInUser: User?
    let title: String
    let courseName: String
    let courseDescription: String
    let instructor: String
    let sections: Int
    let lectures: Int
    let publishDate: String
    let difficulty: String
    let courseDuration: String
    let beginURL: String
    let courses: Courses
    let section: Future<[CourseSection]>
    let forWhoName: String
    let forWhoText: String
    let introVideo: String
    let lastupdatedDate: String?
}

struct courseSectionVideoPlayerContext: Encodable {
    let blogcategories: Future<[BlogCategoryModel]>
    let userLoggedIn: Bool
    let loggedInUser: User?
    let sections: CourseSection
    let sectionName: String
    let videos: Future<[VideoModel]>
    let title: String
}

struct BlogCategoryContext: Encodable {
    let blogcategories: Future<[BlogCategoryModel]>
    let categoryID: UUID
    let blog: Future<[BlogPostModel]>
    let categories: BlogCategoryModel
    let loggedInUser: User?
    let userLoggedIn: Bool
    
    let categoryName: String
    
}

struct BlogPostContext: Encodable {
    let blogcategories: Future<[BlogCategoryModel]>

    let userLoggedIn: Bool
    let loggedInUser: User?
    var blogTitle: String
    var publicationDate: String
    var writer: String
    var tags: String
    var publication: String
    var introImage: String
    
}

struct SubscriptionContext: Encodable {
    let blogcategories: Future<[BlogCategoryModel]>
    let loggedInUser: User?
    let userLoggedIn: Bool
    let title = "subscription"
    let subscription: Future<[Subscription]>
    
}

struct DownloadContext: Encodable {
    let blogcategories: Future<[BlogCategoryModel]>
    let loggedInUser: User?
    let userLoggedIn: Bool
    let title = "Downloads"
    let downloads: Future<[Download]>
}

struct FreelanceContext: Encodable {
    let blogcategories: Future<[BlogCategoryModel]>
    let loggedInUser: User?
    let userLoggedIn: Bool
    let title: String
}

struct UserContext: Encodable {
    let blogcategories: Future<[BlogCategoryModel]>
    let loggedInUser: User?
    let userLoggedIn: Bool
    let title: String
    let user: User
}

struct LoginContext: Encodable {
    
    let loginError: Bool
    init(loginError: Bool = false) {
        self.loginError = loginError
    }
    
}

struct RegisterContext: Encodable {
   // let blogcategories: Future<[BlogCategoryModel]>
    let title = "Register"
    
    let message: String?
    init(message: String? = nil) {
        self.message = message
    }
}

struct ProfileContext: Encodable {
    let blogcategories: Future<[BlogCategoryModel]>
    let loggedInUser: User?
    let userLoggedIn: Bool
    let id: UUID?
    let title: String?
    let username: String
    let name: String?
    let lastName: String?
    let dateOfBirth: String?
    let userImage: String?
    let email: String?
    let userDescription: String?
    let specialty: [String]?
    let user: User
    let subscription: Bool?
}

struct UpdateProfileContext: Decodable {
    
    let name: String?
    let lastName: String?
    let userName: String?
    let userDescription: String?
    let dateOfBirth: String?
    let email: String?
    let userImage: String?
    let sectionFinished: [String]?
}

struct ResetPasswordContext: Encodable {
   // let blogcategories: Future<[BlogCategoryModel]>
    let title = "Reset Password"
    let error: Bool?
    
    init(error: Bool? = false) {
        self.error = error
    }
}

struct ResetPasswordData: Content {
    let password: String
    let confirmPassword: String
}

struct UserSubscriptionContext: Encodable {
    let blogcategories: Future<[BlogCategoryModel]>
    let title: String
    let loggedInUser: User?
    let userLoggedIn: Bool?
    let user: User
    var isSubscribed: Bool? = false
}

struct ImageUploadData: Content {
    var picture: Data
}

struct CheckoutContext: Encodable {
    let blogcategories: Future<[BlogCategoryModel]>
    let title: String
    let loggedInUser: User?
    let userLoggedIn: Bool?
    let user: User
    var isSubscribed: Bool? = false
}

struct CompanyContext: Encodable {
    let blogcategories: Future<[BlogCategoryModel]>
    let title: String
    let loggedInUser: User?
    let userLoggedIn: Bool?
}

struct emailContext: Encodable {
    var to: String
    var subject: String
    var message: String
}

struct SendEmailContext: Content {
    var to: String
    var sender: String
    var subject: String
    var message: String
}

struct BasicRespone: Content {
   var message: String
}

struct CourseSectionFinishedContext: Content {
    var sectionID: String
    let loggedInUser: User?
    let userLoggedIn: Bool?
    var user: User
    var finishedSection: [String]
}



extension RegisterPostData: Validatable, Reflectable {
    static func validations() throws -> Validations<RegisterPostData> {
        var validations = Validations(RegisterPostData.self)
        try validations.add(\.username, .alphanumeric && .count(3...))
        try validations.add(\.password, .count(8...))
        
        validations.add("passwords match") { model in
            guard model.password == model.confirmPassword else {
                throw BasicValidationError("password don't match")
            }
        }
        return validations
    }
}

