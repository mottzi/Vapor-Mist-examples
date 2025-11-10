import Vapor
import LeafKit

extension Application.Mist 
{    
    public func use(_ components: [any Component]) async
    {
        await configure(components: components, on: application)
    }
    
    public func use(_ components: any Component...) async 
    {
        await configure(components: components, on: application)
    }
}

private func configure(components: [any Component], on application: Application) async
{
    let inlineTemplates = TemplateSource()
    for component in components {
        guard case .inline(let template) = component.template else { continue }
        await inlineTemplates.register(name: component.name, template: template)
    }
    
    let sources = LeafSources()
    try? sources.register(source: "mist-templates", using: inlineTemplates)
    try? sources.register(source: "default", using: application.leaf.defaultSource)
    application.leaf.sources = sources
    
    await application.mist.components.registerComponents(components, with: application)

    let websocket = Socket()
    websocket.register(on: application)
}