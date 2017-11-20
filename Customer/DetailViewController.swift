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


class DetailViewController: UIViewController {

    private let appDelegate = UIApplication.shared.delegate as! AppDelegate
    private let logger: Logger = Logger.shared(named: "DetailViewController")
    
    private var _entity: MyPrefixCustomer = MyPrefixCustomer()
    var entity: EntityValue {
        get { return _entity }
        set { self._entity = newValue as! MyPrefixCustomer
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
