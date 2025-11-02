import Vapor
import Fluent
import Mist

struct DemoComponent: Mist.Component
{
    static let models: [any Mist.Model.Type] = [DemoModel1.self, DemoModel2.self]
    static let template: String = "/mistDemo/DemoComponent"
}
