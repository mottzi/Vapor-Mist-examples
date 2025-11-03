import Vapor
import Fluent
import Mist

struct DemoComponent: Mist.Component
{
    let models: [any Mist.Model.Type] = [DemoModel1.self, DemoModel2.self]
    let template: String = "/mistDemo/DemoComponent"
}
