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
    let actions: [any Action] = [DeleteAction(), RandomizeAction()]
    
    let template: TemplateType = .inline(template:
        """
        <tr
            class="hover:bg-green-500 dark:hover:bg-neutral-750 transition-colors duration-150"
            mist-component="DemoComponentGreen"
            mist-id="#(component.demomodel1.id)"
        >
            <td class="px-6 py-4">
                <span class="text-sm font-semibold text-green-600 dark:text-green-400">
                    DemoComponentGreen
                </span>
            </td>
        
            <td class="px-6 py-4">
                <div class="flex items-center gap-2">
                    <span class="font-mono text-indigo-600 dark:text-indigo-400 text-sm">
                        #(component.demomodel1.shortID)
                    </span>
                    <button
                        onclick="navigator.clipboard.writeText('#(component.demomodel1.id)'); this.textContent='✓'; setTimeout(() => this.textContent='📋', 1000)"
                        class="px-1.5 py-0.5 text-xs bg-gray-100 hover:bg-gray-200 dark:bg-neutral-700 dark:hover:bg-neutral-600 rounded transition-colors"
                        title="Copy full ID"
                    >
                        📋
                    </button>
                </div>
            </td>
        
            <td class="px-6 py-4 max-w-[160px]">
                <span class="block text-sm text-gray-700 dark:text-neutral-300 truncate font-medium">
                    #(component.demomodel1.text)
                </span>
            </td>
        
            <td class="px-6 py-4">
                <span class="text-sm text-gray-700 dark:text-neutral-300 font-medium">
                    #(component.demomodel2.text)
                </span>
            </td>
        
            <td class="px-6 py-4">
                <div class="flex gap-2">
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
            </td>
        </tr>
        """
    )
}

struct DeleteAction: Mist.Action
{
    let name: String = "delete"
    
    func perform(id: UUID, on db: Database) async -> ActionResult
    {
        guard let model1 = try? await DemoModel1.find(id, on: db) else { return .failure(message: "Model1 not found") }
        guard let model2 = try? await DemoModel2.find(id, on: db) else { return .failure(message: "Model2 not found") }
        guard let _ = try? await model1.delete(on: db) else { return .failure(message: "Failed to delete Model1") }
        guard let _ = try? await model2.delete(on: db) else { return .failure(message: "Failed to delete Model2") }
        
        return .success()
    }
}

struct RandomizeAction: Mist.Action
{
    func perform(id: UUID, on db: Database) async -> ActionResult
    {
        guard let model1 = try? await DemoModel1.find(id, on: db) else { return .failure(message: "Model1 not found") }
        guard let model2 = try? await DemoModel2.find(id, on: db) else { return .failure(message: "Model2 not found") }
        
        model1.text = "\(UUID().uuidString.prefix(8))"
        model2.text = "\(UUID().uuidString.prefix(8))"
        
        guard let _ = try? await model1.save(on: db) else { return .failure(message: "Failed to save Model1") }
        guard let _ = try? await model2.save(on: db) else { return .failure(message: "Failed to save Model2") }
        
        return .success(message: "Randomized successfully")
    }
}
