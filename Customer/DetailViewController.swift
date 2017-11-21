//
//  DetailViewController.swift
//  Customer
//
//  Created by Jason Scott on 20/11/17.
//  Copyright © 2017 SAP. All rights reserved.
//

import Foundation
import SAPFoundation
import SAPOData
import SAPFiori
import SAPCommon


class DetailViewController: FUIFormTableViewController {

    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    private let logger: Logger = Logger.shared(named: "DetailViewController")
    
    private var _entity: MyPrefixCustomer = MyPrefixCustomer()
    var entity: EntityValue {
        get { return _entity }
        set { self._entity = newValue as! MyPrefixCustomer
        }
    }
    
    var objectHeader: FUIObjectHeader!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Create Fiori Object Header
        tableView.register(FUIObjectTableViewCell.self, forCellReuseIdentifier: FUIObjectTableViewCell.reuseIdentifier)
        
        objectHeader = FUIObjectHeader()
        
        tableView.tableHeaderView = objectHeader
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorStyle = .none
        
        if let objectHeader = tableView.tableHeaderView as? FUIObjectHeader {
            objectHeader.headlineText = "\(_entity.firstName!) \(_entity.lastName!)"
            objectHeader.subheadlineText = _entity.customerID
            objectHeader.tags = [FUITag(title: "Started"), FUITag(title:"PM01"), FUITag(title:"103-Repair")]
            objectHeader.footnoteText = "\(_entity.city!), \(_entity.country!)"
            objectHeader.descriptionText = "This is the description text..."
            objectHeader.statusText = "High"
            objectHeader.substatusImage = #imageLiteral(resourceName: "person-placeholder")
        }
        
        // Create Fiori Simple Property
        tableView.register(FUISimplePropertyFormCell.self, forCellReuseIdentifier: FUISimplePropertyFormCell.reuseIdentifier)
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorStyle = .none
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /**
     Specify the number of rows in the table collection. Here we return a row for the Fiori
     Object Header and additional rows for each Fiori Simple Property Cell.
    */
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            return UITableViewCell( )
        } else {
            let simplePropertyCell = tableView.dequeueReusableCell(withIdentifier: FUISimplePropertyFormCell.reuseIdentifier, for: indexPath) as! FUISimplePropertyFormCell
            
            switch indexPath.row {
            case 1:
                simplePropertyCell.keyName = "E-mail"
                simplePropertyCell.value = _entity.emailAddress!
                simplePropertyCell.keyLabel.font = UIFont.preferredFioriFont(forTextStyle: .body)
                simplePropertyCell.valueTextField.font = UIFont.preferredFioriFont(forTextStyle: .body)
            case 2:
                simplePropertyCell.keyName = "Phone Number"
                simplePropertyCell.value = _entity.phoneNumber!
                simplePropertyCell.keyLabel.font = UIFont.preferredFioriFont(forTextStyle: .body)
                simplePropertyCell.valueTextField.font = UIFont.preferredFioriFont(forTextStyle: .body)
            default:
                simplePropertyCell.keyName = "Address"
                simplePropertyCell.value = "\(_entity.houseNumber!) \(_entity.street!), \(_entity.city!) \(_entity.postalCode!)"
                simplePropertyCell.keyLabel.font = UIFont.preferredFioriFont(forTextStyle: .body)
                simplePropertyCell.valueTextField.font = UIFont.preferredFioriFont(forTextStyle: .body)
            }
            
            return simplePropertyCell
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
