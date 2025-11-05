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
            mist-component="DemoComponentInline"
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
                <span class="text-sm text-gray-700 dark:text-neutral-300 font-medium">
                    #(component.demomodel2.text)
                </span>
            </td>
        </tr>
        """
    )
}
