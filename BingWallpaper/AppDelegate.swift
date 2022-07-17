import Cocoa
import ServiceManagement

extension Notification.Name {
    static let killLauncher = Notification.Name("killLauncher")
}

// TODO: @2h4u create and add icon (app icon and menubar icon)

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    private let menuController = MenuController()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        FileHandler.createWallpaperFolderIfNeeded()
        
        let updateManager = UpdateManager()
        updateManager.delegate = menuController
        updateManager.start()
        
        menuController.updateManager = updateManager
        menuController.setup()
        
        killBingWallpaperHelperIfNeeded()
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        menuController.showSettingsWc(sender: nil)
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    fileprivate func killBingWallpaperHelperIfNeeded() {
        let launcherAppId = "com.2h4u.BingWallpaperHelper"
        let runningApps = NSWorkspace.shared.runningApplications
        let isRunning = !runningApps.filter { $0.bundleIdentifier == launcherAppId }.isEmpty
        
        if isRunning {
            DistributedNotificationCenter.default().post(name: .killLauncher, object: Bundle.main.bundleIdentifier!)
        }
    }
    
    // MARK: - Core Data stack
    
    func entityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = "ImageDescriptor"
        entity.managedObjectClassName = NSStringFromClass(ImageDescriptor.self)
        
        // Attributes
        let startDateAttr = NSAttributeDescription()
        startDateAttr.name = "startDate"
        startDateAttr.attributeType = .stringAttributeType
        startDateAttr.isOptional = false
        
        let endDateAttr = NSAttributeDescription()
        endDateAttr.name = "endDate"
        endDateAttr.attributeType = .stringAttributeType
        endDateAttr.isOptional = false
        
        let imageUrlAttr = NSAttributeDescription()
        imageUrlAttr.name = "imageUrl"
        imageUrlAttr.attributeType = .URIAttributeType
        imageUrlAttr.isOptional = false
        
        let descriptionStringAttr = NSAttributeDescription()
        descriptionStringAttr.name = "descriptionString"
        descriptionStringAttr.attributeType = .stringAttributeType
        descriptionStringAttr.isOptional = false
        
        let copyrightUrlAttr = NSAttributeDescription()
        copyrightUrlAttr.name = "copyrightUrl"
        copyrightUrlAttr.attributeType = .URIAttributeType
        copyrightUrlAttr.isOptional = false
        
        entity.properties = [
            startDateAttr,
            endDateAttr,
            imageUrlAttr,
            descriptionStringAttr,
            copyrightUrlAttr
        ]
        
        return entity
    }
    
    func managedObjectModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()
        
        model.entities = [entityDescription()]
        
        return model
    }
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DataModel", managedObjectModel: managedObjectModel())
        
        container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    // MARK: - Core Data Saving and Undo support
    
    @IBAction func saveAction(_ sender: AnyObject?) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        let context = persistentContainer.viewContext
        
        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Customize this code block to include application-specific recovery steps.
                let nserror = error as NSError
                NSApplication.shared.presentError(nserror)
            }
        }
    }
    
    func windowWillReturnUndoManager(window: NSWindow) -> UndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        return persistentContainer.viewContext.undoManager
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        let context = persistentContainer.viewContext
        
        if !context.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
            return .terminateCancel
        }
        
        if !context.hasChanges {
            return .terminateNow
        }
        
        do {
            try context.save()
        } catch {
            let nserror = error as NSError
            
            // Customize this code block to include application-specific recovery steps.
            let result = sender.presentError(nserror)
            if result {
                return .terminateCancel
            }
            
            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info")
            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = info
            alert.addButton(withTitle: quitButton)
            alert.addButton(withTitle: cancelButton)
            
            let answer = alert.runModal()
            if answer == .alertSecondButtonReturn {
                return .terminateCancel
            }
        }
        // If we got here, it is time to quit.
        return .terminateNow
    }
}
