//
//  CustomerTableViewController.swift
//  Customer
//
//  Created by Jason Scott on 17/11/17.
//  Copyright © 2017 SAP. All rights reserved.
//

import Foundation
import SAPFoundation
import SAPOData
import SAPOfflineOData
import SAPFiori
import SAPCommon

import EventKit


class CustomerTableViewController: FUIFormTableViewController, SAPFioriLoadingIndicator {

    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    private var myServiceClass: MyPrefixMyServiceClass<OfflineODataProvider> {
        return self.appDelegate.myServiceClass
    }
    var isStoreOpened = false
    
    private var entities: [MyPrefixCustomer] = [MyPrefixCustomer]( )
    private let logger = Logger.shared(named: "CustomerViewControllerLogger")
    private let okTitle = NSLocalizedString("keyOkButtonTitle",
                                            value: "OK",
                                            comment: "XBUT: Title of OK button.")
    
    var loadingIndicator: FUILoadingIndicatorView?
    
    private var activities = [FUIActivityItem.phone, FUIActivityItem.message, FUIActivityItem.detail]
    
    // Reminders (EventKit)
    var eventStore: EKEventStore!
    var calendars: Array<EKCalendar> = []
    var customerCalendar: EKCalendar!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.edgesForExtendedLayout = []
        self.tableView.rowHeight = UITableViewAutomaticDimension
        self.tableView.estimatedRowHeight = 98
        
        eventStore = EKEventStore()
        eventStore.requestAccess(to: EKEntityType.reminder, completion: {(granted, error) in
            if !granted {
                self.logger.error("Access to reminders not granted")
            }
        })
        
        calendars = eventStore.calendars(for: EKEntityType.reminder)
        checkIfCustomersReminderListExists()
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.refreshControl = refreshControl

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        initOfflineSyncProcess()
        //updateTable()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.entities.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath) as! FUIContactCell
        
        let customer = self.entities[indexPath.row]
        
        cell.headlineText = "\(customer.firstName!) \(customer.lastName!)"
        cell.subheadlineText = "\(customer.city!), \(customer.country!)"
        cell.descriptionText = customer.phoneNumber
        cell.splitPercent = CGFloat(0.3) // Default is 30%
        
        cell.detailImage = #imageLiteral(resourceName: "person-placeholder")
        
        cell.activityControl.addActivities(activities)
        cell.activityControl.maxVisibleItems = 4
        cell.onActivitySelectedHandler = { activityItem in
            switch activityItem {
            case FUIActivityItem.phone:
                guard let number = URL(string: "tel://" + customer.phoneNumber!) else { return }
                if UIApplication.shared.canOpenURL(number) {
                    UIApplication.shared.open(number)
                }
            case FUIActivityItem.message:
                guard let sms = URL(string: "sms://" + customer.phoneNumber!) else { return }
                if UIApplication.shared.canOpenURL(sms) {
                    UIApplication.shared.open(sms)
                }
            case FUIActivityItem.detail:
                self.createReminder(customer: customer)
            default:
                break
            }
        }
        
