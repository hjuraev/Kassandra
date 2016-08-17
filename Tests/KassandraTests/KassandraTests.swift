/**
 Copyright IBM Corporation 2016
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */


import XCTest
@testable import Kassandra

#if os(OSX) || os(iOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

public final class Student {
    var id: Int?
    var name: String
    var school: String
    
    init(id: Int?, name: String, school: String) {
        self.id = id
        self.name = name
        self.school = school
    }
}
extension Student: Model, CustomStringConvertible {
    
    public enum Field : String {
        case id
        case name
        case school
    }
    
    public var description: String {
        return "id: \(id!), name: \(name), school: \(school)"
    }
    public static var tableName: String = "student"
    
    public static var primaryKey: Field = Field.id
    
    public var key: Int? {
        get { return id }
        set { id = newValue }
    }
    
    public convenience init(row: Row) {
        let id = row["id"] as? Int
        let name = row["name"] as! String
        let school = row["school"] as! String
        
        self.init(id: id, name: name, school: school)
    }
    
}
public class TodoItem: Table {
    public enum Field: String {
        case type = "type"
        case userID = "userID"
        case title = "title"
        case pos = "pos"
        case completed = "completed"
    }
    
    public static var tableName: String = "todoitem"
    
}

public class BreadShop: Table {
    public enum Field: String {
        case type = "type"
        case userID = "userID"
        case time = "time"
        case name = "name"
        case cost = "cost"
        case rate = "rate"
}
    
    public static var tableName: String = "breadshop"
    
}

class KassandraTests: XCTestCase {
    
    private var client: Kassandra!
    
    var tokens = [String]()
    
