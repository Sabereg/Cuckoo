//
//  ObjectiveClassTest.swift
//  Cuckoo+OCMock_iOSTests
//
//  Created by Matyáš Kříž on 28/05/2019.
//

import XCTest
import Cuckoo

class ObjectiveClassTest: XCTestCase {
    func testThenDoNothing() {
        let mock = objectiveStub(for: UIView.self) { stubber, mock in
            stubber.when(mock.addSubview(objectiveAny())).thenDoNothing()
        }

        mock.addSubview(UIView())

        objectiveVerify(mock.addSubview(objectiveAny()))
    }

    func testThenReturn() {
        let mock = objectiveStub(for: UIView.self) { stubber, mock in
            stubber.when(mock.endEditing(true)).thenReturn(true)
            stubber.when(mock.endEditing(false)).thenReturn(false)
        }

        XCTAssertTrue(mock.endEditing(true))
        XCTAssertFalse(mock.endEditing(false))

        objectiveVerify(mock.endEditing(true))
        objectiveVerify(mock.endEditing(false))
    }

    func testThen() {
        let tableView = UITableView()
        let mock = objectiveStub(for: UITableViewController.self) { stubber, mock in
            stubber.when(mock.numberOfSections(in: tableView)).thenReturn(1)
            stubber.when(mock.tableView(tableView, accessoryButtonTappedForRowWith: IndexPath(row: 420, section: 69))).then { args in
                let (tableView, indexPath) = (args[0] as! UITableView, args[1] as! IndexPath)
                print(tableView, indexPath)
                print("Owie")
            }
        }

        XCTAssertEqual(mock.numberOfSections(in: tableView), 1)
        mock.tableView(tableView, accessoryButtonTappedForRowWith: IndexPath(row: 420, section: 69))

        objectiveVerify(mock.numberOfSections(in: tableView))
        objectiveVerify(mock.tableView(tableView, accessoryButtonTappedForRowWith: IndexPath(row: 420, section: 69)))
    }

    func testThenWithReturn() {
        let event = UIEvent()
        let view = UIView()
        let mock = objectiveStub(for: UIView.self) { stubber, mock in
            stubber.when(mock.endEditing(false)).then { args in
                print("Hello, \(args).")
                return true
            }
            stubber.when(mock.hitTest(CGPoint.zero, with: event)).then { args in
                print("Hello, \(args).")
                return nil
            }
            stubber.when(mock.hitTest(CGPoint(x: 145.5, y: 0.444), with: event)).then { args in
                print("Hello, \(args).")
                return view
            }
            stubber.when(mock.userActivity).then { args in
                print("Hello, \(args).")
                return NSUserActivity(activityType: "activity")
            }
        }

        XCTAssertTrue(mock.endEditing(false))
        XCTAssertNil(mock.hitTest(.zero, with: event))
        XCTAssertEqual(mock.hitTest(CGPoint(x: 145.5, y: 0.444), with: event), view)
        XCTAssertEqual(mock.userActivity?.activityType, "activity")

        objectiveVerify(mock.endEditing(false))
        objectiveVerify(mock.hitTest(.zero, with: event))
        objectiveVerify(mock.hitTest(CGPoint(x: 145.5, y: 0.444), with: event))
        objectiveVerify(mock.userActivity?.activityType)
    }

    func testThenThrow() {
        let mock = objectiveStub(for: UINavigationController.self) { stubber, mock in
            stubber.when(mock.resignFirstResponder()).thenThrow(TestError.unknown)
        }

        objectiveAssertThrows(errorHandler: { print($0) }, mock.resignFirstResponder())

        objectiveVerify(mock.resignFirstResponder())
    }

    func testArgumentClosure() {
        var savedCompletionHandler: ((Data?, URLResponse?, Error?) -> Void)?
        let dataTaskMock = objectiveStub(for: URLSessionDataTask.self) { stubber, mock in
            stubber.when(mock.resume()).then { _ in
                guard let data = "Hello, upgraded Cuckoo!".data(using: .utf8) else {
                    savedCompletionHandler?(nil, nil, TestError.unknown)
                    return
                }
                savedCompletionHandler?(data, nil, nil)
            }
        }

        let url = URL(string: "https://github.com/Brightify/Cuckoo")!
        let mock = objectiveStub(for: URLSession.self) { stubber, mock in
            stubber.when(mock.dataTask(with: url, completionHandler: objectiveAnyClosure())).then { args in
                // NOTE: when you need to get a closure from an argument, this is the only way to do it
                let completionHandler = objectiveArgumentClosure(from: args[1]) as (Data?, URLResponse?, Error?) -> Void
                savedCompletionHandler = completionHandler
                return dataTaskMock
            }
        }
        

        mock.dataTask(with: url) { data, response, error in
            guard let data = data else { return }
            print(String(data: data, encoding: .utf8)!)
        }.resume()
    }

    func testStubPriority() {
        let mock = objectiveStub(for: UITextField.self) { stubber, mock in
            stubber.when(mock.shouldChangeText(in: objectiveAny(), replacementText: "pappa pia")).thenReturn(false)
            stubber.when(mock.shouldChangeText(in: objectiveAny(), replacementText: "mamma mia")).thenReturn(true)
            // NOTE: In ObjC mocking, the general `objectiveAny()` must be at the bottom, else it captures all the other stubs declared after it.
            stubber.when(mock.shouldChangeText(in: objectiveAny(), replacementText: objectiveAny())).thenReturn(false)
        }

        XCTAssertFalse(mock.shouldChangeText(in: objectiveAny(), replacementText: "pappa pia"))
        XCTAssertTrue(mock.shouldChangeText(in: objectiveAny(), replacementText: "mamma mia"))
        XCTAssertFalse(mock.shouldChangeText(in: objectiveAny(), replacementText: "lalla lia"))

        objectiveVerify(mock.shouldChangeText(in: objectiveAny(), replacementText: "pappa pia"))
        objectiveVerify(mock.shouldChangeText(in: objectiveAny(), replacementText: "mamma mia"))
        objectiveVerify(mock.shouldChangeText(in: objectiveAny(), replacementText: "lalla lia"))
    }

    func testSwiftClass() {
        let mock = objectiveStub(for: SwiftClass.self) { stubber, mock in
            stubber.when(mock.dudka(lelo: "heya")).thenReturn(false)
            stubber.when(mock.dudka(lelo: "heyda")).thenReturn(true)
        }

        XCTAssertFalse(mock.dudka(lelo: "heya"))
        XCTAssertTrue(mock.dudka(lelo: "heyda"))

        objectiveVerify(mock.dudka(lelo: objectiveAny()))
    }
}

class SwiftClass: NSObject {
    @objc
    // `dynamic` modifier is necessary
    dynamic func dudka(lelo: String) -> Bool {
        return false
    }
}