        return cell
    }

    // MARK: - Data accessing
    
    /**
     Perform the actual OData request to the backend.
     We have added logic to open the offline store and close it when finished.
     (This should be pulled out into separate method.)
    */
    func requestEntities(completionHandler: @escaping (Error?) -> Void) {
        //if (!self.isStoreOpened) {
            // try opening the store
            self.myServiceClass.provider.open { error in
                guard error == nil else {
                    print("Error opening the offline store in requestEntities()")
                    self.logger.error("Offline store could not be opened", error: error)
                    completionHandler(error!)
                    return
                }
                
                // set flag indicating store is open
                //self.isStoreOpened = true
                
                // download data
                //print("Downloading/caching customer data to offline store")
                //self.myServiceClass.provider.download { error in
                //    guard error == nil else {
                //        // in case of error, close store and reset flag
                //        self.logger.info("Could not download store", error: error)
                //        try! self.myServiceClass.provider.close()
                //        self.isStoreOpened = false
                //        completionHandler(error!)
                //        return
                //    }
                
                    // Only request the first 30 values. If you want to modify the requested entities, you can do it here.
                    print("Fetching customer data (top-30) in requestEntities()")
                    let query = DataQuery().selectAll().top(30)
                    self.myServiceClass.fetchCustomers(matching: query) { customers, error in
                        guard let customers = customers else {
                            try! self.myServiceClass.provider.close()
                            //self.isStoreOpened = false
                            completionHandler(error!)
                            return
                        }
                        
                        self.entities = customers
                        try! self.myServiceClass.provider.close()
                        //self.isStoreOpened = false
                        completionHandler(nil)
                    }
                    
                //}
            }
        //}
    }
    
    // MARK: - Table update
    
    func updateTable() {
        self.showFioriLoadingIndicator()
        let oq = OperationQueue()
        oq.addOperation({
            self.loadData {
                self.hideFioriLoadingIndicator()
            }
        })
    }
    
    private func loadData(completionHandler: @escaping () -> Void) {
        self.requestEntities { error in
            defer {
                completionHandler()
            }
            if let error = error {
                let alertController = UIAlertController(title: NSLocalizedString("keyErrorLoadingData", value: "Loading data failed!", comment: "XTIT: Title of loading data error pop up."), message: error.localizedDescription, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: self.okTitle, style: .default))
                OperationQueue.main.addOperation({
                    // Present the alertController
                    self.present(alertController, animated: true)
                })
                self.logger.error("Could not update table. Error: \(error)", error: error)
                return
            }
            OperationQueue.main.addOperation({
                self.tableView.reloadData()
                self.logger.info("Table updated successfully!")
            })
        }
    }
    
    @objc func refresh() {
        let oq = OperationQueue()
        oq.addOperation({
            self.loadData {
                OperationQueue.main.addOperation({
                    self.refreshControl?.endRefreshing()
                })
            }
        })
    }
    
    /**
     Check if a Reminder List called 'Customers' already exists.
     If not then create it.
    */
    func checkIfCustomersReminderListExists() {
        var calenderExists = false
        
        for calendar in calendars as [EKCalendar] {
            if calendar.title == "Customers" {
                calenderExists = true
                self.customerCalendar = calendar
            }
        }
        
        if !calenderExists {
            createCustomersReminderList()
        }
    }
    
    /**
     Create a new Reminder List in the iOS Reminders App for Customers.
    */
    func createCustomersReminderList() {
        customerCalendar = EKCalendar(for: EKEntityType.reminder, eventStore: self.eventStore)
        customerCalendar.title = "Customers"
        customerCalendar.source = self.eventStore.defaultCalendarForNewReminders()?.source
        
        do {
            try self.eventStore.saveCalendar(customerCalendar, commit: true)
        } catch let error {
            logger.error("Calendar creation failed with error \(error.localizedDescription)")
        }
    }
    
    /**
     Create a reminder (in the iOS Reminders App) with the
     contact details of the selected customer.
     - parameter customer: Customer OData Entity
    */
    func createReminder(customer: MyPrefixCustomer) {
        let reminder = EKReminder(eventStore: self.eventStore)
        
        reminder.title = "Call \(customer.firstName!) \(customer.lastName!)"
        reminder.notes = "Phone: \(customer.phoneNumber!)\nEmail: \(customer.emailAddress!)"
        
        reminder.calendar = self.customerCalendar
        
        do {
            try self.eventStore.save(reminder, commit: true)
            
            let alert = UIAlertController(title: NSLocalizedString("keyReminderCreated", value: "Reminder has been created", comment: "XTIT: Title of reminder creation pop up."), message: "Reminder has been created", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: self.okTitle, style: .default))
            self.present(alert, animated: true, completion: nil)
            
        } catch let error {
            print("Reminder failed with error \(error.localizedDescription)")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "to_details" {
            
            if (self.tableView.indexPathForSelectedRow?.row != nil) {
                let customer = self.entities[(self.tableView.indexPathForSelectedRow?.row)!]
                let detailView = segue.destination as! DetailViewController
                
                detailView.entity = customer
                
            //    let currentEntity = self.entity as PackagesType
            //    let esDeliveryStatus = DeliveryServiceMetadata.EntitySets.deliveryStatus
            //    let propPackageId    = DeliveryStatusType.packageID
            //    let propTimestamp    = DeliveryStatusType.deliveryTimestamp
                
                // Load all related DeliveryStatuses for the current Package,
                // latest first.
            //    let query = DataQuery()
            //        .from(esDeliveryStatus)
            //        .where(propPackageId.equal((currentEntity.packageID)!))
            //        .orderBy(propTimestamp, SortOrder.descending)
                
            //    self.deliveryService.fetchDeliveryStatus(matching: query) { deliveryStatus, error in
            //        guard let deliveryStatus = deliveryStatus else {
            //            return
            //        }
            //        trackingInfoView.entities = deliveryStatus
            //        trackingInfoView.tableView.reloadData()
            //    }
            }
        }
    }
    
    /**
     Initialise the Offline OData Store by downloading the defining entities.
    */
    func initOfflineSyncProcess() {
        myServiceClass.provider.open { error in
            guard error == nil else {
                print("Error opening offline store")
                return
            }
            
            self.myServiceClass.provider.download { error in
                guard error == nil else {
                    print("Error downloading to offline store")
                    try! self.myServiceClass.provider.close()
                    return
                }
                
                print("Offline store updated (download complete)")
                try! self.myServiceClass.provider.close()
                
                self.updateTable()
            }
        }
    }
    
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
