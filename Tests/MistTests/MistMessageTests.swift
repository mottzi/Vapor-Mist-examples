import XCTest
import Vapor
import Fluent
import FluentSQLiteDriver
@testable import Mist

final class MistMessageTests: XCTestCase
{
    // tests decoding json subscription message to ClientMessage type
    func testSubscriptionDecoding() async
    {
        let text = #"{ "subscribe": { "component": "TestComponent2" } }"#

        // try to decode json message to mist subscribe message
        guard let data = text.data(using: .utf8) else { return XCTFail("Failed to convert JSON string to data") }
        guard let message = try? JSONDecoder().decode(ClientMessage.self, from: data) else { return XCTFail("Failed to decode data to ClientMessage") }
        guard case .subscribe(let component) = message else { return XCTFail("Valid but non-subscribe message") }

        XCTAssertEqual(component, "TestComponent2", "ClientMessage component should match JSON component string")
    }

    // tests encoding ClientMessage.subscribe to json
    func testSubscriptionEncoding() async
    {
        // Create a subscription message
        let subscriptionMessage = ClientMessage.subscribe(component: "TestComponent2")

        // Encode the message to JSON
        guard let jsonData = try? JSONEncoder().encode(subscriptionMessage) else { return XCTFail("Failed to encode subscription message") }

        // Decode JSON data to a dictionary for inspection
        guard let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else { return XCTFail("Failed to convert json to dictionary") }

        // Verify JSON structure and values
        XCTAssertNotNil(dict["subscribe"], "Should have 'subscribe' key")
        guard let subscribeDict = dict["subscribe"] as? [String: Any] else { return XCTFail("Subscribe should be a dictionary") }
        XCTAssertEqual(subscribeDict["component"] as? String, "TestComponent2", "Component should match")
        XCTAssertEqual(dict.count, 1, "JSON should only have 1 key (the case name)")
    }

    // tests decoding json component update message to ServerMessage type
    func testComponentUpdateDecoding() async
    {
        // Create a UUID to test with
        let testUUID = UUID()

        // Create JSON string for a component update message
        let text =
        """
        {
            "component": {
                "update": {
                    "component": "TestComponent",
                    "id": "\(testUUID)",
                    "html": "<div>Updated content</div>"
                }
            }
        }
        """

        // Try to decode json message to broadcast message
        guard let data = text.data(using: .utf8) else { return XCTFail("Failed to convert JSON string to data") }
        guard let message = try? JSONDecoder().decode(ServerBroadcast.self, from: data) else { return XCTFail("Failed to decode data to BroadcastMessage") }

        // Verify the message is of correct type
        guard case .instanceComponent(let componentMessage) = message else { return XCTFail("Valid but non-component message") }
        guard case .update(let component, let id, let html) = componentMessage else { return XCTFail("Valid but non-update component message") }

        // Verify all fields match expected values
        XCTAssertEqual(component, "TestComponent", "Component name should match expected value")
        XCTAssertEqual(id, testUUID, "UUID should match expected value")
        XCTAssertEqual(html, "<div>Updated content</div>", "HTML content should match expected value")
    }

    // tests encoding ComponentMessage.update to json
    func testComponentUpdateEncoding() async
    {
        // Create a UUID to test with
        let testUUID = UUID()

        // Create a component update message
        let componentMessage = ComponentBroadcast.update(
            component: "TestComponent",
            id: testUUID,
            html: "<div>Updated content</div>"
        )
        let broadcastMessage = ServerBroadcast.instanceComponent(componentMessage)

        // Encode the message to JSON
        guard let jsonData = try? JSONEncoder().encode(broadcastMessage) else { return XCTFail("Failed to encode component update message") }

        // Decode JSON data to a dictionary for inspection
        guard let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else { return XCTFail("Failed to convert json to dictionary") }

        // Verify JSON structure and values
        XCTAssertNotNil(dict["component"], "Should have 'component' key")
        guard let componentDict = dict["component"] as? [String: Any] else { return XCTFail("Component should be a dictionary") }
        XCTAssertNotNil(componentDict["update"], "Should have 'update' key in component")
        guard let updateDict = componentDict["update"] as? [String: Any] else { return XCTFail("Update should be a dictionary") }
        XCTAssertEqual(updateDict["component"] as? String, "TestComponent", "Component should match")
        XCTAssertEqual(updateDict["id"] as? String, testUUID.uuidString, "UUID should match")
        XCTAssertEqual(updateDict["html"] as? String, "<div>Updated content</div>", "HTML should match")
        XCTAssertEqual(dict.count, 1, "JSON should have 1 key (the case name)")
    }

    // tests decoding json query upsert message to ServerMessage type
    func testQueryUpsertDecoding() async
    {
        // Create JSON string for a query upsert message
        let text =
        """
        {
            "query": {
                "upsert": {
                    "component": "TestQueryComponent",
                    "html": "<div>Query content</div>"
                }
            }
        }
        """

        // Try to decode json message to broadcast query message
        guard let data = text.data(using: .utf8) else { return XCTFail("Failed to decode data to BroadcastMessage") }
        guard let message = try? JSONDecoder().decode(ServerBroadcast.self, from: data) else { return XCTFail("Failed to decode data to BroadcastMessage") }

        // Verify the message is of correct type
        guard case .queryComponent(let queryMessage) = message else { return XCTFail("Valid but non-query message") }
        guard case .upsert(let component, let html) = queryMessage else { return XCTFail("Valid but non-upsert query message") }

        // Verify all fields match expected values
        XCTAssertEqual(component, "TestQueryComponent", "Component name should match expected value")
        XCTAssertEqual(html, "<div>Query content</div>", "HTML content should match expected value")
    }

    // tests encoding QueryComponentMessage.upsert to json
    func testQueryUpsertEncoding() async
    {
        // Create a query upsert message
        let queryMessage = QueryComponentBroadcast.upsert(
            component: "TestQueryComponent",
            html: "<div>Query content</div>"
        )
        let broadcastMessage = ServerBroadcast.queryComponent(queryMessage)

        // Encode the message to JSON
        guard let jsonData = try? JSONEncoder().encode(broadcastMessage) else { return XCTFail("Failed to encode query upsert message") }

        // Decode JSON data to a dictionary for inspection
        guard let dict = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else { return XCTFail("Failed to convert json to dictionary") }

        // Verify JSON structure and values
        XCTAssertNotNil(dict["query"], "Should have 'query' key")
        guard let queryDict = dict["query"] as? [String: Any] else { return XCTFail("Query should be a dictionary") }
        XCTAssertNotNil(queryDict["upsert"], "Should have 'upsert' key in query")
        guard let upsertDict = queryDict["upsert"] as? [String: Any] else { return XCTFail("Upsert should be a dictionary") }
        XCTAssertEqual(upsertDict["component"] as? String, "TestQueryComponent", "Component should match")
        XCTAssertEqual(upsertDict["html"] as? String, "<div>Query content</div>", "HTML should match")
        XCTAssertEqual(dict.count, 1, "JSON should have 1 key (the case name)")
    }
}