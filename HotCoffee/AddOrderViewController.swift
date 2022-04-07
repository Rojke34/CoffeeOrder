//
//  AddOrder.swift
//  HotCoffee
//
//  Created by Kevin on 6/04/22.
//

import UIKit

struct AddOrder: Encodable {
    var name: String?
    var email: String?
    
    var selectedType: String?
    var selectedSize: String?
    
    var types: [String] {
        return CoffeeType.allCases.map { $0.rawValue.capitalized }
    }
    
    var sizes: [String] {
        return CoffeeSize.allCases.map { $0.rawValue.capitalized }
    }
}

extension OrderModel {
    init?(addOrder: AddOrder) {
        guard let name = addOrder.name,
                let email = addOrder.email,
                let selectedType = CoffeeType(rawValue: addOrder.selectedType!.lowercased()),
                let selectedSize = CoffeeSize(rawValue: addOrder.selectedSize!.lowercased()) else {
                    return nil
                }
        
        self.name = name
        self.email = email
        self.type = selectedType
        self.size = selectedSize
        
    }
}

class AddOrderViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var nameTextfield: UITextField!
    @IBOutlet weak var emailTextfield: UITextField!
    private var vm = AddOrder()
    
    private var coffeSizeSegmenteControl: UISegmentedControl!
    
    var service: ItemService?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
    }
    
    @IBAction func close() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func save() {
        let name = nameTextfield.text
        let email = emailTextfield.text
        
        let selectedSize = coffeSizeSegmenteControl.titleForSegment(at: coffeSizeSegmenteControl.selectedSegmentIndex)
        guard let indexPath = tableView.indexPathForSelectedRow else {
            fatalError("Error in selecting coffee!")
        }
        
        vm.name = name
        vm.email = email
        vm.selectedSize = selectedSize
        vm.selectedType = vm.types[indexPath.row]
        
        
        //Send data to the server
        let url = URL(string: "https://warp-wiry-rugby.glitch.me/orders")!
        
        service = OrderAPIServiceAdapter(api: OrderAPIService.shared, url: url, payload: vm)
        service?.saveItems(completion: handleAPIResult)
    }
    
    private func handleAPIResult(_ result: Result<[ItemViewModel], NetworkError>) {
        switch result {
        case let .success(items):
            print(items)
        case let .failure(error):
            self.show(error: error)
        }
    }
    
    func setupUI() {
        coffeSizeSegmenteControl = UISegmentedControl(items: vm.sizes)
        coffeSizeSegmenteControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(coffeSizeSegmenteControl)
        coffeSizeSegmenteControl.topAnchor.constraint(equalTo: tableView.bottomAnchor, constant: 20).isActive = true
        coffeSizeSegmenteControl.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
    }

}

extension AddOrderViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return vm.types.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "addCell", for: indexPath)
        
        cell.textLabel?.text = vm.types[indexPath.row]
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        tableView.cellForRow(at: indexPath)?.accessoryType = .none
    }
}
