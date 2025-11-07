import Vapor
import Fluent
import Mist

struct DemoComponentBlue: Mist.Component
{
    let models: [any Mist.Model.Type] = [DemoModel1.self, DemoModel2.self]
}

struct DemoComponentRed: Mist.Component
{
    let models: [any Mist.Model.Type] = [DemoModel1.self, DemoModel2.self]
    let template: TemplateType = .file(path: "/mistDemo/DemoComponentRed")
}

struct DemoComponentGreen: Mist.Component
{
    let models: [any Mist.Model.Type] = [DemoModel1.self, DemoModel2.self]
    
    let template: TemplateType = .inline(template:
        """
        <tr
            class="hover:bg-green-500 dark:hover:bg-neutral-750 transition-colors duration-150"
            mist-component="DemoComponentGreen"
            mist-id="#(component.demomodel1.id)"
        >
            <td class="px-6 py-4">
                <span class="font-mono text-indigo-600 dark:text-indigo-400 text-sm">
                    #(component.demomodel1.id)
                </span>
            </td>
        
            <td class="px-6 py-4 max-w-[160px]">
                <span class="block text-sm text-gray-700 dark:text-neutral-300 truncate font-medium">
                    #(component.demomodel1.text)
                </span>
            </td>
        
            <td class="px-6 py-4">
                <div class="flex items-center justify-between gap-3">
                    <span class="text-sm text-gray-700 dark:text-neutral-300 font-medium">
                        #(component.demomodel2.text)
                    </span>
                    <div class="flex gap-2 flex-shrink-0">
                        <button
                            mist-action="RandomizeAction"
                            class="px-2 py-1 text-xs bg-blue-500 hover:bg-blue-600 text-white rounded transition-colors"
                        >
                            Randomize
                        </button>
                        <button
                            mist-action="delete"
                            class="px-2 py-1 text-xs bg-red-500 hover:bg-red-600 text-white rounded transition-colors"
                        >
                            Delete
                        </button>
                    </div>
                </div>
            </td>
        </tr>
        """
    )
    
    var actions: [any Action]
    {
        [
            DeleteAction(),
            RandomizeAction()
        ]
    }
}

struct DeleteAction: Action
{
    let name: String = "delete"
    
    func execute(id: UUID, on db: Database) async throws -> ActionResult
    {
        if let model1 = try await DemoModel1.find(id, on: db) {
            try await model1.delete(on: db)
        }
        if let model2 = try await DemoModel2.find(id, on: db) {
            try await model2.delete(on: db)
        }
        return .success
    }
}

struct RandomizeAction: Action
{
    func execute(id: UUID, on db: Database) async throws -> ActionResult
    {
        if let model1 = try await DemoModel1.find(id, on: db) {
            model1.text = "Random-\(UUID().uuidString.prefix(8))"
            try await model1.save(on: db)
        }
        if let model2 = try await DemoModel2.find(id, on: db) {
            model2.text = "Random-\(UUID().uuidString.prefix(8))"
            try await model2.save(on: db)
        }
        return .success
    }
}
