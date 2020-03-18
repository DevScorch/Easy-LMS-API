import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    
    let userController = UserController()
    let websiteController = WebsiteController()
    let courseController = CourseController()
    let courseCategoryController = CourseCategoryController()
    let subscriptionController = SubscriptionController()
    let adminController = AdminController()
    let downloadController = DownloadsController()
    let sectionController = SectionController()
    let videoController = VideoController()
    let blogCategoryController = BlogCategoryController()
    let blogController = BlogController()
    
    
    
    try router.register(collection: userController)
    try router.register(collection: websiteController)
    try router.register(collection: courseController)
    try router.register(collection: courseCategoryController)
    try router.register(collection: subscriptionController)
    try router.register(collection: adminController)
    try router.register(collection: downloadController)
    try router.register(collection: sectionController)
    try router.register(collection: videoController)
    try router.register(collection: blogCategoryController)
    try router.register(collection: blogController)
    
    }