    static var allTests: [(String, (KassandraTests) -> () throws -> Void)] {
        return [
            ("testConnect", testConnect),
            ("testCreateKeyspace", testCreateKeyspace),
            ("testKeyspaceWithCreateATable", testKeyspaceWithCreateATable),
            ("testKeyspaceWithFetchCompletedTodoItems", testKeyspaceWithFetchCompletedTodoItems),
            ("testOptions",testOptions),
            ("testPreparedQuery", testPreparedQuery),
            ("testTruncateTable",testTruncateTable),
            ("testZBatch", testZBatch),
            //("testZDropTableAndDeleteKeyspace", testZDropTableAndDeleteKeyspace),
            //("testMaxTodoitemID", testMaxTodoitemID),
            //("testTable", testTable),
            //("testModel", testModel),
        ]
    }
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        client = Kassandra()
    }
    
    func testConnect() throws {
        
        // try client.connect { error in }
    }
    
    func testCreateKeyspace() throws {
        
        
        //let expectation2 = expectation(description: "Keyspace exist")
        let expectation1 = expectation(description: "Created a keyspace or Keyspace exist")
        do {
            try client.connect() { error in
                
                XCTAssertNil(error)
            }
            
            sleep(1)
            let query: Query = Raw(query: "CREATE KEYSPACE IF NOT EXISTS test WITH replication = {'class':'SimpleStrategy', 'replication_factor': 1};")

            try client.execute(.query(using: query)) {
                result in

                switch result {
                case .kind(let res):
                    switch res {
                    case .schema: expectation1.fulfill()
                    case .void  : expectation1.fulfill()
                    default     : break
                    }
                default: break
                }
            }
        } catch {
            throw error
        }
        
        waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
    }
    
   func testKeyspaceWithCreateATable() throws {
        
        let expectation1 = expectation(description: "Create a table in the keyspace or table exist in the keyspace")
        
        do {
            try client.connect() { error in
                
                XCTAssertNil(error)
            }
            
            sleep(1)
            let _ = client["test"]
            let query: Query = Raw(query: "CREATE TABLE IF NOT EXISTS todoitem(userID int primary key, type text, title text, pos int, completed boolean);")
            try client.execute(.query(using: query)) {
                result in

                switch result {
                case .kind(let res):
                    switch res {
                    case .schema: expectation1.fulfill()
                    case .void  : expectation1.fulfill()
                    default     : break
                    }
                default: break
                }
            }
            
            sleep(2)
            
        } catch {
            throw error
        }
        
        waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
    }
    
    func testKeyspaceWithCreateABreadShopTable() throws {
        
        let expectation1 = expectation(description: "Create a table in the keyspace or table exist in the keyspace")
        
        do {
            try client.connect() { error in
                
                XCTAssertNil(error)
            }
            
            sleep(1)
            let _ = client["test"]
            let query: Query = Raw(query: "CREATE TABLE IF NOT EXISTS breadshop (userID uuid primary key, type text, name text, cost float, rate double, time timestamp);")
            try client.execute(.query(using: query)) {
                result in
                
                switch result {
                case .kind(let res):
                    switch res {
                    case .schema: expectation1.fulfill()
                    case .void  : expectation1.fulfill()
                    default     : break
                    }
                default: break
                }
            }
            
            sleep(2)
            
        } catch {
            throw error
        }
        
        waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
    }
    
    func testKeyspaceWithCreateABreadShopTableInsertAndSelect() throws {
        
        do {
            try client.connect() { error in
                
                XCTAssertNil(error)
            }
            
            sleep(1)
            let _ = client["test"]
            
            let query: Query = Raw(query: "INSERT INTO breadshop (userID, type, name, cost, rate, time) VALUES (60780342-90fe-11e2-8823-0026c650d722, 'Sandwich', 'roller', 2.90, 9.99, '2013-03-07 11:17:38');")
            try client.execute(.query(using: query)) {
                result in
                
                print(result)
            }
            
            sleep(2)
            
            BreadShop.select().execute()
                .then { (table: TableObj) in
                    print(table)
                    
                }.fail {
                    error in
                    print("Error: ",error)
            }
            sleep(5)
        } catch {
            throw error
        }
    }
  
    func testKeyspaceWithFetchCompletedTodoItems() throws {
        
        let expectation1 = expectation(description: "Filter out todoitems that are done and update one of the todoitems")
        
        do {
            try client.connect() { error in
                
                XCTAssertNil(error)
            }
            
            sleep(1)
            let _ = client["test"]
            
            let _ : Promise<Status> = TodoItem.insert([.type: "todo", .userID: 1,.title: "God Among God", .pos: 1, .completed: true]).execute()
            
            let _ : Promise<Status> =  TodoItem.insert([.type: "todo", .userID: 2,.title: "Ares", .pos: 2, .completed: false]).execute()
            
            let _ : Promise<Status> =  TodoItem.insert([.type: "todo", .userID: 3,.title: "Thor", .pos: 3, .completed: true]).execute()
            
            let _ : Promise<Status> =  TodoItem.insert([.type: "todo", .userID: 4,.title: "Apollo", .pos: 4, .completed: false]).execute()
            
            let _ : Promise<Status> =  TodoItem.insert([.type: "todo", .userID: 5,.title: "Cassandra", .pos: 5, .completed: true]).execute()
            
            let _ : Promise<Status> =  TodoItem.insert([.type: "todo", .userID: 6,.title: "Hades", .pos: 6, .completed: false]).execute()
            
            let _ : Promise<Status> =  TodoItem.insert([.type: "todo", .userID: 7,.title: "Athena", .pos: 7, .completed: true]).execute()
            
            sleep(2)
            
            TodoItem.select().limited(to: 3).execute()
                .then {
                (table: TableObj) in

                let _ : Promise<Status> = TodoItem.update([.title: "Zeus"], conditions: "userID" == 1).execute()
                sleep(1)
                
                TodoItem.select().filter(by: "userID" == 1).execute()
                    .then { (table: TableObj) in
                        
                        expectation1.fulfill()
                        
                    }.fail {
                        error in
                        
                        print(error)
                }
                
                
                
                }.fail {
                    error in
                    
                    print(error)
            }
            
        } catch {
            throw error
        }
        waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
        
    }
    
   
    func testTruncateTable() throws {
        
        let expectation1 = expectation(description: "Truncate table")
        
        do {
            try client.connect() { error in
                
                XCTAssertNil(error)
            }
            
            sleep(1)
            let _ = client["test"]
            
            let _ : Promise<Status> = TodoItem.insert([.type: "todo", .userID: 10,.title: "Hera", .pos: 10, .completed: false]).execute()
            
            let _ : Promise<Status> = TodoItem.insert([.type: "todo", .userID: 11,.title: "Aphrodite", .pos: 11, .completed: false]).execute()
            
            let _ : Promise<Status> = TodoItem.insert([.type: "todo", .userID: 12,.title: "Poseidon", .pos: 12, .completed: false]).execute()
            
            sleep(3)
            
            TodoItem.count().execute().then {
                (table: TableObj) in
                
                XCTAssertEqual((table.rows[0]["count"] as! Int64), 10)
                
                let _ : Promise<Status> = TodoItem.truncate().execute()
                
                sleep(2)
                
                TodoItem.count().execute().then {
                    (truncatedTable: TableObj) in
                    
                    XCTAssertEqual((truncatedTable.rows[0]["count"] as! Int64), 0)
                    
                    expectation1.fulfill()
                    }.fail{
                        error in
                        
                        print(error)
                }
                }.fail{
                    error in
                    
                    print(error)
            }
        } catch {
            throw error
        }
        
        waitForExpectations(timeout: 10, handler: { error in XCTAssertNil(error, "Timeout") })
    }
    
    func testOptions() throws {
        
        let expectation1 = expectation(description: "Showing options")
        do {
            try client.connect() { error in
                
                XCTAssertNil(error)
            }
            
            sleep(1)
            let _ = client["test"]
            
            try client.execute(.options) {
                result in
                
                expectation1.fulfill()
            }
        } catch {
            throw error
        }
        
        waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
        
    }
    
