//
//  OrdersTableViewController.swift
//  HotCoffee
//
//  Created by Kevin on 6/04/22.
//

import UIKit

//Helper
extension DispatchQueue {
    static func mainAsyncIfNeeded(execute work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            main.async(execute: work)
        }
    }
}

enum CoffeeType: String, Codable, CaseIterable {
    case cappucino
    case latte
    case espressino
    case cortado
}

enum CoffeeSize: String, Codable, CaseIterable {
    case small
    case medium
    case large
}

struct OrderModel: Codable {
    let name: String
    let email: String
    let type: CoffeeType
    let size: CoffeeSize
}

//VIEW MODEL!!!!The
struct ItemViewModel {
    let title: String
    let description: String
}

extension ItemViewModel {
    init(order: OrderModel) {
        self.title = "\(order.name) - \(order.email)"
        self.description = "Coffee: \(order.type.rawValue) Size: \(order.size.rawValue)"
    }
}

protocol ItemService {
    func loadItems(completion: @escaping (Result<[ItemViewModel], NetworkError>) -> Void)
    func saveItems(completion: @escaping (Result<[ItemViewModel], NetworkError>) -> Void)
}

enum NetworkError: Error {
    case domainError
    case decodingError
}

class OrderAPIService {
    static var shared = OrderAPIService()
    
    func loadOrders(url: URL, completion: @escaping (Result<[OrderModel], NetworkError>) -> Void) {
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(.failure(.domainError))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(OrderModel.self, from: data)
                DispatchQueue.mainAsyncIfNeeded {
                    completion(.success([result]))
                }
            } catch let err {
                print(err.localizedDescription)
                
                DispatchQueue.mainAsyncIfNeeded {
                    completion(.success([
                        OrderModel(name: "Kevin", email: "rojke34@gmail.com", type: .cappucino, size: .large)
                    ]))
                }
            }
        }.resume()
    }
    
    func saveOrder(url: URL, payload: AddOrder, completion: @escaping (Result<[OrderModel], NetworkError>) -> Void) {
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        guard let data = try? JSONEncoder().encode(payload) else {
            fatalError("Error Encoding Model")
        }
        request.httpBody = data
        request.addValue("application/json; chartset=utf-8", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(.failure(.domainError))
                return
            }
            
            do {
                let result = try JSONDecoder().decode(OrderModel.self, from: data)
                print(result)
                DispatchQueue.mainAsyncIfNeeded {
                    completion(.success([result]))
                }
            } catch let err {
                print(err.localizedDescription)
                
                DispatchQueue.mainAsyncIfNeeded {
                    completion(.success([
                        OrderModel(name: "Kevin", email: "rojke34@gmail.com", type: .cappucino, size: .large)
                    ]))
                }
            }
        }.resume()
    }
    
}
    
struct OrderAPIServiceAdapter: ItemService {
    let api: OrderAPIService
    let url: URL
    let payload: AddOrder?
    
    func loadItems(completion: @escaping (Result<[ItemViewModel], NetworkError>) -> Void) {
        api.loadOrders(url: url) { result in
            DispatchQueue.mainAsyncIfNeeded {
                switch result {
                case .success(_):
                    completion(result.map { items in
                        items.map { item in
                            ItemViewModel(order: item)
                        }
                    })
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func saveItems(completion: @escaping (Result<[ItemViewModel], NetworkError>) -> Void) {
        guard let body = payload else { return }
        api.saveOrder(url: url, payload: body) { result in
            DispatchQueue.mainAsyncIfNeeded {
                switch result {
                case .success(_):
                    completion(result.map { items in
                        items.map { item in
                            ItemViewModel(order: item)
                        }
                    })
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
}

class OrdersTableViewController: UITableViewController {

    var itemsCoffeeOrders = [ItemViewModel]()
    var service: ItemService?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
        
        let url = URL(string: "https://warp-wiry-rugby.glitch.me/orders")!
        
        service = OrderAPIServiceAdapter(api: OrderAPIService.shared, url: url, payload: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if tableView.numberOfRows(inSection: 0) == 0 {
            refresh()
        }
    }
    
    @objc func refresh() {
        refreshControl?.beginRefreshing()
        
        service?.loadItems(completion: handleAPIResult)
    }
    
    private func handleAPIResult(_ result: Result<[ItemViewModel], NetworkError>) {
        switch result {
        case let .success(items):
            self.itemsCoffeeOrders = items
            self.refreshControl?.endRefreshing()
            self.tableView.reloadData()
        case let .failure(error):
            self.show(error: error)
            self.refreshControl?.endRefreshing()
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return itemsCoffeeOrders.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = itemsCoffeeOrders[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "ItemCell")
        cell.configure(item)
        return cell
    }
   
}

extension UIViewController {
    //Helper
    //Decople the viewcontroller from navigation and presentation `show` much reusable
    //to do something reusable we need to eliminate dependency on specific context
    func show(error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default))
        showDetailViewController(alert, sender: self) // Provide by UKit -- showDetailViewController to decouple from navigation
    }
}

extension UITableViewCell {
    func configure(_ vm: ItemViewModel) {
        textLabel?.text = vm.title
        textLabel?.numberOfLines = 0
        detailTextLabel?.text = vm.description
        detailTextLabel?.numberOfLines = 0
    }
}