/*    func testZDropTableAndDeleteKeyspace() throws {
        
        let expectation1 = expectation(description: "Drop the table and delete the keyspace")
        
        do {
            try client.connect() { error in
                
                XCTAssertNil(error)
            }
            
            sleep(1)
            let _ = client["test"]
            
            let _ : Promise<Status> = TodoItem.truncate().execute()
            sleep(2)
            
            let query: Query = Raw(query: "DROP KEYSPACE test;")

            try client.execute(.query(using: query)) {
                result in

                switch result {
                case .kind(let res):
                    switch res {
                    case .schema: expectation1.fulfill()
                    default: break
                    }
                default: break
                }
            }
        } catch {
            throw error
        }
        
        waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
        
    }
*/
    /*func testMaxTodoitemID() throws {
     
     let expectation1 = expectation(description: "Get the max todoitem")
     
     do {
     try client.connect() { error in
     
     XCTAssertNil(error)
     }
     
     sleep(1)
     let _ = client["test"]
     
     try TodoItem.insert([.type: "todo", .userID: 7,.title: "Hephaestus", .pos: 21, .completed: false]).execute(oncompletion: ErrorHandler)
     
     try TodoItem.insert([.type: "todo", .userID: 7,.title: "Hermes", .pos: 22, .completed: false]).execute(oncompletion: ErrorHandler)
     
     sleep(1)
     
     /*TodoItem.select().limited(to: 3).filter(by: "type" == "todo").ordered(by: ["title": .DESC]).execute().then { table in
     
     print(table)
     
     
     }.fail {
     error in
     
     print(error)
     }*/
     
     } catch {
     throw error
     }
     waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
     
     }*/
    
    func testPreparedQuery() throws {
     
        let expectation1 = expectation(description: "Execute a prepared query")
            do {
                try client.connect() {
                    error in
                    XCTAssertNil(error)
                }

                sleep(1)
                let _ = client["test"]

                let query: Query = Raw(query: "SELECT userID FROM todoitem WHERE completed = true allow filtering;").with(consistency: .all)

                try client.execute(.prepare(query: query)) {
                    result in

                    switch result {
                    case .kind(let res):
                        switch res {
                        case .prepared(let id, _, _):
                            do {
                                try self.client.execute(.execute(id: id, parameters: query)) {
                                    result in
                                    
                                    switch result {
                                    case .error(let error): print(error)
                                    default: expectation1.fulfill()
                                    }
                                }
                            } catch { }
                        default: break
                        }
                    default: break
                    }

         }
     } catch {
     throw error
     }
     waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
     
     }

     /*
    /*
     func testTable() throws {
     
     do {
     try client.connect() { error in print("\(#function) - ErrorType(\(error))")}
     
     sleep(1)
     let _ = client["test"]
     
     sleep(1)
     try TodoItem.insert([.type: "todo", .userID: 2,.title: "Chia", .pos: 2, .completed: false]).execute(oncompletion: ErrorHandler)
     try TodoItem.insert([.type: "todo", .userID: 3,.title: "Thor", .pos: 3, .completed: false]).execute(oncompletion: ErrorHandler)
     sleep(1)
     TodoItem.select().limited(to: 2).filter(by: "type" == "todo" && "userID" == 3).ordered(by: ["title": .ASC]).execute()
     .then { table in
     print(table)
     
     do { try TodoItem.update([.completed: true], conditions: "userID" == 3).execute(oncompletion: self.ErrorHandler) } catch {}
     sleep(1)
     TodoItem.select().execute()
     .then { table in
     print(table)
     TodoItem.count().execute()
     .then { table in
     print(table)
     
     do { try TodoItem.delete(where: "userID" == 2).execute(oncompletion: self.ErrorHandler) }catch {}
     
     TodoItem.select().execute()
     .then { table in
     print(table)
     
     do { try TodoItem.truncate().execute(oncompletion: self.ErrorHandler) } catch {}
     TodoItem.select().execute()
     .then { table in
     print(table)
     }.fail { error in
     print(error)
     }
     }.fail { error in
     print(error)
     }
     
     }.fail { error in
     print(error)
     }
     }.fail { error in
     print(error)
     }
     }.fail { error in
     print(error)
     }
     sleep(5)
     
     } catch {
     throw error
     }
     
     }
     */
    func testModel() throws {
        
        let expectation1 = expectation(description: "Test Student Model")
        
        print("--------+---------+----------+---------")
        
        do {
            try client.connect() { error in
                
                XCTAssertNil(error)
            }
            
            sleep(1)
            let _ = client["test"]
            
            /*try Student.drop().execute(oncompletion: ErrorHandler)
             try Student.select().execute(oncompletion: ResultHandler)
             try Student.insert([:]).execute(oncompletion: ErrorHandler)
             try Student.delete(where: [:]).execute(oncompletion: ErrorHandler)
             try Student.update([:], conditions: [:]).execute(oncompletion: ErrorHandler)*/
            
            let student = Student(id: 10, name: "Dave", school: "UNC") ; sleep(1)
            try student.create() ; sleep(1)
            
            student.id = 15
            student.name = "Aaron"
            
            student.save().fail{
                error in
                print(error)
            }
            sleep(2)
            Student.fetch()
                .then { rows in
                    print(rows)
                    
                    student.delete().fail {
                        error in
                        print(error)
                    }
                    sleep(2)
                    Student.fetch()
                        .then { rows in
                            print(rows)
                            
                            expectation1.fulfill()
                            
                        }.fail{ error in
                            print(error)
                    }
                }.fail{ error in
                    print(error)
            }
            
            
        } catch {
            throw error
        }
        sleep(3)
        waitForExpectations(timeout: 10, handler: { error in XCTAssertNil(error, "Timeout") })
        
    }
    */
    
    public func testZBatch() {
        let expectation1 = expectation(description: "Execute a batch query")
        
        var insert1 = TodoItem.insert([.type: "todo", .userID: 99,.title: "Water Plants", .pos: 15, .completed: false])
        
        insert1.prepare()
            .then {
                id in
                
                insert1.preparedID = id
                
                let insert2 = TodoItem.insert([.type: "todo", .userID: 98,.title: "Make Dinner", .pos: 14, .completed: true])
                let insert3 = TodoItem.insert([.type: "todo", .userID: 97,.title: "Excercise", .pos: 13, .completed: true])
                let insert4 = TodoItem.insert([.type: "todo", .userID: 96,.title: "Sprint Plannning", .pos: 12, .completed: false])
                
                [insert1,insert2,insert3,insert4].execute(with: .logged, consis: .any) { result in
                    
                    switch result {
                    case .error(let error)  : print(error)
                    case .kind              : expectation1.fulfill()
                    default                 : break
                    }
                    
                }
    
            }.fail {
                error in
                
                print(error)
            }
        
        
        
        
        waitForExpectations(timeout: 5, handler: { error in XCTAssertNil(error, "Timeout") })
    }
    public func ErrorHandler(error: Result?) {
        print(error)
    }
}

